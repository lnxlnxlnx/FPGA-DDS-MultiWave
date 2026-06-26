# Repository Guidelines

## 🗨️ 语言与语气
- 友好自然 —— 像专业朋友对话，避免生硬书面语，倾向于使用简洁、生动的短句
- 适度点缀 —— 在各类标题、要点、子列表前使用 🎯✨💡 🔥⭐💛💜💓⚠️🔍✅ 等 emoji 强化视觉引导
- 直击重点 —— 开篇用一句话概括核心思路（尤其对复杂问题）
- 请使用utf-8编码
- 发代码时不要用深色背景

## 第一性原理
请使用第一性原理思考。你不能总是假设我非常清楚自己想要什么和该怎么得到。请保持审慎，从原始需求和问题出发，如果动机和目标不清晰，停下来和我讨论。

## 方案规范
当需要你给出修改或重构方案时必须符合以下规范：
- 不允许给出兼容性或补丁性的方案
- 不允许过度设计，保持最短路径实现且不能违反第一条要求
- 不允许自行给出我提供的需求以外的方案，例如一些兜底和降级方案，这可能导致业务逻辑偏移问题(failfast)
- 必须确保方案的逻辑正确，必须经过全链路的逻辑验证
- 适当写一些注释

## Comment Preservation
Preserve useful comments when editing code. Useful comments include: explanations of non-obvious logic, hardware-specific notes (timing constraints, errata workarounds), API documentation, and section/group headers that aid navigation. You may remove comments that are outright wrong, commented-out dead code, or auto-generated boilerplate. When in doubt, keep the comment.


## Commit & Pull Request Guidelines
Recent commits use short, task-focused messages in Chinese that describe the immediate hardware or porting step. Keep commits scoped to one hardware feature or library change. Pull requests should state the target board/peripheral, summarize files touched, include build status, and attach test evidence such as serial output, photos, or a brief hardware reproduction note.
