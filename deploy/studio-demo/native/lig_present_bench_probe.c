/* Runtime probe for bench-studio-viewport-perf — paint blit + surface_ok (no SDL required). */
#include <stdio.h>
#include "li_rt.h"

#define LI_RT_LIG_PIXEL_SOURCE_PAINT_BLIT 2

int main(void) {
  const int32_t host = li_rt_lig_host_present_active();
  int32_t blit_ok = 0;
  if (host) {
    blit_ok = li_rt_lig_present_blit_rgba8(1280, 720, 1, 42, 21);
  }
  printf(
      "{\"host_present_active\":%d,\"paint_blit_ok\":%d,\"surface_ok\":%d,"
      "\"native_pixels\":%d,\"native_pixel_source\":%d}\n",
      (int)host, (int)blit_ok, (int)li_rt_lig_present_surface_ok(),
      (int)li_rt_lig_host_native_pixels(), (int)li_rt_lig_host_native_pixel_source());
  return 0;
}
