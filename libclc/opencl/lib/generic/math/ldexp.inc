//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef __CLC_SCALAR

_CLC_OVERLOAD _CLC_DEF __CLC_GENTYPE ldexp(__CLC_GENTYPE x, int n) {
  return __clc_ldexp(x, (__CLC_INTN)n);
}

#endif
