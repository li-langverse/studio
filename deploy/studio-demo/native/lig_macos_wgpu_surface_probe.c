/* macOS aarch64 wgpu/Metal surface probe (wsg-w5-macos-wgpu, PH-HW WP3). */
#include <stdio.h>
#include "li_rt.h"

#define LI_RT_LIG_BACKEND_METAL 3
#define LI_RT_LIG_SWAPCHAIN_STATUS_PASS 1
#define LI_RT_LIG_PIXEL_SOURCE_WGPU_SWAPCHAIN 5

int main(void) {
  const int32_t host = li_rt_lig_host_present_active();
  const int32_t swap_env = li_rt_lig_wgpu_swapchain_active();
  const int32_t status = li_rt_lig_wgpu_swapchain_readback_status();
  const int32_t pixels = li_rt_lig_wgpu_swapchain_readback_run(1280, 720);
  const int32_t surface_ok = li_rt_lig_present_surface_ok();
  const int32_t device = li_rt_lig_device_kind();
  const char* platform = "unknown";
#if defined(__APPLE__)
  platform = "aarch64-apple-darwin";
#endif
  const char* bench_status = "blocked_runner";
  if (status == LI_RT_LIG_SWAPCHAIN_STATUS_PASS && pixels > 0 && surface_ok) {
    bench_status = "swapchain_pass";
  }
  printf(
      "{\"platform\":\"%s\",\"host_present\":%d,\"swapchain_env\":%d,"
      "\"readback_status\":%d,\"pixels_sampled\":%d,\"surface_ok\":%d,"
      "\"device_kind\":%d,\"metal_backend\":%d,\"native_pixels\":%d,"
      "\"native_pixel_source\":%d,\"bench_status\":\"%s\"}\n",
      platform, (int)host, (int)swap_env, (int)status, (int)pixels, (int)surface_ok,
      (int)device, (int)(device == LI_RT_LIG_BACKEND_METAL), (int)li_rt_lig_host_native_pixels(),
      (int)li_rt_lig_host_native_pixel_source(), bench_status);
  return 0;
}
