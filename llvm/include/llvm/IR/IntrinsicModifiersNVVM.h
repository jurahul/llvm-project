
#ifndef LLVM_IR_INTRINSIC_MODIFIERS_NVVM_H
#define LLVM_IR_INTRINSIC_MODIFIERS_NVVM_H

#include <cstdint>

namespace llvm {
class raw_ostream;
class StringRef;
} // namespace llvm

namespace llvm::Intrinsic::nvvm {

enum class RndMode {
  RTN,
  RTZ,
  RDN,
  RUP,
};

union Op1ModifiersPacked {
  struct {
    uint32_t Rnd : 2;
    uint32_t Pad0 : 6;
    uint32_t Ftz : 1;
    uint32_t Pad1 : 23;
  } Fields;
  uint32_t Packed;
};
static_assert(sizeof(Op1ModifiersPacked) == sizeof(uint32_t));

void printFTZ(raw_ostream &OS, bool Ftz);
bool parseFTZ(StringRef &Suffix, bool &Ftz);

void printRND(raw_ostream &OS, uint8_t Rnd);
bool parseRND(StringRef &Suffix, uint8_t &Rnd);

} // namespace llvm::Intrinsic::nvvm

#endif // LLVM_IR_INTRINSIC_MODIFIERS_NVVM_H
