/* Runtime probe for wgpu swapchain readback bench (studio-ux-21). */
#include <stdio.h>
#include "li_rt.h"

#define LI_RT_LIG_SWAPCHAIN_STATUS_BLOCKED 0
#define LI_RT_LIG_SWAPCHAIN_STATUS_PASS 1
#define LI_RT_LIG_PIXEL_SOURCE_WGPU_SWAPCHAIN 5

int main(void) {
  const int32_t env_active = li_rt_lig_wgpu_swapchain_active();
  const int32_t status = li_rt_lig_wgpu_swapchain_readback_status();
  const int32_t pixels = li_rt_lig_wgpu_swapchain_readback_run(1280, 720);
  const char* bench_status = "blocked_runner";
  if (status == LI_RT_LIG_SWAPCHAIN_STATUS_PASS && pixels > 0) {
    bench_status = "swapchain_pass";
  }
  printf(
      "{\"env_active\":%d,\"readback_status\":%d,\"pixels_sampled\":%d,"
      "\"native_pixels\":%d,\"native_pixel_source\":%d,\"bench_status\":\"%s\"}\n",
      (int)env_active, (int)status, (int)pixels, (int)li_rt_lig_host_native_pixels(),
      (int)li_rt_lig_host_native_pixel_source(), bench_status);
  return 0;
}
