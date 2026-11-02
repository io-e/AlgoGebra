# F-1 mise warning (GROK_V1)

launch.sh warns when the mise-pinned Java is below GGB_JAVA_MIN and discovery falls through (was silent).
Suite 17: **15/0/0** (adds L-14 mise Java 25, L-15 mise pin 21 -> warning + PATH fallback; fake mise shim, no real mise needed). Suite 18 regression (PR #11 image): see tap.
