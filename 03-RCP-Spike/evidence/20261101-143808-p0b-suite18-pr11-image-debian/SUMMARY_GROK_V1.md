# Suite 18 follow-up (GROK_V1)

LC-18 fixed (host jar lives in image host/build/, Start-Process arg quoting, log marker `Course loaded: ... (5 chapters`).

| Image | PASS | FAIL | SKIP |
|---|---|---|---|
| PR #11 image (built on Debian from tip+#11+#9 scratch merge, `image-pr11`) | 18 | 0 | 1 |
| existing r8 Linux image (no course package) | 17 | 0 | 2 |

LC-19 still SKIP (needs a T-27 OPEN path through the product log).
