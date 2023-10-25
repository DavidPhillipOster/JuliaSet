// ComputeRow.h

// BEGIN #defines to allow the same code to compule as C or OpenCL.

#ifndef JULIA_FLOATTYPE
#define JULIA_FLOATTYPE double
#endif

#ifndef JULIA_GLOBAL
#define JULIA_GLOBAL /* empty */
#endif

#ifndef JULIA_KERNEL
#define JULIA_KERNEL /* empty */
#endif

// END #defines to allow the same code to compule as C or OpenCL.


// Do the actual work of computing one row of the Julia Set
void ComputeRow(
  int j, int numIterations,
  int width, int height,
  unsigned char *pixels, int rowBytes,
  JULIA_FLOATTYPE scale,
  JULIA_FLOATTYPE offsetX, JULIA_FLOATTYPE offsetY,
  JULIA_FLOATTYPE a, JULIA_FLOATTYPE b);
