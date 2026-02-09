/**
 * Pre-build check: ensures all .md files in content/ have 'created:' frontmatter.
 * On WSL2, birthtimeMs returns 0, causing Quartz to emit invalid date warnings.
 * This script adds created: YYYY-MM-DD (from filename or mtime) to files missing it.
 */
import { readdirSync, readFileSync, writeFileSync, statSync } from "fs"
import { join, basename } from "path"

const contentDir = process.argv[2] || "content"
const dateRe = /(\d{4}-\d{2}-\d{2})/

function walk(dir) {
  const results = []
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name)
    if (entry.isDirectory()) results.push(...walk(full))
    else if (entry.name.endsWith(".md")) results.push(full)
  }
  return results
}

let fixed = 0
for (const file of walk(contentDir)) {
  const content = readFileSync(file, "utf8")
  if (/^---\n/.test(content) && /^created:/m.test(content.split("\n---")[0])) continue

  const match = basename(file).match(dateRe)
  const date = match ? match[1] : statSync(file).mtime.toISOString().slice(0, 10)

  const patched = content.startsWith("---\n")
    ? content.replace("---\n", `---\ncreated: ${date}\n`)
    : `---\ncreated: ${date}\n---\n${content}`

  writeFileSync(file, patched)
  console.log(`  +created: ${date} → ${file}`)
  fixed++
}

console.log(fixed ? `\n${fixed} file(s) fixed.` : "All files have created: frontmatter.")
