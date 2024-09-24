use IO;
use SIMD;
use PrecisionSerializer;

config const precision = 2;
config const padding = 5;
var vecOut = stdout.withSerializer(new precisionSerializer(precision=precision, padding=padding));

config param testName: string = "all";


proc sqrtTest(type eltType, param numElts: int) {
  writeln("sqrtTest for ", eltType:string, " ", numElts);

  var a: vector(eltType, numElts);
  var v: numElts*eltType;
  for param i in 0..#a.numElts {
    v(i) = (i+1)*(i+1);
  }
  vecOut.writeln("  v: ", v);
  a.set(v);

  vecOut.writeln("  a: ", v);
  a = sqrt(a);
  vecOut.writeln("  sqrt(a): ", a);

  a = rsqrt(a*a);
  vecOut.writeln("  rsqrt(a): ", a);
}

proc arrTest(type eltType, param numElts: int) {
  writeln("arrTest for ", eltType:string, " ", numElts);

  var arr: [1..#(numElts*4)] eltType;
  arr = [i in arr.domain] i:eltType;

  vecOut.writeln("  arr: ", arr);

  var a: vector(eltType, numElts);
  for i in arr.domain by numElts {
    a.load(arr, i);
    vecOut.writeln("  vec at ", i, ": ", a);

    var b = new a.type();
    b = a+a;
    b.store(arr, i);
  }
  vecOut.writeln("  arr: ", arr);

  param stride = 2;
  var strided: [1.. by stride #(numElts*4)] eltType;
  strided = [i in strided.domain] i:eltType;

  vecOut.writeln("  strided: ", strided);
  for i in strided.domain by numElts {
    a.load(strided, i);
    vecOut.writeln("  vec at ", i, ": ", a);

    var b = new a.type();
    b = a+a;
    b.store(strided, i);
  }

  vecOut.writeln("  strided: ", strided);
}
proc initTest(type eltType, param numElts: int) {
  writeln("initTest for ", eltType:string, " ", numElts);

  var a = new vector(eltType, numElts);
  for param i in 0..#numElts {
    a.set(i, (i+1):eltType);
  }
  vecOut.writeln("  set individual: ", a);
  a.set(0);
  vecOut.writeln("  reset: ", a);

  var tup: numElts*eltType;
  for param i in 0..#numElts {
    tup(i) = (i+1):eltType;
  }
  a.set(tup);
  vecOut.writeln("  set tuple: ", a);

  var res = a:(numElts*eltType);
  vecOut.writeln("  get tuple (", res.type:string, "): ", res);

}

proc shuffleTest(type eltType, param numElts: int) {
  writeln("shuffleTest for ", eltType:string, " ", numElts);

  var a, other = new vector(eltType, numElts);
  for param i in 0..#numElts {
    a.set(i, (i+1):eltType);
    other.set(i, numElts + (i+1));
  }
  vecOut.writeln("  a                : ", a);
  vecOut.writeln("  other            : ", other);
  vecOut.writeln("  -----------------");

  {
    var b = swapPairs(a);
    vecOut.writeln("  swapPairs        : ", b);
  }
  {
    var b = swapLowHigh(a);
    vecOut.writeln("  swapLowHigh      : ", b);
  }
  {
    var b = reverse(a);
    vecOut.writeln("  reverse          : ", b);
  }
  {
    var b = rotateLeft(a);
    vecOut.writeln("  rotateLeft       : ", b);
  }
  {
    var b = rotateRight(a);
    vecOut.writeln("  rotateRight      : ", b);
  }
  {
    var b = interleaveLower(a, other);
    vecOut.writeln("  interleaveLower  : ", b);
  }
  {
    var b = interleaveUpper(a, other);
    vecOut.writeln("  interleaveUpper  : ", b);
  }
  {
    var b = deinterleaveLower(a, other);
    vecOut.writeln("  deinterleaveLower: ", b);
  }
  {
    var b = deinterleaveUpper(a, other);
    vecOut.writeln("  deinterleaveUpper: ", b);
  }
  {
    var b = blendLowHigh(a, other);
    vecOut.writeln("  blendLowHigh     : ", b);
  }
}

proc mathTest(type eltType, param numElts: int) {
  writeln("mathTest for ", eltType:string, " ", numElts);

  var a, b = new vector(eltType, numElts);
  for param i in 0..#numElts {
    a.set(i, (i+1):eltType);
    b.set(i, numElts + (i+1));
  }
  vecOut.writeln("  a: ", a);
  vecOut.writeln("  b: ", b);
  vecOut.writeln("  -----------------");

  {
    var c = a + b;
    vecOut.writeln("  a + b: ", c);
  }
  {
    var c = a - b;
    vecOut.writeln("  a - b: ", c);
  }
  {
    var c = a * b;
    vecOut.writeln("  a * b: ", c);
  }
  {
    var c = a / b;
    vecOut.writeln("  a / b: ", c);
  }
  {
    var c = pairwiseAdd(a, b);
    vecOut.writeln("  pairAdd(a, b): ", c);
  }
}

proc compute(ref points: [] real(32)) {
  for p in points.domain by 3 {
    // take each point, normalize it, and store it back
    var point = vector(real(32), 3).load(points, p);
    var radius = sqrt(point*point);
    point = point / radius;
    point.store(points, p);
  }
}

proc main() {

  param test_arrTest = testName == "all" || testName == "arrTest";
  param test_initTest = testName == "all" || testName == "initTest";
  param test_mathTest = testName == "all" || testName == "mathTest";
  param test_sqrtTest = testName == "all" || testName == "sqrtTest";
  param test_shuffleTest = testName == "all" || testName == "shuffleTest";

  if test_arrTest {
    arrTest(real(32), 4);
    arrTest(real(64), 2);
    arrTest(real(32), 8);
    arrTest(real(64), 4);
  }
  if test_initTest {
    initTest(real(32), 4);
    initTest(real(64), 2);
    initTest(real(32), 8);
    initTest(real(64), 4);
  }
  if test_mathTest {
    mathTest(real(32), 4);
    mathTest(real(64), 2);
    mathTest(real(32), 8);
    mathTest(real(64), 4);
  }
  if test_sqrtTest {
    sqrtTest(real(32), 4);
    sqrtTest(real(64), 2);
    sqrtTest(real(32), 8);
    sqrtTest(real(64), 4);
  }
  if test_shuffleTest {
    shuffleTest(real(32), 4);
    shuffleTest(real(64), 2);
    shuffleTest(real(32), 8);
    shuffleTest(real(64), 4);
  }

}
