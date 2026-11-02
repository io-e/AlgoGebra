# Suite 20: GeoGebra-backed Java corpus test (GROK_V1)
Image: image-final (tip build), JDK 25.0.5. 54 validator/scanner cases through the real StepValidator + headless AppDNoGui.
Result: **54/0/2** (52 PASS + compile + summary; 2 XFAIL = T-45/T-51, issue #21 Q3b). When #21 lands they turn into XPASS -> remove from XFAIL.
Convention: plain javac/java main() test like CourseModelTest/StepValidatorPolicyTest (no Gradle/JUnit in the RCP spike).
