# Suite 09 hygiene (ORDER-03/04 strict, FONT-01 note), Debian, GROK_V1
Branch grok/hygiene-suite09-order-font off tip 6d62ef4. Image: /workspace/AlgoGebra/image-prod-2f24a7e (2f24a7e..6d62ef4 changes only evidence + Verify_Issues_27_28 test script; no build inputs -> no rebuild). Xvfb, xdotool.
Result: **17/3/0** (was 19/1/0 with lenient ORDER-03/04).
- D04-FOCUS-01 FAIL (#33, unchanged): 3D bar E=(1,1,1) lost=True, retry also lost, changed=False.
- D04-ORDER-03 FAIL (new, strict): 3D bar h(x)=x^2 first burst lost=True; retry after 2nd click worked (changed=True). Same symptom as #33: first click on the 3D SWT_AWT input bar does not give the AWT field focus.
- D04-ORDER-04 FAIL (new, strict): 2D bar k(x)=x+1 right after a *successful* 3D input: first burst lost=True, retry worked. Session 1 FOCUS-02 (2D after a *failed* 3D input) had lost=False: focus never actually moved into the 3D frame there. So loss occurs whenever AWT focus has to move between the two embedded SWT_AWT frames, in either direction -> same root cause as #33 (embedded frame activation on first click), but the 3D->2D direction.
- PR #48 (Codex, closes #33) installs a focus bridge only on App3D's algebra text field; it may not cover ORDER-04 (2D field). Suite 09 on a #48 image should be checked against all three cases.
- FONT-01 PASS: fragment org.geogebra.plus.renderer.resources_0.1.0.jar 46 .ttf; renderer jar 0 .ttf by design.
