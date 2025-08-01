# NOTE: Assertions have been autogenerated by utils/update_mca_test_checks.py
// RUN: llvm-mca -mtriple=aarch64-unknown-linux-gnu -mcpu=neoverse-v2 -iterations=1 -resource-pressure=false < %s | FileCheck %s

.text
// LLVM-MCA-BEGIN Empty
// Empty sequence
// LLVM-MCA-END

  mul x1, x1, x1
// LLVM-MCA-BEGIN NotEmpty
  add x0, x0, x1
// LLVM-MCA-END
  mul x2, x2, x2

# CHECK:      [0] Code Region - NotEmpty

# CHECK:      Iterations:        1
# CHECK-NEXT: Instructions:      1
# CHECK-NEXT: Total Cycles:      4
# CHECK-NEXT: Total uOps:        1

# CHECK:      Dispatch Width:    6
# CHECK-NEXT: uOps Per Cycle:    0.25
# CHECK-NEXT: IPC:               0.25
# CHECK-NEXT: Block RThroughput: 0.2

# CHECK:      Instruction Info:
# CHECK-NEXT: [1]: #uOps
# CHECK-NEXT: [2]: Latency
# CHECK-NEXT: [3]: RThroughput
# CHECK-NEXT: [4]: MayLoad
# CHECK-NEXT: [5]: MayStore
# CHECK-NEXT: [6]: HasSideEffects (U)

# CHECK:      [1]    [2]    [3]    [4]    [5]    [6]    Instructions:
# CHECK-NEXT:  1      1     0.17                        add	x0, x0, x1
