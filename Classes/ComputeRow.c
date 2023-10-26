// ComputeRow.c
#include "ComputeRow.h"

// Note: This .c is used on the NSOperation version, ComputeRow.clx in OpenCL
// the remainder of this file and Resources/ComputeRow.clx are identical.

#ifndef JULIA_FLOATTYPE
#define JULIA_FLOATTYPE float
#endif

#ifndef JULIA_GLOBAL
#define JULIA_GLOBAL global
#endif

#ifndef JULIA_KERNEL
#define JULIA_KERNEL kernel
#endif

#ifndef JULIA_OPENCL
#define JULIA_OPENCL 1
#endif

// JULIA_FLOATTYPE defaults to double from the .h file.

JULIA_KERNEL void ComputeRow(
  int jx,
  int numIterations,
  int width,
  int height,
  JULIA_GLOBAL unsigned char *pixels,
  int rowBytes,
  JULIA_FLOATTYPE scale,
  JULIA_FLOATTYPE offsetX,
  JULIA_FLOATTYPE offsetY,
  JULIA_FLOATTYPE a,
  JULIA_FLOATTYPE b) {

  int j = jx;
#if JULIA_OPENCL
  j = get_global_id(0);
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
