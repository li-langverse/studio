#!/usr/bin/env node
/**
 * Headless PNG capture for studio-demo HTML (Chrome hangs with --screenshot in some builds).
 * Usage: node scripts/capture-studio-demo-png.mjs [screenshots-dir]
 */
import { chromium } from "playwright";
import { readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const shotsDir =
  process.argv[2] ||
  path.join(
    path.dirname(fileURLToPath(import.meta.url)),
    "../.demo-cache/deploy/studio-demo/screenshots",
  );
const outDir = path.join(shotsDir, "png");
const chrome =
  process.env.CHROME ||
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

const files = (await readdir(shotsDir))
  .filter((f) => /^[0-9].*\.html$/.test(f))
  .sort();

if (!files.length) {
  console.error("capture-studio-demo-png: no HTML mocks in", shotsDir);
  process.exit(2);
}

const browser = await chromium.launch({
  executablePath: chrome,
  headless: true,
  args: ["--disable-gpu", "--hide-scrollbars"],
});
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });

for (const f of files) {
  const base = f.replace(/\.html$/, "");
  const url = new URL(path.join(shotsDir, f), "file://").href;
  await page.goto(url, { waitUntil: "load", timeout: 20000 });
  await page.screenshot({
    path: path.join(outDir, `${base}.png`),
    fullPage: false,
  });
  console.log(`  ${outDir}/${base}.png`);
}

await browser.close();
