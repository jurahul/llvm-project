//===-- DirectivesCommon.h --------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Coding style: https://mlir.llvm.org/getting_started/DeveloperGuide/
//
//===----------------------------------------------------------------------===//
///
/// A location to place directive utilities shared across multiple lowering
/// and optimizer files, e.g. utilities shared in OpenMP and OpenACC.
//===----------------------------------------------------------------------===//

#ifndef FORTRAN_OPTIMIZER_BUILDER_DIRECTIVESCOMMON_H_
#define FORTRAN_OPTIMIZER_BUILDER_DIRECTIVESCOMMON_H_

#include "BoxValue.h"
#include "FIRBuilder.h"
#include "flang/Optimizer/Builder/BoxValue.h"
#include "flang/Optimizer/Builder/FIRBuilder.h"
#include "flang/Optimizer/Builder/Todo.h"
#include "flang/Optimizer/HLFIR/HLFIROps.h"
#include "mlir/Dialect/OpenACC/OpenACC.h"
#include "mlir/Dialect/OpenMP/OpenMPDialect.h"

namespace fir::factory {

/// Information gathered to generate bounds operation and data entry/exit
/// operations.
struct AddrAndBoundsInfo {
  explicit AddrAndBoundsInfo() {}
  explicit AddrAndBoundsInfo(mlir::Value addr, mlir::Value rawInput)
      : addr(addr), rawInput(rawInput) {}
  explicit AddrAndBoundsInfo(mlir::Value addr, mlir::Value rawInput,
                             mlir::Value isPresent)
      : addr(addr), rawInput(rawInput), isPresent(isPresent) {}
  explicit AddrAndBoundsInfo(mlir::Value addr, mlir::Value rawInput,
                             mlir::Value isPresent, mlir::Type boxType)
      : addr(addr), rawInput(rawInput), isPresent(isPresent), boxType(boxType) {
  }
  mlir::Value addr = nullptr;
  mlir::Value rawInput = nullptr;
  mlir::Value isPresent = nullptr;
  mlir::Type boxType = nullptr;
  void dump(llvm::raw_ostream &os) {
    os << "AddrAndBoundsInfo addr: " << addr << "\n";
    os << "AddrAndBoundsInfo rawInput: " << rawInput << "\n";
    os << "AddrAndBoundsInfo isPresent: " << isPresent << "\n";
    os << "AddrAndBoundsInfo boxType: " << boxType << "\n";
  }
};

inline AddrAndBoundsInfo getDataOperandBaseAddr(fir::FirOpBuilder &builder,
                                                mlir::Value symAddr,
                                                bool isOptional,
                                                mlir::Location loc,
                                                bool unwrapFirBox = true) {
  mlir::Value rawInput = symAddr;
  if (auto declareOp =
          mlir::dyn_cast_or_null<hlfir::DeclareOp>(symAddr.getDefiningOp())) {
    symAddr = declareOp.getResults()[0];
    rawInput = declareOp.getResults()[1];
  }

  if (!symAddr)
    llvm::report_fatal_error("could not retrieve symbol address");

  mlir::Value isPresent;
  if (isOptional)
    isPresent =
        fir::IsPresentOp::create(builder, loc, builder.getI1Type(), rawInput);

  if (auto boxTy = mlir::dyn_cast<fir::BaseBoxType>(
          fir::unwrapRefType(symAddr.getType()))) {
    // In case of a box reference, load it here to get the box value.
    // This is preferrable because then the same box value can then be used for
    // all address/dimension retrievals. For Fortran optional though, leave
    // the load generation for later so it can be done in the appropriate
    // if branches.
    if (unwrapFirBox && mlir::isa<fir::ReferenceType>(symAddr.getType()) &&
        !isOptional) {
      mlir::Value addr = fir::LoadOp::create(builder, loc, symAddr);
      return AddrAndBoundsInfo(addr, rawInput, isPresent, boxTy);
    }

    return AddrAndBoundsInfo(symAddr, rawInput, isPresent, boxTy);
  }
  // For boxchar references, do the same as what is done above for box
  // references - Load the boxchar so that it is easier to retrieve the length
  // of the underlying character and the data pointer.
  if (auto boxCharType = mlir::dyn_cast<fir::BoxCharType>(
          fir::unwrapRefType((symAddr.getType())))) {
    if (!isOptional && mlir::isa<fir::ReferenceType>(symAddr.getType())) {
      mlir::Value boxChar = fir::LoadOp::create(builder, loc, symAddr);
      return AddrAndBoundsInfo(boxChar, rawInput, isPresent);
    }
  }
  return AddrAndBoundsInfo(symAddr, rawInput, isPresent);
}

template <typename BoundsOp, typename BoundsType>
llvm::SmallVector<mlir::Value>
gatherBoundsOrBoundValues(fir::FirOpBuilder &builder, mlir::Location loc,
                          fir::ExtendedValue dataExv, mlir::Value box,
                          bool collectValuesOnly = false) {
  assert(box && "box must exist");
  llvm::SmallVector<mlir::Value> values;
  mlir::Value byteStride;
  mlir::Type idxTy = builder.getIndexType();
  mlir::Type boundTy = builder.getType<BoundsType>();
  mlir::Value one = builder.createIntegerConstant(loc, idxTy, 1);
  for (unsigned dim = 0; dim < dataExv.rank(); ++dim) {
    mlir::Value d = builder.createIntegerConstant(loc, idxTy, dim);
    mlir::Value baseLb =
        fir::factory::readLowerBound(builder, loc, dataExv, dim, one);
    auto dimInfo =
        fir::BoxDimsOp::create(builder, loc, idxTy, idxTy, idxTy, box, d);
    mlir::Value lb = builder.createIntegerConstant(loc, idxTy, 0);
    mlir::Value ub =
        mlir::arith::SubIOp::create(builder, loc, dimInfo.getExtent(), one);
    if (dim == 0) // First stride is the element size.
      byteStride = dimInfo.getByteStride();
    if (collectValuesOnly) {
      values.push_back(lb);
      values.push_back(ub);
      values.push_back(dimInfo.getExtent());
      values.push_back(byteStride);
      values.push_back(baseLb);
    } else {
      mlir::Value bound =
          BoundsOp::create(builder, loc, boundTy, lb, ub, dimInfo.getExtent(),
                           byteStride, true, baseLb);
      values.push_back(bound);
    }
    // Compute the stride for the next dimension.
    byteStride = mlir::arith::MulIOp::create(builder, loc, byteStride,
                                             dimInfo.getExtent());
  }
  return values;
}
template <typename BoundsOp, typename BoundsType>
mlir::Value
genBoundsOpFromBoxChar(fir::FirOpBuilder &builder, mlir::Location loc,
                       fir::ExtendedValue dataExv, AddrAndBoundsInfo &info) {

  if (!mlir::isa<fir::BoxCharType>(fir::unwrapRefType(info.addr.getType())))
    return mlir::Value{};

  mlir::Type idxTy = builder.getIndexType();
  mlir::Type lenType = builder.getCharacterLengthType();
  mlir::Value zero = builder.createIntegerConstant(loc, idxTy, 0);
  mlir::Value one = builder.createIntegerConstant(loc, idxTy, 1);
  using ExtentAndStride = std::tuple<mlir::Value, mlir::Value>;
  auto [extent, stride] = [&]() -> ExtentAndStride {
    if (info.isPresent) {
      llvm::SmallVector<mlir::Type> resTypes = {idxTy, idxTy};
      mlir::Operation::result_range ifRes =
          builder
              .genIfOp(loc, resTypes, info.isPresent, /*withElseRegion=*/true)
              .genThen([&]() {
                mlir::Value boxChar =
                    fir::isa_ref_type(info.addr.getType())
                        ? fir::LoadOp::create(builder, loc, info.addr)
                        : info.addr;
                fir::BoxCharType boxCharType =
                    mlir::cast<fir::BoxCharType>(boxChar.getType());
                mlir::Type refType = builder.getRefType(boxCharType.getEleTy());
                auto unboxed = fir::UnboxCharOp::create(builder, loc, refType,
                                                        lenType, boxChar);
                mlir::SmallVector<mlir::Value> results = {unboxed.getResult(1),
                                                          one};
                fir::ResultOp::create(builder, loc, results);
              })
              .genElse([&]() {
                mlir::SmallVector<mlir::Value> results = {zero, zero};
                fir::ResultOp::create(builder, loc, results);
              })
              .getResults();
      return {ifRes[0], ifRes[1]};
    }
    // We have already established that info.addr.getType() is a boxchar
    // or a boxchar address. If an address, load the boxchar.
    mlir::Value boxChar = fir::isa_ref_type(info.addr.getType())
                              ? fir::LoadOp::create(builder, loc, info.addr)
                              : info.addr;
    fir::BoxCharType boxCharType =
        mlir::cast<fir::BoxCharType>(boxChar.getType());
    mlir::Type refType = builder.getRefType(boxCharType.getEleTy());
    auto unboxed =
        fir::UnboxCharOp::create(builder, loc, refType, lenType, boxChar);
    return {unboxed.getResult(1), one};
  }();

  mlir::Value ub = mlir::arith::SubIOp::create(builder, loc, extent, one);
  mlir::Type boundTy = builder.getType<BoundsType>();
  return BoundsOp::create(builder, loc, boundTy,
                          /*lower_bound=*/zero,
                          /*upper_bound=*/ub,
                          /*extent=*/extent,
                          /*stride=*/stride,
                          /*stride_in_bytes=*/true,
                          /*start_idx=*/zero);
}

/// Generate the bounds operation from the descriptor information.
template <typename BoundsOp, typename BoundsType>
llvm::SmallVector<mlir::Value>
genBoundsOpsFromBox(fir::FirOpBuilder &builder, mlir::Location loc,
                    fir::ExtendedValue dataExv, AddrAndBoundsInfo &info) {
  llvm::SmallVector<mlir::Value> bounds;
  mlir::Type idxTy = builder.getIndexType();
  mlir::Type boundTy = builder.getType<BoundsType>();

  assert(mlir::isa<fir::BaseBoxType>(info.boxType) &&
         "expect fir.box or fir.class");
  assert(fir::unwrapRefType(info.addr.getType()) == info.boxType &&
         "expected box type consistency");

  if (info.isPresent) {
    llvm::SmallVector<mlir::Type> resTypes;
    constexpr unsigned nbValuesPerBound = 5;
    for (unsigned dim = 0; dim < dataExv.rank() * nbValuesPerBound; ++dim)
      resTypes.push_back(idxTy);

    mlir::Operation::result_range ifRes =
        builder.genIfOp(loc, resTypes, info.isPresent, /*withElseRegion=*/true)
            .genThen([&]() {
              mlir::Value box =
                  !fir::isBoxAddress(info.addr.getType())
                      ? info.addr
                      : fir::LoadOp::create(builder, loc, info.addr);
              llvm::SmallVector<mlir::Value> boundValues =
                  gatherBoundsOrBoundValues<BoundsOp, BoundsType>(
                      builder, loc, dataExv, box,
                      /*collectValuesOnly=*/true);
              fir::ResultOp::create(builder, loc, boundValues);
            })
            .genElse([&] {
              // Box is not present. Populate bound values with default values.
              llvm::SmallVector<mlir::Value> boundValues;
              mlir::Value zero = builder.createIntegerConstant(loc, idxTy, 0);
              mlir::Value mOne = builder.createMinusOneInteger(loc, idxTy);
              for (unsigned dim = 0; dim < dataExv.rank(); ++dim) {
                boundValues.push_back(zero); // lb
                boundValues.push_back(mOne); // ub
                boundValues.push_back(zero); // extent
                boundValues.push_back(zero); // byteStride
                boundValues.push_back(zero); // baseLb
              }
              fir::ResultOp::create(builder, loc, boundValues);
            })
            .getResults();
    // Create the bound operations outside the if-then-else with the if op
    // results.
    for (unsigned i = 0; i < ifRes.size(); i += nbValuesPerBound) {
      mlir::Value bound =
          BoundsOp::create(builder, loc, boundTy, ifRes[i], ifRes[i + 1],
                           ifRes[i + 2], ifRes[i + 3], true, ifRes[i + 4]);
      bounds.push_back(bound);
    }
  } else {
    mlir::Value box = !fir::isBoxAddress(info.addr.getType())
                          ? info.addr
                          : fir::LoadOp::create(builder, loc, info.addr);
    bounds = gatherBoundsOrBoundValues<BoundsOp, BoundsType>(builder, loc,
                                                             dataExv, box);
  }
  return bounds;
}

/// Generate bounds operation for base array without any subscripts
/// provided.
template <typename BoundsOp, typename BoundsType>
llvm::SmallVector<mlir::Value>
genBaseBoundsOps(fir::FirOpBuilder &builder, mlir::Location loc,
                 fir::ExtendedValue dataExv, bool isAssumedSize,
                 bool strideIncludeLowerExtent = false) {
  mlir::Type idxTy = builder.getIndexType();
  mlir::Type boundTy = builder.getType<BoundsType>();
  llvm::SmallVector<mlir::Value> bounds;

  if (dataExv.rank() == 0)
    return bounds;

  mlir::Value one = builder.createIntegerConstant(loc, idxTy, 1);
  const unsigned rank = dataExv.rank();
  mlir::Value cumulativeExtent = one;
  for (unsigned dim = 0; dim < rank; ++dim) {
    mlir::Value baseLb =
        fir::factory::readLowerBound(builder, loc, dataExv, dim, one);
    mlir::Value zero = builder.createIntegerConstant(loc, idxTy, 0);
    mlir::Value ub;
    mlir::Value lb = zero;
    mlir::Value extent = fir::factory::readExtent(builder, loc, dataExv, dim);
    if (isAssumedSize && dim + 1 == rank) {
      extent = zero;
      ub = lb;
    } else {
      // ub = extent - 1
      ub = mlir::arith::SubIOp::create(builder, loc, extent, one);
    }
    mlir::Value stride = one;
    if (strideIncludeLowerExtent) {
      stride = cumulativeExtent;
      cumulativeExtent = builder.createOrFold<mlir::arith::MulIOp>(
          loc, cumulativeExtent, extent);
    }

    mlir::Value bound = BoundsOp::create(builder, loc, boundTy, lb, ub, extent,
                                         stride, false, baseLb);
    bounds.push_back(bound);
  }
  return bounds;
}

/// Checks if an argument is optional based on the fortran attributes
/// that are tied to it.
inline bool isOptionalArgument(mlir::Operation *op) {
  if (auto declareOp = mlir::dyn_cast_or_null<hlfir::DeclareOp>(op))
    if (declareOp.getFortranAttrs() &&
        bitEnumContainsAny(*declareOp.getFortranAttrs(),
                           fir::FortranVariableFlagsEnum::optional))
      return true;
  return false;
}

template <typename BoundsOp, typename BoundsType>
llvm::SmallVector<mlir::Value>
genImplicitBoundsOps(fir::FirOpBuilder &builder, AddrAndBoundsInfo &info,
                     fir::ExtendedValue dataExv, bool dataExvIsAssumedSize,
                     mlir::Location loc) {
  llvm::SmallVector<mlir::Value> bounds;

  mlir::Value baseOp = info.rawInput;
  if (mlir::isa<fir::BaseBoxType>(fir::unwrapRefType(baseOp.getType())))
    bounds =
        genBoundsOpsFromBox<BoundsOp, BoundsType>(builder, loc, dataExv, info);
  if (mlir::isa<fir::SequenceType>(fir::unwrapRefType(baseOp.getType()))) {
    bounds = genBaseBoundsOps<BoundsOp, BoundsType>(builder, loc, dataExv,
                                                    dataExvIsAssumedSize);
  }
  if (characterWithDynamicLen(fir::unwrapRefType(baseOp.getType())) ||
      mlir::isa<fir::BoxCharType>(fir::unwrapRefType(info.addr.getType()))) {
    bounds = {genBoundsOpFromBoxChar<BoundsOp, BoundsType>(builder, loc,
                                                           dataExv, info)};
  }
  return bounds;
}

} // namespace fir::factory
#endif // FORTRAN_OPTIMIZER_BUILDER_DIRECTIVESCOMMON_H_
