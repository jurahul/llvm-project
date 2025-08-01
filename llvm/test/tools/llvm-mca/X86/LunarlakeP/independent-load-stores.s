# NOTE: Assertions have been autogenerated by utils/update_mca_test_checks.py
# RUN: llvm-mca -mtriple=x86_64-unknown-unknown -mcpu=lunarlake -timeline -timeline-max-iterations=1 < %s | FileCheck %s -check-prefixes=ALL,NOALIAS
# RUN: llvm-mca -mtriple=x86_64-unknown-unknown -mcpu=lunarlake -timeline -timeline-max-iterations=1 -noalias=false < %s | FileCheck %s -check-prefixes=ALL,YESALIAS

  addq	$44, 64(%r14)
  addq	$44, 128(%r14)
  addq	$44, 192(%r14)
  addq	$44, 256(%r14)
  addq	$44, 320(%r14)
  addq	$44, 384(%r14)
  addq	$44, 448(%r14)
  addq	$44, 512(%r14)
  addq	$44, 576(%r14)
  addq	$44, 640(%r14)

# ALL:           Iterations:        100
# ALL-NEXT:      Instructions:      1000

# NOALIAS-NEXT:  Total Cycles:      681
# YESALIAS-NEXT: Total Cycles:      12003

# ALL-NEXT:      Total uOps:        4000

# ALL:           Dispatch Width:    8

# NOALIAS-NEXT:  uOps Per Cycle:    5.87
# NOALIAS-NEXT:  IPC:               1.47

# YESALIAS-NEXT: uOps Per Cycle:    0.33
# YESALIAS-NEXT: IPC:               0.08

# ALL-NEXT:      Block RThroughput: 6.7

# ALL:           Instruction Info:
# ALL-NEXT:      [1]: #uOps
# ALL-NEXT:      [2]: Latency
# ALL-NEXT:      [3]: RThroughput
# ALL-NEXT:      [4]: MayLoad
# ALL-NEXT:      [5]: MayStore
# ALL-NEXT:      [6]: HasSideEffects (U)

# ALL:           [1]    [2]    [3]    [4]    [5]    [6]    Instructions:
# ALL-NEXT:       4      12    0.67    *      *            addq	$44, 64(%r14)
# ALL-NEXT:       4      12    0.67    *      *            addq	$44, 128(%r14)
# ALL-NEXT:       4      12    0.67    *      *            addq	$44, 192(%r14)
# ALL-NEXT:       4      12    0.67    *      *            addq	$44, 256(%r14)
# ALL-NEXT:       4      12    0.67    *      *            addq	$44, 320(%r14)
# ALL-NEXT:       4      12    0.67    *      *            addq	$44, 384(%r14)
# ALL-NEXT:       4      12    0.67    *      *            addq	$44, 448(%r14)
# ALL-NEXT:       4      12    0.67    *      *            addq	$44, 512(%r14)
# ALL-NEXT:       4      12    0.67    *      *            addq	$44, 576(%r14)
# ALL-NEXT:       4      12    0.67    *      *            addq	$44, 640(%r14)

# ALL:           Resources:
# ALL-NEXT:      [0]   - LNLPPort00
# ALL-NEXT:      [1]   - LNLPPort01
# ALL-NEXT:      [2]   - LNLPPort02
# ALL-NEXT:      [3]   - LNLPPort03
# ALL-NEXT:      [4]   - LNLPPort04
# ALL-NEXT:      [5]   - LNLPPort05
# ALL-NEXT:      [6]   - LNLPPort10
# ALL-NEXT:      [7]   - LNLPPort11
# ALL-NEXT:      [8]   - LNLPPort20
# ALL-NEXT:      [9]   - LNLPPort21
# ALL-NEXT:      [10]  - LNLPPort22
# ALL-NEXT:      [11]  - LNLPPort25
# ALL-NEXT:      [12]  - LNLPPort26
# ALL-NEXT:      [13]  - LNLPPort27
# ALL-NEXT:      [14]  - LNLPPortInvalid
# ALL-NEXT:      [15]  - LNLPVPort00
# ALL-NEXT:      [16]  - LNLPVPort01
# ALL-NEXT:      [17]  - LNLPVPort02
# ALL-NEXT:      [18]  - LNLPVPort03

# ALL:           Resource pressure per iteration:
# ALL-NEXT:      [0]    [1]    [2]    [3]    [4]    [5]    [6]    [7]    [8]    [9]    [10]   [11]   [12]   [13]   [14]   [15]   [16]   [17]   [18]
# ALL-NEXT:       -     3.33    -     3.33    -     3.34   5.00   5.00   6.66   6.66   6.68   3.33   3.33   3.34    -      -      -      -      -

# ALL:           Resource pressure by instruction:
# ALL-NEXT:      [0]    [1]    [2]    [3]    [4]    [5]    [6]    [7]    [8]    [9]    [10]   [11]   [12]   [13]   [14]   [15]   [16]   [17]   [18]   Instructions:
# ALL-NEXT:       -     0.33    -     0.33    -     0.34    -     1.00   0.66   0.66   0.68   0.33   0.33   0.34    -      -      -      -      -     addq	$44, 64(%r14)
# ALL-NEXT:       -     0.33    -     0.34    -     0.33   1.00    -     0.66   0.68   0.66   0.33   0.34   0.33    -      -      -      -      -     addq	$44, 128(%r14)
# ALL-NEXT:       -     0.34    -     0.33    -     0.33    -     1.00   0.68   0.66   0.66   0.34   0.33   0.33    -      -      -      -      -     addq	$44, 192(%r14)
# ALL-NEXT:       -     0.33    -     0.33    -     0.34   1.00    -     0.66   0.66   0.68   0.33   0.33   0.34    -      -      -      -      -     addq	$44, 256(%r14)
# ALL-NEXT:       -     0.33    -     0.34    -     0.33    -     1.00   0.66   0.68   0.66   0.33   0.34   0.33    -      -      -      -      -     addq	$44, 320(%r14)
# ALL-NEXT:       -     0.34    -     0.33    -     0.33   1.00    -     0.68   0.66   0.66   0.34   0.33   0.33    -      -      -      -      -     addq	$44, 384(%r14)
# ALL-NEXT:       -     0.33    -     0.33    -     0.34    -     1.00   0.66   0.66   0.68   0.33   0.33   0.34    -      -      -      -      -     addq	$44, 448(%r14)
# ALL-NEXT:       -     0.33    -     0.34    -     0.33   1.00    -     0.66   0.68   0.66   0.33   0.34   0.33    -      -      -      -      -     addq	$44, 512(%r14)
# ALL-NEXT:       -     0.34    -     0.33    -     0.33    -     1.00   0.68   0.66   0.66   0.34   0.33   0.33    -      -      -      -      -     addq	$44, 576(%r14)
# ALL-NEXT:       -     0.33    -     0.33    -     0.34   1.00    -     0.66   0.66   0.68   0.33   0.33   0.34    -      -      -      -      -     addq	$44, 640(%r14)

# ALL:           Timeline view:

# NOALIAS-NEXT:                      0123456789
# NOALIAS-NEXT:  Index     0123456789          0

# YESALIAS-NEXT:                     0123456789          0123456789          0123456789          01234
# YESALIAS-NEXT: Index     0123456789          0123456789          0123456789          0123456789

# NOALIAS:       [0,0]     DeeeeeeeeeeeeER.    .   addq	$44, 64(%r14)
# NOALIAS-NEXT:  [0,1]     DeeeeeeeeeeeeER.    .   addq	$44, 128(%r14)
# NOALIAS-NEXT:  [0,2]     .DeeeeeeeeeeeeER    .   addq	$44, 192(%r14)
# NOALIAS-NEXT:  [0,3]     .D=eeeeeeeeeeeeER   .   addq	$44, 256(%r14)
# NOALIAS-NEXT:  [0,4]     . DeeeeeeeeeeeeER   .   addq	$44, 320(%r14)
# NOALIAS-NEXT:  [0,5]     . D=eeeeeeeeeeeeER  .   addq	$44, 384(%r14)
# NOALIAS-NEXT:  [0,6]     .  D=eeeeeeeeeeeeER .   addq	$44, 448(%r14)
# NOALIAS-NEXT:  [0,7]     .  D=eeeeeeeeeeeeER .   addq	$44, 512(%r14)
# NOALIAS-NEXT:  [0,8]     .   D=eeeeeeeeeeeeER.   addq	$44, 576(%r14)
# NOALIAS-NEXT:  [0,9]     .   D==eeeeeeeeeeeeER   addq	$44, 640(%r14)

# YESALIAS:      [0,0]     DeeeeeeeeeeeeER.    .    .    .    .    .    .    .    .    .    .    .   .   addq	$44, 64(%r14)
# YESALIAS-NEXT: [0,1]     D============eeeeeeeeeeeeER   .    .    .    .    .    .    .    .    .   .   addq	$44, 128(%r14)
# YESALIAS-NEXT: [0,2]     .D=======================eeeeeeeeeeeeER .    .    .    .    .    .    .   .   addq	$44, 192(%r14)
# YESALIAS-NEXT: [0,3]     .D===================================eeeeeeeeeeeeER    .    .    .    .   .   addq	$44, 256(%r14)
# YESALIAS-NEXT: [0,4]     . D==============================================eeeeeeeeeeeeER  .    .   .   addq	$44, 320(%r14)
# YESALIAS-NEXT: [0,5]     . D==========================================================eeeeeeeeeeeeER   addq	$44, 384(%r14)
# YESALIAS-NEXT: Truncated display due to cycle limit

# ALL:           Average Wait times (based on the timeline view):
# ALL-NEXT:      [0]: Executions
# ALL-NEXT:      [1]: Average time spent waiting in a scheduler's queue
# ALL-NEXT:      [2]: Average time spent waiting in a scheduler's queue while ready
# ALL-NEXT:      [3]: Average time elapsed from WB until retire stage

# ALL:                 [0]    [1]    [2]    [3]
# ALL-NEXT:      0.     1     1.0    1.0    0.0       addq	$44, 64(%r14)

# NOALIAS-NEXT:  1.     1     1.0    0.0    0.0       addq	$44, 128(%r14)
# NOALIAS-NEXT:  2.     1     1.0    1.0    0.0       addq	$44, 192(%r14)
# NOALIAS-NEXT:  3.     1     2.0    1.0    0.0       addq	$44, 256(%r14)
# NOALIAS-NEXT:  4.     1     1.0    0.0    0.0       addq	$44, 320(%r14)
# NOALIAS-NEXT:  5.     1     2.0    1.0    0.0       addq	$44, 384(%r14)
# NOALIAS-NEXT:  6.     1     2.0    1.0    0.0       addq	$44, 448(%r14)
# NOALIAS-NEXT:  7.     1     2.0    0.0    0.0       addq	$44, 512(%r14)
# NOALIAS-NEXT:  8.     1     2.0    1.0    0.0       addq	$44, 576(%r14)
# NOALIAS-NEXT:  9.     1     3.0    1.0    0.0       addq	$44, 640(%r14)
# NOALIAS-NEXT:         1     1.7    0.7    0.0       <total>

# YESALIAS-NEXT: 1.     1     13.0   0.0    0.0       addq	$44, 128(%r14)
# YESALIAS-NEXT: 2.     1     24.0   0.0    0.0       addq	$44, 192(%r14)
# YESALIAS-NEXT: 3.     1     36.0   0.0    0.0       addq	$44, 256(%r14)
# YESALIAS-NEXT: 4.     1     47.0   0.0    0.0       addq	$44, 320(%r14)
# YESALIAS-NEXT: 5.     1     59.0   0.0    0.0       addq	$44, 384(%r14)
# YESALIAS-NEXT: 6.     1     70.0   0.0    0.0       addq	$44, 448(%r14)
# YESALIAS-NEXT: 7.     1     82.0   0.0    0.0       addq	$44, 512(%r14)
# YESALIAS-NEXT: 8.     1     93.0   0.0    0.0       addq	$44, 576(%r14)
# YESALIAS-NEXT: 9.     1     105.0  0.0    0.0       addq	$44, 640(%r14)
# YESALIAS-NEXT:        1     53.0   0.1    0.0       <total>
