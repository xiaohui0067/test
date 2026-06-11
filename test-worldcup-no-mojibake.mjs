import assert from "node:assert/strict";
import fs from "node:fs";

const files = [
  "worldcup2026-dashboard.html",
  "worldcup2026-live-data.json",
  "worldcup2026-live-data.js"
];

const mojibakeFragments = ["涓", "鐨", "鍞", "鏉", "锛", "鎴", "鍐", "绔", "僵", "鍙", "浣", "楂", "绋", "鍧", "鑳", "骞", "闃", "鐟", "瑗", "?/"];

for (const file of files) {
  const text = fs.readFileSync(file, "utf8");
  const found = mojibakeFragments.filter(fragment => text.includes(fragment));
  assert.deepEqual(found, [], `${file} should not contain common mojibake fragments`);
}

console.log("worldcup mojibake check ok");
