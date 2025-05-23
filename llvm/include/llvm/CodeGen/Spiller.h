//===- llvm/CodeGen/Spiller.h - Spiller -------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CODEGEN_SPILLER_H
#define LLVM_CODEGEN_SPILLER_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/CodeGen/Register.h"

namespace llvm {

class LiveRangeEdit;
class MachineFunction;
class MachineFunctionPass;
class VirtRegMap;
class VirtRegAuxInfo;
class LiveIntervals;
class LiveRegMatrix;
class LiveStacks;
class MachineDominatorTree;
class MachineBlockFrequencyInfo;
class AllocationOrder;

/// Spiller interface.
///
/// Implementations are utility classes which insert spill or remat code on
/// demand.
class Spiller {
  virtual void anchor();

public:
  virtual ~Spiller() = 0;

  /// spill - Spill the LRE.getParent() live interval.
  virtual void spill(LiveRangeEdit &LRE, AllocationOrder *Order = nullptr) = 0;

  /// Return the registers that were spilled.
  virtual ArrayRef<Register> getSpilledRegs() = 0;

  /// Return registers that were not spilled, but otherwise replaced
  /// (e.g. rematerialized).
  virtual ArrayRef<Register> getReplacedRegs() = 0;

  virtual void postOptimization() {}

  struct RequiredAnalyses {
    LiveIntervals &LIS;
    LiveStacks &LSS;
    MachineDominatorTree &MDT;
    const MachineBlockFrequencyInfo &MBFI;
  };
};

/// Create and return a spiller that will insert spill code directly instead
/// of deferring though VirtRegMap.
Spiller *createInlineSpiller(const Spiller::RequiredAnalyses &Analyses,
                             MachineFunction &MF, VirtRegMap &VRM,
                             VirtRegAuxInfo &VRAI,
                             LiveRegMatrix *Matrix = nullptr);

} // end namespace llvm

#endif // LLVM_CODEGEN_SPILLER_H
