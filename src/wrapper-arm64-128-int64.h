#ifndef WRAPPER_ARM64_128_INT64_H_
#define WRAPPER_ARM64_128_INT64_H_

#include <arm_neon.h>

#define LANES(V) V(0) V(1)

#define GET_LANE_64x2i(LANE) \
  static inline int64_t get_lane_64x2i##LANE(int64x2_t v) { \
    return vgetq_lane_s64(v, LANE); \
  }
LANES(GET_LANE_64x2i)
#undef GET_LANE_64x2i

#define SET_LANE_64x2i(LANE) \
  static inline int64x2_t set_lane_64x2i##LANE(int64x2_t v, int64_t x) { \
    return vsetq_lane_s64(x, v, LANE); \
  }
LANES(SET_LANE_64x2i)
#undef SET_LANE_64x2i

static inline int64x2_t load64x2i(const int64_t* x) { return vld1q_s64(x); }
static inline void store64x2i(int64_t* x, int64x2_t y) { vst1q_s64(x, y); }

#define EXTRACT_VECTOR_64x2i(LANE) \
  static inline int64x2_t extractVector64x2i##LANE(int64x2_t x, int64x2_t y) { \
    return vextq_s64(x, y, LANE); \
  }
LANES(EXTRACT_VECTOR_64x2i)
#undef EXTRACT_VECTOR_64x2i

#undef LANES

#endif
