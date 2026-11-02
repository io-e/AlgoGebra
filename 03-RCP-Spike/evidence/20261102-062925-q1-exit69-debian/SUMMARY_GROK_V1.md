# Q1 no-JDK exit code 4 -> 69 (GROK_V1)
Owner decision: https://github.com/io-e/AlgoGebra/issues/17#issuecomment-6569788303 (Q1). launch.sh no usable Java >= 25 now exits **69** (EX_UNAVAILABLE), same as launch.ps1; 3/64/65/66/77 unchanged.
Debian 13, pwsh 7.6.9: suite 17 **15/0/0** (L-03/05/08/09 expect 69); suite 18 **21/0/1** (PR #11 image), **20/0/2** (r8 image); LC-17b-no-jdk-exit-code-69 PASS rc=69.
Windows: LC-17b now runs when no bundled jre and no Eclipse JustJ plugin exist (no launch.ps1 change), else SKIP with reason.
