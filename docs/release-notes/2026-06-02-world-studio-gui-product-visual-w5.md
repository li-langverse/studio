# World Studio GUI product-visual W5 (acceptance)

- **Todo:** `wsv-w5-acceptance-screenshots`
- **WPs:** WP-UX-14 (honest native pixels), WP-UX-05 (seven vertical profiles)
- **Changes:** `studio_vertical_capture_ppm_auto` + headless PPM writer in `studio` package; gates capture all seven verticals plus `product-visual-game-1280x720.png`; completion gate requires full acceptance PNG set.
- **Smokes:** `li-tests/smoke/studio_product_visual_w5_acceptance.li` (`li_std_studio_version` 49).
- **Screenshots:** `docs/demo/media/native-verticals/png/product-visual-*.png` manifest in `data/world-studio-gui-product-visual-loop/latest-screenshots.json`.
