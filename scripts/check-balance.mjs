// 没有 Swift 编译器时的最低限度自查：逐文件检查 () [] {} 是否配平（忽略字符串和注释）。
// 用法：node scripts/check-balance.mjs
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "PlayerX");
const PAIRS = { ")": "(", "]": "[", "}": "{" };

function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    return entry.isDirectory() ? walk(full) : full.endsWith(".swift") ? [full] : [];
  });
}

/** 去掉注释和字符串内容，保留换行，行号才对得上 */
function strip(src) {
  let out = "";
  let i = 0;
  const n = src.length;
  while (i < n) {
    const c = src[i];
    const d = src[i + 1];
    if (c === "/" && d === "/") {
      while (i < n && src[i] !== "\n") i++;
    } else if (c === "/" && d === "*") {
      let depth = 1;
      i += 2;
      while (i < n && depth > 0) {
        if (src[i] === "/" && src[i + 1] === "*") { depth++; i += 2; }
        else if (src[i] === "*" && src[i + 1] === "/") { depth--; i += 2; }
        else { if (src[i] === "\n") out += "\n"; i++; }
      }
    } else if (c === '"' || (c === "#" && /^#+"/.test(src.slice(i, i + 12)))) {
      // 字符串：支持 #"…"# 原始字符串与 """ 多行字符串，插值 \( … ) 里的括号也要配平，这里整体跳过
      const hashes = c === "#" ? src.slice(i).match(/^#+/)[0].length : 0;
      i += hashes;
      const triple = src.startsWith('"""', i);
      i += triple ? 3 : 1;
      const close = '"'.repeat(triple ? 3 : 1) + "#".repeat(hashes);
      while (i < n && !src.startsWith(close, i)) {
        if (src[i] === "\\" && hashes === 0) { i += 2; continue; }
        if (src[i] === "\n") out += "\n";
        i++;
      }
      i += close.length;
      out += '""';
    } else {
      out += c;
      i++;
    }
  }
  return out;
}

let bad = 0;
for (const file of walk(root)) {
  const text = strip(fs.readFileSync(file, "utf8"));
  const stack = [];
  let line = 1;
  let problem = "";
  for (const ch of text) {
    if (ch === "\n") line++;
    else if ("([{".includes(ch)) stack.push([ch, line]);
    else if (PAIRS[ch]) {
      const top = stack.pop();
      if (!top || top[0] !== PAIRS[ch]) { problem = `第 ${line} 行多出了 ${ch}`; break; }
    }
  }
  if (!problem && stack.length) problem = `第 ${stack[stack.length - 1][1]} 行的 ${stack[stack.length - 1][0]} 没有闭合`;
  if (problem) { bad++; console.log(`✗ ${path.relative(root, file)}：${problem}`); }
}
const total = walk(root).length;
console.log(bad ? `\n${bad} 个文件括号不配平` : `✓ ${total} 个 Swift 文件括号全部配平`);
process.exit(bad ? 1 : 0);
