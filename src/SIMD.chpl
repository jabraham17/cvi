module SIMD {
  config param implementationWarnings = true;
  use Types;
  use IO;
  use CTypes only c_ptr, c_ptrConst, c_ptrTo, c_ptrToConst, c_addrOf, c_addrOfConst;
  import Intrin;

  record vector: writeSerializable {
    type eltType;
    param numElts: int;
    var data: Intrin.vectorType(eltType, numElts);

    /* type init*/
    proc init(type eltType, param numElts: int) {
      this.eltType = eltType;
    this.numElts = numElts;
      this.data = Intrin.splat(eltType, numElts, 0:eltType);
    }
    /* init to single value */
    proc init(type eltType, param numElts: int, value: eltType) {
      this.eltType = eltType;
      this.numElts = numElts;
      this.data = Intrin.splat(eltType, numElts, value);
    }
    /* init to single value, infer type */
    proc init(param numElts: int, value: ?eltType) {
      this.eltType = eltType;
      this.numElts = numElts;
      this.data = Intrin.splat(eltType, numElts, value);
    }

    //
    // init from other vector
    //
    proc init(type eltType, param numElts: int, value: vector(eltType, numElts)) {
      this.eltType = eltType;
      this.numElts = numElts;
      this.data = value.data;
    }
    proc init=(value: vector(?)) {
      this.eltType = value.eltType;
      this.numElts = value.numElts;
      this.data = value.data;
    }
    inline operator=(ref lhs: vector(?), rhs: lhs.type) {
      lhs.data = rhs.data;
    }

    //
    // init from tuple
    //
    proc init(values) where isHomogeneousTupleType(values.type) {
      this.eltType = values(0).type;
      this.numElts = values.size;
      this.data = Intrin.set(this.eltType, this.numElts, values);
    }
    proc init=(values) where isHomogeneousTupleType(values.type) {
      this.eltType = values(0).type;
      this.numElts = values.size;
      this.data = Intrin.set(this.eltType, this.numElts, values);
    }
    inline operator=(ref lhs, rhs) where isSubtype(lhs.type, vector) &&
                                         isHomogeneousTupleType(rhs.type) &&
                                         isCoercible(rhs(0).type, lhs.eltType) &&
                                         lhs.numElts == rhs.size {
      lhs.set(rhs);
    }
    inline operator:(x: ?tupType, type t: vector(?))
      where isHomogeneousTupleType(tupType) &&
            isCoercible(x(0).type, t.eltType) &&
            x.size == t.numElts {

      var result: t;
      result.set(x);
      return result;
    }

    //
    // init from scalar
    //
    inline operator:(x: ?eltType, type t: vector(?))
      where isCoercible(eltType, t.eltType) {
      var result: t;
      result.set(x);
      return result;
    }

    //
    // cast to tuple
    //
    inline operator:(x: vector(?eltType, ?numElts), type tupType)
      where isHomogeneousTupleType(tupType) &&
            isCoercible(eltType, tupType(0)) &&
            tupType.size == numElts {
      type resEltType = tupType(0);
      var result: tupType;
      for param i in 0..#numElts {
        result(i) = x[i]:resEltType;
      }
      return result;
    }

    /* VECTOR + VECTOR */
    inline operator+(x: vector(?eltType, ?numElts), y: x.type): x.type {
      var result: x.type;
      result.data = Intrin.add(eltType, numElts, x.data, y.data);
      return result;
    }
    inline operator+=(ref x: vector(?eltType, ?numElts), y: x.type) do
      x.data = Intrin.add(eltType, numElts, x.data, y.data);

    /* VECTOR + SCALAR */
    inline operator+(x: vector(?eltType, ?numElts), y: ?scalarType): x.type
      where isCoercible(scalarType, eltType) {
      var result: x.type;
      result.data = Intrin.add(eltType, numElts, x.data,
                      Intrin.splat(eltType, numElts, y));
      return result;
    }
    inline operator+=(ref x: vector(?eltType, ?numElts), y: ?scalarType)
      where isCoercible(scalarType, eltType) do
      x.data = Intrin.add(eltType, numElts, x.data,
                      Intrin.splat(eltType, numElts, y));

    /* SCALAR + VECTOR */
    inline operator+(x: ?scalarType, y: vector(?eltType, ?numElts)): y.type
      where isCoercible(scalarType, eltType) {
      var result: y.type;
      result.data = Intrin.add(eltType, numElts,
                      Intrin.splat(eltType, numElts, x), y.data);
      return result;
    }

    /* VECTOR - VECTOR */
    inline operator-(x: vector(?eltType, ?numElts), y: x.type): x.type {
      var result: x.type;
      result.data = Intrin.sub(eltType, numElts, x.data, y.data);
      return result;
    }
    inline operator-=(ref x: vector(?eltType, ?numElts), y: x.type) do
      x.data = Intrin.sub(eltType, numElts, x.data, y.data);

    /* VECTOR - SCALAR */
    inline operator-(x: vector(?eltType, ?numElts), y: ?scalarType): x.type
      where isCoercible(scalarType, eltType) {
      var result: x.type;
      result.data = Intrin.sub(eltType, numElts, x.data,
                      Intrin.splat(eltType, numElts, y));
      return result;
    }
    inline operator-=(ref x: vector(?eltType, ?numElts), y: ?scalarType)
      where isCoercible(scalarType, eltType) do
      x.data = Intrin.sub(eltType, numElts, x.data,
                      Intrin.splat(eltType, numElts, y));

    /* SCALAR - VECTOR */
    inline operator-(x: ?scalarType, y: vector(?eltType, ?numElts)): y.type
      where isCoercible(scalarType, eltType) {
      var result: y.type;
      result.data = Intrin.sub(eltType, numElts,
                      Intrin.splat(eltType, numElts, x), y.data);
      return result;
    }

    /* VECTOR * VECTOR */
    inline operator*(x: vector(?eltType, ?numElts), y: x.type): x.type {
      var result: x.type;
      result.data = Intrin.mul(eltType, numElts, x.data, y.data);
      return result;
    }
    inline operator*=(ref x:vector(?eltType, ?numElts), y: x.type) do
      x.data = Intrin.mul(eltType, numElts, x.data, y.data);

    /* VECTOR * SCALAR */
    inline operator*(x: vector(?eltType, ?numElts), y: ?scalarType): x.type
      where isCoercible(scalarType, eltType) {
      var result: x.type;
      result.data = Intrin.mul(eltType, numElts, x.data,
                      Intrin.splat(eltType, numElts, y));
      return result;
    }
    inline operator*=(ref x: vector(?eltType, ?numElts), y: ?scalarType) 
      where isCoercible(scalarType, eltType) do
      x.data = Intrin.mul(eltType, numElts, x.data,
                      Intrin.splat(eltType, numElts, y));

    /* SCALAR * VECTOR */
    inline operator*(x: ?scalarType, y: vector(?eltType, ?numElts)): y.type
      where isCoercible(scalarType, eltType) {
      var result: y.type;
      result.data = Intrin.mul(eltType, numElts,
                      Intrin.splat(eltType, numElts, x), y.data);
      return result;
    }

    /* VECTOR / VECTOR */
    inline operator/(x: vector(?eltType, ?numElts), y: x.type): x.type {
      var result: x.type;
      result.data = Intrin.div(eltType, numElts, x.data, y.data);
      return result;
    }
    inline operator/=(ref x: vector(?eltType, ?numElts), y: x.type) do
      x.data = Intrin.div(eltType, numElts, x.data, y.data);

    /* VECTOR / SCALAR */
    inline operator/(x: vector(?eltType, ?numElts), y: ?scalarType): x.type
      where isCoercible(scalarType, eltType) {
      var result: x.type;
      result.data = Intrin.div(eltType, numElts, x.data,
                      Intrin.splat(eltType, numElts, y));
      return result;
    }
    inline operator/=(ref x: vector(?eltType, ?numElts), y: ?scalarType)
      where isCoercible(scalarType, eltType) do
      x.data = Intrin.div(eltType, numElts, x.data,
                      Intrin.splat(eltType, numElts, y));

    /* SCALAR / VECTOR */
    inline operator/(x: ?scalarType, y: vector(?eltType, ?numElts)): y.type
      where isCoercible(scalarType, eltType) {
      var result: y.type;
      result.data = Intrin.div(eltType, numElts,
                      Intrin.splat(eltType, numElts, x), y.data);
      return result;
    }

    inline proc ref set(value) where isCoercible(value.type, eltType) do
      data = Intrin.splat(eltType, numElts, value:eltType);
    inline proc ref set(values) where isHomogeneousTupleType(values.type) &&
                                      isCoercible(values(0).type, eltType) &&
                                      values.size == numElts {
      var values_: numElts*eltType;
      for param i in 0..<numElts do
        values_[i] = values[i]:eltType;
      data = Intrin.set(eltType, numElts, values_);
    }
    inline proc ref set(param idx: int, value)
      where isCoercible(value.type, eltType) do
      data = Intrin.insert(eltType, numElts, data, value:eltType, idx);

    inline proc this(param idx: int): eltType do
      return Intrin.extract(eltType, numElts, data, idx);
    inline iter these(): eltType {
      for param i in 0..#numElts {
        yield this[i];
      }
    }

    @chpldoc.nodoc
    inline proc type _computeAddress(ref arr: [] eltType, idx: int): c_ptr(eltType)
      where arr.rank == 1 && arr.isRectangular() && arr._value.isDefaultRectangular() {
      if boundsChecking {
        // TODO
      }
      const ptr = c_addrOf(arr[idx]);
      return ptr;
    }
    @chpldoc.nodoc
    inline proc type _computeAddressConst(arr: [] eltType, idx: int): c_ptrConst(eltType)
      where arr.rank == 1 && arr.isRectangular() && arr._value.isDefaultRectangular() {
      if boundsChecking {
        // TODO
      }
      const ptr = c_addrOfConst(arr[idx]);
      return ptr;
    }
    @chpldoc.nodoc
    inline proc type _computeAddress(tup, idx: int = 0): c_ptr(eltType)
      where isHomogeneousTuple(tup) && tup(0).type == eltType {
      if boundsChecking {
        if idx+numElts-1 >= tup.size {
          halt("out of bounds load");
        }
      }
      const ptr = c_addrOf(tup(idx));
      return ptr;
    }

    inline proc ref load(ptr: c_ptrConst(eltType),
                         idx: int = 0,
                         param aligned: bool = false) {
      var ptr_ = ptr + idx;
      if aligned then
        data = Intrin.loadAligned(eltType, numElts, ptr_);
      else
        data = Intrin.loadUnaligned(eltType, numElts, ptr_);
    }
    inline proc ref load(arr: [] eltType,
                         idx: int = 0,
                         param aligned: bool = false)
      where arr.rank == 1 && arr.isRectangular() && arr._value.isDefaultRectangular() do
      load(this.type._computeAddressConst(arr, idx), idx=0, aligned=aligned);
    inline proc ref load(tup, idx: int = 0, param aligned: bool = false)
      where isHomogeneousTuple(tup) && tup(0).type == eltType do
      load(this.type._computeAddress(tup, idx), idx=0, aligned=aligned);

    inline proc store(ptr: c_ptr(eltType),
                      idx: int = 0,
                      param aligned: bool = false) {
      var ptr_ = ptr + idx;
      if aligned then
        Intrin.storeAligned(eltType, numElts, ptr_, data);
      else
        Intrin.storeUnaligned(eltType, numElts, ptr_, data);
    }
    inline proc ref store(ref arr: [] eltType,
                          idx: int = 0,
                          param aligned: bool = false)
      where arr.rank == 1 && arr.isRectangular() && arr._value.isDefaultRectangular() do
      store(this.type._computeAddress(arr, idx), idx=0, aligned=aligned);

    inline proc store(ref tup, idx: int = 0, param aligned: bool = false)
      where isHomogeneousTuple(tup) && tup(0).type == eltType {
      if boundsChecking {
        if idx+numElts-1 >= tup.size {
          halt("out of bounds store");
        }
      }
      store(this.type._computeAddress(tup, idx), idx=0, aligned=aligned);
    }
    inline proc type load(container: ?t,
                          idx: int = 0,
                          param aligned: bool = false): this {
      var result: this;
      result.load(container, idx=idx, aligned=aligned);
      return result;
    }

    // compares
    // bitmath (and, or, not, xor)
    // abs, min, max
    // transmute (bitcast)
    // typecaste


    // TODO: we should have standalone, leader, and follower versions of all of these
    inline iter type indicies(rng): rng.idxType
      where isSubtype(rng.type, range(?)) || isSubtype(rng.type, domain(?)) {
      for i in rng by numElts {
        yield i;
      }
    }
    inline iter type vectors(tup, param aligned: bool = false): this
      where isHomogeneousTuple(tup) && tup(0).type == eltType {
      for i in 0..#tup.size by numElts {
        yield this.load(tup, i, aligned=aligned);
      }
    }
    inline iter type vectors(arr: [], param aligned: bool = false): this {
      // TODO: how can I avoid the extra load per loop of the array metadata?
      for i in arr.domain by numElts {
        yield this.load(arr, i, aligned=aligned);
      }
    }
    inline iter type vectorsRef(ref arr: [], param aligned: bool = false) ref : vectorRef(this, aligned) {
      // TODO: how can I avoid the extra load per loop of the array metadata?
      for i in arr.domain by numElts {
        var vr = new vectorRef(this, this._computeAddress(arr, i), aligned=aligned);
        yield vr;
      }
    }
    inline iter type vectorsJagged(arr: [], pad: eltType = 0, param aligned: bool = false): this {
      // TODO: is this really the most efficient way to do this?
      // this should iterate over a range, and pad the extra with 'pad'
      // so that the last iteration is a full vector
      for i in arr.domain by numElts {
        writeln("i: ", i);
        if i+numElts <= arr.domain.high then
          yield this.load(arr, i, aligned=aligned);
        else {
          var tup: numElts*eltType;
          for param j in 0..#numElts do tup(j) = pad;
          for j in 0..#(arr.domain.high-i+1) do tup(j) = arr[i+j];
          yield this.load(tup, aligned=aligned);
        }
      }
    }


    proc serialize(writer, ref serializer) throws {
      var s: string;
      var sep = "";
      for param i in 0..#numElts {
        writer.write(sep, this[i]);
        sep = ", ";
      }
      return s;
    }
  }


  inline proc swapPairs(x: vector(?eltType, ?numElts)): x.type {
    var result: x.type;
    result.data = Intrin.swapPairs(eltType, numElts, x.data);
    return result;
  }
  inline proc swapLowHigh(x: vector(?eltType, ?numElts)): x.type {
    var result: x.type;
    result.data = Intrin.swapLowHigh(eltType, numElts, x.data);
    return result;
  }
  inline proc reverse(x: vector(?eltType, ?numElts)): x.type {
    var result: x.type;
    result.data = Intrin.reverse(eltType, numElts, x.data);
    return result;
  }
  inline proc rotateLeft(x: vector(?eltType, ?numElts)): x.type {
    var result: x.type;
    result.data = Intrin.rotateLeft(eltType, numElts, x.data);
    return result;
  }
  inline proc rotateRight(x: vector(?eltType, ?numElts)): x.type {
    var result: x.type;
    result.data = Intrin.rotateRight(eltType, numElts, x.data);
    return result;
  }
  inline proc interleaveLower(x: vector(?eltType, ?numElts), y: x.type): x.type {
    var result: x.type;
    result.data = Intrin.interleaveLower(eltType, numElts, x.data, y.data);
    return result;
  }
  inline proc interleaveUpper(x: vector(?eltType, ?numElts), y: x.type): x.type {
    var result: x.type;
    result.data = Intrin.interleaveUpper(eltType, numElts, x.data, y.data);
    return result;
  }
  inline proc deinterleaveLower(x: vector(?eltType, ?numElts), y: x.type): x.type {
    var result: x.type;
    result.data = Intrin.deinterleaveLower(eltType, numElts, x.data, y.data);
    return result;
  }
  inline proc deinterleaveUpper(x: vector(?eltType, ?numElts), y: x.type): x.type {
    var result: x.type;
    result.data = Intrin.deinterleaveUpper(eltType, numElts, x.data, y.data);
    return result;
  }

  /*
    pairwise add adjacent elements

    x: [a, b, c, d]
    y: [e, f, g, h]

    returns: [a+b, e+f, c+d, g+h]
  */
  inline proc pairwiseAdd(x: vector(?eltType, ?numElts), y: x.type): x.type {
    var result: x.type;
    result.data = Intrin.hadd(eltType, numElts, x.data, y.data);
    return result;
  }

  /*
    takes the low half of x and the high half of y
  */
  inline proc blendLowHigh(x: vector(?eltType, ?numElts), y: x.type): x.type {
    var result: x.type;
    result.data = Intrin.blendLowHigh(eltType, numElts, x.data, y.data);
    return result;
  }


  proc sqrt(x: vector(?eltType, ?numElts)): x.type {
    var result: x.type;
    result.data = Intrin.sqrt(eltType, numElts, x.data);
    return result;
  }
  proc rsqrt(x: vector(?eltType, ?numElts)): x.type {
    var result: x.type;
    result.data = Intrin.rsqrt(eltType, numElts, x.data);
    return result;
  }

  inline proc fma(x: vector(?eltType, ?numElts),
                    y: x.type,
                    z: x.type): x.type {
    var result: x.type;
    result.data = Intrin.fmadd(eltType, numElts, x.data, y.data, z.data);
    return result;
  }
  inline proc fms(x: vector(?eltType, ?numElts),
                    y: x.type,
                    z: x.type): x.type {
    var result: x.type;
    result.data = Intrin.fmsub(eltType, numElts, x.data, y.data, z.data);
    return result;
  }

  /* a transparent record that iterators can yield,
     takes in modifications to the yielded vector and then writes them back out
     to the raw address when this goes out of scope*/
  record vectorRef: writeSerializable {
    type vectorType;
    param aligned: bool;
    var vec: vectorType;
    var address: c_ptr(vectorType.eltType);
    forwarding vec;

    proc init(type vectorType, param aligned: bool = false) {
      this.vectorType = vectorType;
      this.aligned = aligned;
    }
    proc init(vec: ?vecType, address: c_ptr(vecType.eltType), param aligned: bool = false) {
      this.vectorType = vecType;
      this.aligned = aligned;
      this.vec = vec;
      this.address = address;
    }
    proc init(type vectorType, address: c_ptr(vectorType.eltType), param aligned: bool = false) {
      this.vectorType = vectorType;
      this.vec = vectorType.load(address, 0, aligned=aligned);
      this.address = address;
    }
    proc deinit() {
      this.commitChanges();
    }
    inline proc commitChanges() {
      this.vec.store(this.address, 0, aligned=this.aligned);
    }

    proc serialize(writer, ref serializer) throws {
      writer.write(vec);
    }

    //
    // Forwarding doesn't work for operators, so we need to manually implement them
    //
    operator+(lhs: ?lhsType, rhs: ?rhsType)
      where returnTypeForOperatorTypes(lhsType, rhsType) != nothing do
      return getValue(lhs) + getValue(rhs);
    operator+=(ref lhs: vectorRef(?), rhs: ?rhsType)
      where _validEqOperatorTypes(lhs.type, rhsType) do
      getRef(lhs) += getValue(rhs);

    operator-(lhs: ?lhsType, rhs: ?rhsType)
      where returnTypeForOperatorTypes(lhsType, rhsType) != nothing do
      return getValue(lhs) + getValue(rhs);
    operator-=(ref lhs: vectorRef(?), rhs: ?rhsType)
      where _validEqOperatorTypes(lhs.type, rhsType) do
      getRef(lhs) -= getValue(rhs);

    operator*(lhs: ?lhsType, rhs: ?rhsType)
      where returnTypeForOperatorTypes(lhsType, rhsType) != nothing do
      return getValue(lhs) * getValue(rhs);
    operator*=(ref lhs: vectorRef(?), rhs: ?rhsType)
      where _validEqOperatorTypes(lhs.type, rhsType) do
      getRef(lhs) *= getValue(rhs);

    operator/(lhs: ?lhsType, rhs: ?rhsType)
      where returnTypeForOperatorTypes(lhsType, rhsType) != nothing do
      return getValue(lhs) + getValue(rhs);
    operator/=(ref lhs: vectorRef(?), rhs: ?rhsType)
      where _validEqOperatorTypes(lhs.type, rhsType) do
      getRef(lhs) /= getValue(rhs);

    // more strict checking is technically needed to do assignment
    // this is done by the vector type already
    // TODO: we also need init= from vector, init= from vectorRef, and init= from tuple
    // operator=(ref lhs: ?lhsType, rhs: ?rhsType)
    //   where isVectorType(lhsType) &&
    //        (isVectorType(rhsType) || isHomogeneousTupleType(rhsType)) do
    //   getRef(lhs) = getValue(rhs);
  }
  private proc isVectorType(type T) param: bool do return isSubtype(T, vector) || isSubtype(T, vectorRef);
  private proc getEltType(type T) type where isSubtype(T, vector) do return T.eltType;
  private proc getEltType(type T) type where isSubtype(T, vectorRef) do return T.vectorType.eltType;
  private proc getNumElts(type T) param: int where isSubtype(T, vector) do return T.numElts;
  private proc getNumElts(type T) param: int where isSubtype(T, vectorRef) do return T.vectorType.numElts;

  private inline proc getValue(x: vector(?)): x.type do return x;
  private inline proc getValue(x: vectorRef(?)): x.vectorType do return x.vec;
  private inline proc getValue(x: ?t): t do return x;
  private inline proc getRef(ref x: vector(?)) ref: x.type do return x;
  private inline proc getRef(ref x: vectorRef(?)) ref: x.vectorType do return x.vec;
  private inline proc getRef(ref x: ?t) ref: t do return x;

  private proc returnTypeForOperatorTypes(type lhsType, type rhsType) type {
    // one of the types can be scalar, but not both
    if !isVectorType(lhsType) && isVectorType(rhsType) {
      return vector(getEltType(rhsType), getNumElts(rhsType));
    } else if isVectorType(lhsType) && !isVectorType(rhsType) {
      return vector(getEltType(lhsType), getNumElts(lhsType));
    } else if isVectorType(lhsType) && isVectorType(rhsType) {
      // must be same eltType/numElt
      if getEltType(lhsType) == getEltType(rhsType) &&
         getNumElts(lhsType) == getNumElts(rhsType) {
        return vector(getEltType(lhsType), getNumElts(lhsType));
      } else return nothing;
    } else return nothing;
  }
  // must be a valid operator and the lhs must be a vector
  proc validEqOperatorTypes(type lhsType, type rhsType) param: bool {
    if returnTypeForOperatorTypes(lhsType, rhsType) == nothing {
      return false;
    }
    if !isVectorType(lhsType) {
      return false;
    }
    return true;
  }

}
