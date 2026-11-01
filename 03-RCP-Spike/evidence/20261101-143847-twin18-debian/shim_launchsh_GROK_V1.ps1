# Maps launch.ps1 test args to launch.sh: -NoBuild dropped, -Headless -> --headless, -Course/--course passed through.
$m = @(foreach ($a in $args) { switch -CaseSensitive ($a) { '-NoBuild' { } '-Headless' { '--headless' } default { $a } } })
$env:IMAGE = '/workspace/AlgoGebra/image/GeoGebraPlus-RCP-0.1.0-linux-gtk-x86_64'
$env:GGB_JAVA = (Get-ChildItem /workspace/AlgoGebra/jdk -Directory -Filter 'jdk-25*' | Select-Object -First 1).FullName + '/bin/java'
& bash (Join-Path '/tmp/twin/03-RCP-Spike' 'launch.sh') @m; exit $LASTEXITCODE
