/* Headless AIMD hero builds link studio/gui without full ui_snapshot RT — return safe no-ops. */
#include <stdint.h>

int32_t li_rt_ui_snapshot_tag_from_id(const char* id) {
  (void)id;
  return 0;
}

const char* li_rt_ui_snapshot_id_name(int32_t tag) {
  (void)tag;
  return "";
}
