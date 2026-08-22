---
description: Run a full performance and storage audit before and after major changes
---
## Steps
### 1. Capture engine metrics
- Run the project for at least 30 seconds of typical combat (attack, block, dodge, ability use).
- Report average FPS, minimum FPS, frame time (ms), draw calls, and video memory.

### 2. Capture storage
- Run `du -sh` on the project root and each top-level asset folder.
- Compare against the AGENTS.md budget and flag anything over.

### 3. Flag regressions
- Compare against the last entry in /docs/perf-log.md. If FPS dropped more than 10% or any storage category grew more than 500MB in one task, stop and report before continuing.

### 4. Append results
- Add a new dated row to /docs/perf-log.md.
