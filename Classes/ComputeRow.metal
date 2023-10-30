//  ComputeRow.metal
//  JuliaSet
//
//  Created by david on 10/28/23.
// Metal version of JuliaSet : NOT YET
//

#include <metal_stdlib>
using namespace metal;

#ifndef JULIA_FLOATPARAMTYPE
#define JULIA_FLOATPARAMTYPE device const float&
#endif

#ifndef JULIA_FLOATTYPE
#define JULIA_FLOATTYPE float
#endif

#ifndef JULIA_INTTYPE
#define JULIA_INTTYPE device const int&
#endif

#ifndef JULIA_GLOBAL
#define JULIA_GLOBAL device
#endif

#ifndef JULIA_KERNEL
#define JULIA_KERNEL kernel
#endif

#ifndef JULIA_METAL
#define JULIA_METAL 1
#endif

JULIA_KERNEL void ComputeRow(
  JULIA_INTTYPE jx,
  JULIA_INTTYPE numIterations,
  JULIA_INTTYPE width, 
  JULIA_INTTYPE height,
  JULIA_GLOBAL unsigned char *pixels,
  JULIA_INTTYPE rowBytes,
  JULIA_FLOATPARAMTYPE scale,
  JULIA_FLOATPARAMTYPE offsetX,
  JULIA_FLOATPARAMTYPE offsetY,
  JULIA_FLOATPARAMTYPE a,
  JULIA_FLOATPARAMTYPE b,
  uint index [[thread_position_in_grid]]) {

  int j = jx;
#if JULIA_METAL
  j = index;
#endif
  if (j < height) {
    JULIA_GLOBAL unsigned int *p = (JULIA_GLOBAL unsigned int *)(pixels + j*rowBytes);
    for (int i = 0; i < width; ++i) {
      JULIA_FLOATTYPE x = i*scale + offsetX;
      JULIA_FLOATTYPE y = j*scale + offsetY;
      int color = 0;
      int n = 0;
      // This for() loop is the actual Julia set equation.
      for (; n < numIterations && x*x + y*y < 4; ++n) {
        JULIA_FLOATTYPE newX = x*x - y*y + a;
        y = 2*x*y + b;
        x = newX;
      }
      color = n << 12;
      p[i] = color;
    }
  }
}
