import lldb
import binascii
from lldbsuite.test.lldbtest import *
from lldbsuite.test.decorators import *
from lldbsuite.test.gdbclientutils import *
from lldbsuite.test.lldbgdbclient import GDBRemoteTestBase

LLDB_INVALID_ADDRESS = lldb.LLDB_INVALID_ADDRESS
load_address = 0x400000000

def format_register_value(val):
    """
    Encode each byte by two hex digits in little-endian order.
    """
    result = ""
    mask = 0xFF
    shift = 0
    for i in range(0, 8):
        x = (val & mask) >> shift
        result += format(x, "02x")
        mask <<= 8
        shift += 8
    return result


class MyResponder(MockGDBServerResponder):
    current_pc = load_address + 0x0A

    def __init__(self, obj_path, module_name=""):
        self._obj_path = obj_path
        self._module_name = module_name or obj_path
        MockGDBServerResponder.__init__(self)

    def respond(self, packet):
        if packet[0:13] == "qRegisterInfo":
            return self.qRegisterInfo(packet[13:])
        if packet.startswith("qWasmCallStack"):
            return self.qWasmCallStack()
        return MockGDBServerResponder.respond(self, packet)

    def qSupported(self, client_supported):
        return "qXfer:libraries:read+;PacketSize=1000;vContSupported-"

    def qHostInfo(self):
        return ""

    def QEnableErrorStrings(self):
        return ""

    def qfThreadInfo(self):
        return "m1,"

    def qRegisterInfo(self, index):
        if index == 0:
            return "name:pc;alt-name:pc;bitsize:64;offset:0;encoding:uint;format:hex;set:General Purpose Registers;gcc:16;dwarf:16;generic:pc;"
        return "E45"

    def qProcessInfo(self):
        return "pid:1;ppid:1;uid:1;gid:1;euid:1;egid:1;name:%s;triple:%s;ptrsize:4" % (
            hex_encode_bytes("lldb"),
            hex_encode_bytes("wasm32-unknown-unknown-wasm"),
        )

    def haltReason(self):
        return "T02thread:1;"

    def readRegister(self, register):
        return format_register_value(self.current_pc)

    def qXferRead(self, obj, annex, offset, length):
        if obj == "libraries":
            xml = (
                '<library-list><library name="%s"><section address="%d"/></library></library-list>'
                % (self._module_name, load_address)
            )
            return xml, False
        else:
            return None, False

    def readMemory(self, addr, length):
        if addr < load_address:
            return "E02"
        result = ""
        with open(self._obj_path, mode="rb") as file:
            file_content = bytearray(file.read())
            addr_from = addr - load_address
            addr_to = addr_from + min(length, len(file_content) - addr_from)
            for i in range(addr_from, addr_to):
                result += format(file_content[i], "02x")
            file.close()
        return result

    def qWasmCallStack(self):
        # Return two 64-bit addresses: 0x40000000000001B3, 0x40000000000001FE
        return "b301000000000040fe01000000000040"


class TestWasm(GDBRemoteTestBase):
    @skipIfAsan
    @skipIfXmlSupportMissing
    def test_load_module_with_embedded_symbols_from_remote(self):
        """Test connecting to a WebAssembly engine via GDB-remote and loading a Wasm module with embedded DWARF symbols"""

        yaml_path = "test_wasm_embedded_debug_sections.yaml"
        yaml_base, ext = os.path.splitext(yaml_path)
        obj_path = self.getBuildArtifact(yaml_base)
        self.yaml2obj(yaml_path, obj_path)

        self.server.responder = MyResponder(obj_path, "test_wasm")

        target = self.dbg.CreateTarget("")
        process = self.connect(target, "wasm")
        lldbutil.expect_state_changes(
            self, self.dbg.GetListener(), process, [lldb.eStateStopped]
        )

        num_modules = target.GetNumModules()
        self.assertEqual(1, num_modules)

        module = target.GetModuleAtIndex(0)
        num_sections = module.GetNumSections()
        self.assertEqual(5, num_sections)

        code_section = module.GetSectionAtIndex(0)
        self.assertEqual("code", code_section.GetName())
        self.assertEqual(
            load_address | code_section.GetFileOffset(),
            code_section.GetLoadAddress(target),
        )

        debug_info_section = module.GetSectionAtIndex(1)
        self.assertEqual(".debug_info", debug_info_section.GetName())
        self.assertEqual(
            load_address | debug_info_section.GetFileOffset(),
            debug_info_section.GetLoadAddress(target),
        )

        debug_abbrev_section = module.GetSectionAtIndex(2)
        self.assertEqual(".debug_abbrev", debug_abbrev_section.GetName())
        self.assertEqual(
            load_address | debug_abbrev_section.GetFileOffset(),
            debug_abbrev_section.GetLoadAddress(target),
        )

        debug_line_section = module.GetSectionAtIndex(3)
        self.assertEqual(".debug_line", debug_line_section.GetName())
        self.assertEqual(
            load_address | debug_line_section.GetFileOffset(),
            debug_line_section.GetLoadAddress(target),
        )

        debug_str_section = module.GetSectionAtIndex(4)
        self.assertEqual(".debug_str", debug_str_section.GetName())
        self.assertEqual(
            load_address | debug_line_section.GetFileOffset(),
            debug_line_section.GetLoadAddress(target),
        )

    @skipIfAsan
    @skipIfXmlSupportMissing
    def test_load_module_with_stripped_symbols_from_remote(self):
        """Test connecting to a WebAssembly engine via GDB-remote and loading a Wasm module with symbols stripped into a separate Wasm file"""

        sym_yaml_path = "test_sym.yaml"
        sym_yaml_base, ext = os.path.splitext(sym_yaml_path)
        sym_obj_path = self.getBuildArtifact(sym_yaml_base) + ".wasm"
        self.yaml2obj(sym_yaml_path, sym_obj_path)

        yaml_path = "test_wasm_external_debug_sections.yaml"
        yaml_base, ext = os.path.splitext(yaml_path)
        obj_path = self.getBuildArtifact(yaml_base) + ".wasm"
        self.yaml2obj(yaml_path, obj_path)

        self.server.responder = MyResponder(obj_path, "test_wasm")

        folder, _ = os.path.split(obj_path)
        self.runCmd(
            "settings set target.debug-file-search-paths " + os.path.abspath(folder)
        )

        target = self.dbg.CreateTarget("")
        process = self.connect(target, "wasm")
        lldbutil.expect_state_changes(
            self, self.dbg.GetListener(), process, [lldb.eStateStopped]
        )

        num_modules = target.GetNumModules()
        self.assertEqual(1, num_modules)

        module = target.GetModuleAtIndex(0)
        num_sections = module.GetNumSections()
        self.assertEqual(5, num_sections)

        code_section = module.GetSectionAtIndex(0)
        self.assertEqual("code", code_section.GetName())
        self.assertEqual(
            load_address | code_section.GetFileOffset(),
            code_section.GetLoadAddress(target),
        )

        debug_info_section = module.GetSectionAtIndex(1)
        self.assertEqual(".debug_info", debug_info_section.GetName())
        self.assertEqual(
            LLDB_INVALID_ADDRESS, debug_info_section.GetLoadAddress(target)
        )

        debug_abbrev_section = module.GetSectionAtIndex(2)
        self.assertEqual(".debug_abbrev", debug_abbrev_section.GetName())
        self.assertEqual(
            LLDB_INVALID_ADDRESS, debug_abbrev_section.GetLoadAddress(target)
        )

        debug_line_section = module.GetSectionAtIndex(3)
        self.assertEqual(".debug_line", debug_line_section.GetName())
        self.assertEqual(
            LLDB_INVALID_ADDRESS, debug_line_section.GetLoadAddress(target)
        )

        debug_str_section = module.GetSectionAtIndex(4)
        self.assertEqual(".debug_str", debug_str_section.GetName())
        self.assertEqual(
            LLDB_INVALID_ADDRESS, debug_line_section.GetLoadAddress(target)
        )

    @skipIfAsan
    @skipIfXmlSupportMissing
    def test_load_module_from_file(self):
        """Test connecting to a WebAssembly engine via GDB-remote and loading a Wasm module from a file"""

        yaml_path = "test_wasm_embedded_debug_sections.yaml"
        yaml_base, ext = os.path.splitext(yaml_path)
        obj_path = self.getBuildArtifact(yaml_base)
        self.yaml2obj(yaml_path, obj_path)

        self.server.responder = MyResponder(obj_path)

        target = self.dbg.CreateTarget("")
        process = self.connect(target, "wasm")
        lldbutil.expect_state_changes(
            self, self.dbg.GetListener(), process, [lldb.eStateStopped]
        )

        num_modules = target.GetNumModules()
        self.assertEqual(1, num_modules)

        module = target.GetModuleAtIndex(0)
        num_sections = module.GetNumSections()
        self.assertEqual(5, num_sections)

        code_section = module.GetSectionAtIndex(0)
        self.assertEqual("code", code_section.GetName())
        self.assertEqual(
            load_address | code_section.GetFileOffset(),
            code_section.GetLoadAddress(target),
        )

        debug_info_section = module.GetSectionAtIndex(1)
        self.assertEqual(".debug_info", debug_info_section.GetName())
        self.assertEqual(
            LLDB_INVALID_ADDRESS, debug_info_section.GetLoadAddress(target)
        )

        debug_abbrev_section = module.GetSectionAtIndex(2)
        self.assertEqual(".debug_abbrev", debug_abbrev_section.GetName())
        self.assertEqual(
            LLDB_INVALID_ADDRESS, debug_abbrev_section.GetLoadAddress(target)
        )

        debug_line_section = module.GetSectionAtIndex(3)
        self.assertEqual(".debug_line", debug_line_section.GetName())
        self.assertEqual(
            LLDB_INVALID_ADDRESS, debug_line_section.GetLoadAddress(target)
        )

        debug_str_section = module.GetSectionAtIndex(4)
        self.assertEqual(".debug_str", debug_str_section.GetName())
        self.assertEqual(
            LLDB_INVALID_ADDRESS, debug_line_section.GetLoadAddress(target)
        )

        thread = process.GetThreadAtIndex(0)
        self.assertTrue(thread.IsValid())

        frame = thread.GetFrameAtIndex(0)
        self.assertTrue(frame.IsValid())
        self.assertEqual(frame.GetPC(), 0x40000000000001B3)

        frame = thread.GetFrameAtIndex(1)
        self.assertTrue(frame.IsValid())
        self.assertEqual(frame.GetPC(), 0x40000000000001FE)
