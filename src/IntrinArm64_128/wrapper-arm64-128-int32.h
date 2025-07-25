#ifndef WRAPPER_ARM64_128_INT32_H_
#define WRAPPER_ARM64_128_INT32_H_

#include <arm_neon.h>

#define LANES(V) V(0) V(1) V(2) V(3)

#define GET_LANE_32x4i(LANE) \
  static inline int32_t get_lane_32x4i##LANE(int32x4_t v) { \
    return vgetq_lane_s32(v, LANE); \
  }
LANES(GET_LANE_32x4i)
#undef GET_LANE_32x4i

#define SET_LANE_32x4i(LANE) \
  static inline int32x4_t set_lane_32x4i##LANE(int32x4_t v, int32_t x) { \
    return vsetq_lane_s32(x, v, LANE); \
  }
LANES(SET_LANE_32x4i)
#undef SET_LANE_32x4i

static inline int32x4_t load32x4i(const int32_t* x) { return vld1q_s32(x); }
static inline void store32x4i(int32_t* x, int32x4_t y) { vst1q_s32(x, y); }

#define EXTRACT_VECTOR_32x4i(LANE) \
  static inline int32x4_t extractVector32x4i##LANE(int32x4_t x, int32x4_t y) { \
    return vextq_s32(x, y, LANE); \
  }
LANES(EXTRACT_VECTOR_32x4i)
#undef EXTRACT_VECTOR_32x4i

#undef LANES

static inline int is_all_zeros_32x4i(int32x4_t x) {
  return vminvq_s32(x) == 0;
}

static inline int movemask_32x4i(int32x4_t x) {
  uint32x4_t input = vreinterpretq_u32_s32(x);
  uint64x2_t paired32 = vreinterpretq_u64_u32(vshrq_n_u32(input, 31));
  uint8x16_t paired64 = vreinterpretq_u8_u64(vsraq_n_u64(paired32, paired32, 28));
  return vgetq_lane_u8(paired64, 0) | ((int) vgetq_lane_u8(paired64, 8) << 8);
}

#endif
