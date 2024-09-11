
#include "llvm/IR/IntrinsicModifiersNVVM.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include <tuple>
using namespace llvm;

#include "llvm/IR/IntrinsicModifiersGen.h"

namespace llvm::Intrinsic::nvvm {
void printFTZ(raw_ostream &OS, bool Ftz) { OS << (Ftz ? ".ftz" : ".noftz"); }

bool parseFTZ(StringRef &Suffix, bool &Ftz) {
  if (Suffix.consume_front(".ftz")) {
    Ftz = true;
    return false;
  }
  if (Suffix.consume_front(".noftz")) {
    Ftz = false;
    return false;
  }
  return true; // Parse error.
}

void printRND(raw_ostream &OS, uint8_t Rnd) {
  switch (static_cast<RndMode>(Rnd)) {
  case RndMode::RTN:
    OS << ".rtn";
    return;
  case RndMode::RTZ:
    OS << ".rtz";
    return;
  case RndMode::RDN:
    OS << ".rdn";
    return;
  case RndMode::RUP:
    OS << ".rup";
    return;
  }
  llvm_unreachable("Bad rounding mode encoded");
}

bool parseRND(StringRef &Suffix, uint8_t &Rnd) {
  static constexpr struct {
    StringLiteral Str;
    uint8_t Val;
  } Table[] = {
      {".rtn", static_cast<uint16_t>(RndMode::RTN)},
      {".rtz", static_cast<uint16_t>(RndMode::RTZ)},
      {".rdn", static_cast<uint16_t>(RndMode::RDN)},
      {".rup", static_cast<uint16_t>(RndMode::RUP)},
  };

  for (auto [Str, Val] : Table) {
    if (Suffix.consume_front(Str)) {
      Rnd = Val;
      return false;
    }
  }
  return true;
}

void printOp0Modifiers(raw_ostream &OS, FloatOp0Modifiers Mods) {
  // FloatOp1Modifiers = std::tuple<bool, uint16_t>
  printFTZ(OS, std::get<0>(Mods) != 0);
  printRND(OS, std::get<1>(Mods));
}

bool parseOp0Modifiers(StringRef Suffix, FloatOp0Modifiers &Mods) {
  bool Ftz;
  uint8_t Rnd;
  if (parseFTZ(Suffix, Ftz) || parseRND(Suffix, Rnd))
    return true;
  std::get<0>(Mods) = Ftz;
  std::get<1>(Mods) = Rnd;
  return false;
}

void printOp1Modifiers(raw_ostream &OS, FloatOp1Modifiers Mods) {
  Op1ModifiersPacked M;
  M.Packed = Mods;
  printFTZ(OS, M.Fields.Ftz);
  printRND(OS, M.Fields.Rnd);
}

bool parseOp1Modifiers(StringRef Suffix, FloatOp1Modifiers &Mods) {
  bool Ftz;
  uint8_t Rnd;
  if (parseFTZ(Suffix, Ftz) || parseRND(Suffix, Rnd))
    return true;

  // Pack sub-modifiers into a single value.
  Op1ModifiersPacked M;
  M.Packed = 0;
  M.Fields.Ftz = Ftz;
  M.Fields.Rnd = Rnd;
  Mods = M.Packed;
  return false;
}

void printOp2Modifiers(raw_ostream &OS, FloatOp2Modifiers Mods) {
  printOp1Modifiers(OS, Mods);
}

bool parseOp2Modifiers(StringRef Suffix, FloatOp2Modifiers &Mods) {
  return parseOp1Modifiers(Suffix, Mods);
}

} // namespace llvm::Intrinsic::nvvm