#ifndef WRAPPER_ARM64_128_REAL64_H_
#define WRAPPER_ARM64_128_REAL64_H_

#include <arm_neon.h>

#define LANES(V) V(0) V(1)

#define GET_LANE_64x2r(LANE) \
  static inline float64_t get_lane_64x2r##LANE(float64x2_t v) { \
    return vgetq_lane_f64(v, LANE); \
  }
LANES(GET_LANE_64x2r)
#undef GET_LANE_64x2r

#define SET_LANE_64x2r(LANE) \
  static inline float64x2_t set_lane_64x2r##LANE(float64x2_t v, float64_t x) { \
    return vsetq_lane_f64(x, v, LANE); \
  }
LANES(SET_LANE_64x2r)
#undef SET_LANE_64x2r

static inline float64x2_t load64x2r(const float64_t* x) { return vld1q_f64(x); }
static inline void store64x2r(float64_t* x, float64x2_t y) { vst1q_f64(x, y); }

#define EXTRACT_VECTOR_64x2r(LANE) \
  static inline float64x2_t extractVector64x2r##LANE(float64x2_t x, float64x2_t y) { \
    return vextq_f64(x, y, LANE); \
  }
LANES(EXTRACT_VECTOR_64x2r)
#undef EXTRACT_VECTOR_64x2r

#undef LANES

#endif
