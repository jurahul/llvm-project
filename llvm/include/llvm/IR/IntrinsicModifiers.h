//===- IntrinsicModifiers.h - LLVM Intrinsic Modifier Handling --*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_IR_INTRINSIC_MODIFIERS_H
#define LLVM_IR_INTRINSIC_MODIFIERS_H

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"

namespace llvm {
class raw_ostream;
class IntrinsicInst;
class ConstantInt;
class LLVMContext;
} // namespace llvm

namespace llvm::Intrinsic {

bool HasModifiers(ID id);
// Returns the position of modifiers for the given intrinsics.
// first is true if they are at start, false if they are at end
// second is the number of modifier args.
std::pair<bool, unsigned> GetModifierArgPosition(ID id);

void PrintModifiers(raw_ostream &OS, const IntrinsicInst &I);
bool ParseModifiers(LLVMContext &Context, ID id, StringRef Suffix,
                    SmallVectorImpl<ConstantInt *> &ModArgs);

} // namespace llvm::Intrinsic

#endif // LLVM_IR_INTRINSIC_MODIFIERS_H