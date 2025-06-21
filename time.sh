#!/bin/bash

declare -a commands=(
"./build/bin/llvm-mc -triple=amdgcn -mcpu=gfx1010 -mattr=+wavefrontsize32 -disassemble -show-encoding llvm/test/MC/Disassembler/AMDGPU/gfx10-wave32.txt -o -"
"./build/bin/llvm-mc -triple=amdgcn -mcpu=gfx1010 -disassemble -show-encoding                         llvm/test/MC/Disassembler/AMDGPU/gfx10-vop3-literal.txt -o -"
"./build/bin/llvm-mc -triple=amdgcn -mcpu=gfx1200 -mattr=+wavefrontsize64 -disassemble -show-encoding llvm/test/MC/Disassembler/AMDGPU/gfx12_dasm_vop3p_dpp8.txt -o -"
)

for c in "${commands[@]}"; do
  $c > /dev/null 2>&1 && python3 -m json.tool /tmp/xyz | grep -A 3 "Total Decode successful inst" | grep "avg ms"
done
