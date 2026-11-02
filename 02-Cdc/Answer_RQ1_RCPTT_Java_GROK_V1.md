# RQ-1 — RCPTT Java fallback on Debian (Grok comment, GROK_V1)

Owner already locked RQ-1 = **yes** (Questions_RCP_Testing_Owner_GROK_V1.md, `88eca94`). This note adds facts; it does not reopen the decision.

## Facts checked 2026-11-01
- Box (Debian 13 trixie): Temurin **21.0.13+9** and **25.0.5+8** both present under `/workspace/AlgoGebra/jdk/`; no system `java`, no mise, no `openjdk-21` apt candidate in the current apt cache. Xvfb/xvfb-run installed.
- RCPTT plans: 2.6.0 and 2.7.x state **AUT Java 17–22**; IDE needs Java 21+. 2.8.x are service releases (no newer AUT Java range published); 2.8.0 notes protected-member access from modules now needs `--add-opens` on the AUT VM. Latest release 2.8.2 (2026-10-04); 2.9.0 is nightly.
  - https://projects.eclipse.org/projects/technology.rcptt/releases/2.6.0/plan
  - https://projects.eclipse.org/projects/technology.rcptt/releases/2.7.1/plan
  - https://github.com/eclipse-rcptt/org.eclipse.rcptt/issues/258
  - https://eclipse.dev/rcptt/download/

## Recommendation
1. Treat Java 21 as the **default** RCPTT AUT JVM on Debian, not just a fallback: Java 25 is outside RCPTT's documented AUT range, so a Java 25 run is an experiment, not the baseline. Run the runner itself on Temurin 21 too.
2. Pin runner **2.8.2** (`rcptt.runner-2.8.2-linux.gtk.x86_64.zip`, ~160 MB) per RQ-3 hybrid; record sha256.
3. Every RCPTT evidence row records AUT JDK + runner version; product/SWTBot/launch.sh stay Java 25 (BUG-017 discovery must not pick 21 for the product).
4. Expect to pass the existing `--add-exports` set plus `--add-opens` for any module RCPTT instruments.
5. A Java 25 RCPTT run may be attempted once as an informative probe; failure there is not a product defect.
