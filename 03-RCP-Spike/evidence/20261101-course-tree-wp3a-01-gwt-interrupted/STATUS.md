# WP3a-01 Windows GWT Build — Interrupted

**Status:** INTERRUPTED — not a pass and not a failure diagnosis  
**Run date:** 2026-11-01  
**Source pin:** `375db7faf5407390bb322165f2414415da8faeda`  
**Platform:** Windows x86_64  
**Java:** JDK 21 (patch version not recorded in the console log)  
**Gradle:** 9.4.1  
**Command:** `gradlew.bat -p source/web :web:gwtCompile :web:compileSass --no-daemon`  
**Exit code:** 1 after Ctrl+C; the run was deliberately stopped before completion.

The build reached `:web:gwtCompile` and logged `Compiling module org.geogebra.web.SuperWeb`. No GWT completion or Sass task result was recorded. Therefore this run provides no evidence that WP3a-01 passes or fails.

No course-tree implementation was created or changed in this run. Generated Gradle outputs were not copied into this evidence folder.

**Log:** `wp3a-01-gwt-windows.log`  
**SHA-256:** `b433420571a051cdd6d0d7d7c83cc806c3d256f156e945a36100889f62b18538`
