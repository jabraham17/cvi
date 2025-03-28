#ifndef WRAPPER_X86_256_INT32_H_
#define WRAPPER_X86_256_INT32_H_

#include <x86intrin.h>

static inline __m256i swapPairs_256epi32(__m256i x) {
  return _mm256_shuffle_epi32(x, 0b10110001);
}
static inline __m256i swapLowHigh_256epi32(__m256i x) {
  return _mm256_permute2f128_si256(x, x, 1);
}
static inline __m256i reverse_256epi32(__m256i x) {
  __m256i mask = _mm256_set_epi32(0, 1, 2, 3, 4, 5, 6, 7);
  return _mm256_permutevar8x32_epi32(x, mask);
}
static inline __m256i rotateLeft_256epi32(__m256i x) {
  __m256i mask = _mm256_set_epi32(0, 7, 6, 5, 4, 3, 2, 1);
  return _mm256_permutevar8x32_epi32(x, mask);
}
static inline __m256i rotateRight_256epi32(__m256i x) {
  __m256i mask = _mm256_set_epi32(6, 5, 4, 3, 2, 1, 0, 7);
  return _mm256_permutevar8x32_epi32(x, mask);
}

static inline __m256i interleaveLower_256epi32(__m256i x, __m256i y) {
  __m256i t0 = _mm256_unpacklo_epi32(x, y);
  __m256i t1 = _mm256_unpackhi_epi32(x, y);
  return _mm256_permute2f128_si256(t0, t1, 0x20);
}
static inline __m256i interleaveUpper_256epi32(__m256i x, __m256i y) {
  __m256i t0 = _mm256_unpacklo_epi32(x, y);
  __m256i t1 = _mm256_unpackhi_epi32(x, y);
  return _mm256_permute2f128_si256(t0, t1, 0x31);
}
static inline __m256i deinterleaveLower_256epi32(__m256i x, __m256i y) {
  __m256i mask = _mm256_set_epi32(14, 12, 10, 8, 6, 4, 2, 0);
  __m256i t0 = _mm256_permutevar8x32_epi32(x, mask);
  __m256i t1 = _mm256_permutevar8x32_epi32(y, mask);
  return _mm256_blend_epi32(t0, t1, 0xF0);
}
static inline __m256i deinterleaveUpper_256epi32(__m256i x, __m256i y) {
  __m256i mask = _mm256_set_epi32(15, 13, 11, 9, 7, 5, 3, 1);
  __m256i t0 = _mm256_permutevar8x32_epi32(x, mask);
  __m256i t1 = _mm256_permutevar8x32_epi32(y, mask);
  return _mm256_blend_epi32(t0, t1, 0xF0);
}

static inline __m256i blendLowHigh_256epi32(__m256i x, __m256i y) {
  return _mm256_blend_epi32(x, y, 0xf0);
}


static inline __m256i hadd_256epi32(__m256i x, __m256i y) {
  __m256i t0 = _mm256_hadd_epi32(x, y);
  return _mm256_shuffle_epi32(t0, 0b11011000);
}

#endif
