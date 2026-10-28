# Task E — Existing Test Baseline

**Repository:** `D:\ALF_ZGit\G1_Geogebra_Migration`  
**Revision:** `375db7faf54` on `main`  
**Date:** 28 October 2026  
**Scope:** requested Gradle tasks `:common-jre:test` and `:desktop:test`. No source files changed.

## Commands run

The first attempt failed before Gradle started because neither `JAVA_HOME` nor `java` was set in the process environment. Re-ran with the installed Temurin JDK 21 as the Gradle launcher JDK:

```powershell
$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
.\gradlew.bat -p source/shared :common-jre:test --no-daemon --console=plain
```

```powershell
$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
.\gradlew.bat -p source/desktop :desktop:test --no-daemon --console=plain
```

Targeted rerun of the sole failure with an English JVM locale:

```powershell
$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
$env:JAVA_TOOL_OPTIONS='-Duser.language=en -Duser.country=US'
.\gradlew.bat -p source/desktop :desktop:test --tests 'org.geogebra.desktop.plugin.CallJavaScriptTest.testEval' --no-daemon --console=plain
```

## Results

| Gradle task | Result | Test XML summary | Duration / notes |
|---|---|---|---|
| `:common-jre:test` | **BUILD SUCCESSFUL** | 6,526 test cases; 0 failures; 0 errors; 12 skipped; 637 XML suite files | 4m 29s. |
| `:desktop:test` | **BUILD FAILED** | 1,090 test cases; 1 failure; 0 errors; 1 skipped; 47 XML suite files | 2m 50s. Failure was locale-sensitive expected English text vs actual French text. |
| Targeted `CallJavaScriptTest.testEval`, English locale | **BUILD SUCCESSFUL** | Targeted test passed | 21s. Confirms a likely locale/test-environment issue, but does not erase the initial failing baseline. |

Failing test from the unmodified-locale desktop run:

```text
org.geogebra.desktop.plugin.CallJavaScriptTest::testEval
expected: Access to Java class "java.lang.Class" is prohibited. (Error at line:#1)
actual:   L'accès à la classe Java "java.lang.Class" est prohibé. (Error at line:#1)
```

This is not evidence of an OSGi failure. It is an existing test assertion/environment locale mismatch. The clean baseline is therefore **common-jre PASS; desktop 1 locale-related failure, targeted English rerun PASS**. Keep both results in the audit record.

## Reports and reproducibility

- `source/shared/common-jre/build/test-results/test/TEST-*.xml`
- `source/desktop/desktop/build/test-results/test/TEST-*.xml`
- HTML report for desktop: `source/desktop/desktop/build/reports/tests/test/index.html`
- Working directory was Windows. `JAVA_HOME` for Gradle launch was Temurin 21. The source checkout's desktop `run` task separately declares a Java 25 toolchain; these test commands do not establish the eventual RCP runtime Java compatibility.

## Findings / next action

The test counts differ from the handoff's Java test-file counts because source files, XML test suites and individual test cases are different measures. Preserve the Gradle XML reports as the baseline evidence. Consider making the locale explicit for the test task or correcting the test to compare locale-independent output, but that requires a separate upstream change decision and is not part of this audit.

The tests exercise existing GeoGebra code only. They do **not** validate Equinox, wrapper bundles, SWT/AWT embedding, JOGL/GIAC loading under Equinox, or a replacement web runtime.
