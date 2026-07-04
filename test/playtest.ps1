# CALAMITY bot playtest harness.
#   .\test\playtest.ps1            -> quick matrix (3 scenarios)
#   .\test\playtest.ps1 full       -> all gods: skirmish + full crusade chains
#   .\test\playtest.ps1 crusade    -> one full crusade chain per god
# Reports land in test\results\*.json; SCRIPT ERRORs in *.err.txt.
param([string]$Matrix = "quick")

$godot = "D:\Godot\Godot_v4.7-stable_win64.exe"
$root = Split-Path $PSScriptRoot -Parent
$out = Join-Path $root "test\results"
New-Item -ItemType Directory -Force $out | Out-Null

$gods = @("swarm", "keraunos", "tzitzimitl", "drowned", "rider")
$scen = @()
switch ($Matrix) {
    "quick" {
        $scen += @{n = "rider_hamlet";    e = @{CAL_CHAR = "rider";   CAL_KIND = "hamlet"; CAL_BOT_TIME = "300"} }
        $scen += @{n = "drowned_extinct"; e = @{CAL_CHAR = "drowned"; CAL_KIND = "town"; CAL_OBJ = "extinction"; CAL_BOT_TIME = "360"} }
        $scen += @{n = "swarm_kowloon";   e = @{CAL_CHAR = "swarm";   CAL_CITY = "kowloon"; CAL_BOT_TIME = "360"} }
    }
    "full" {
        foreach ($g in $gods) {
            $scen += @{n = "skirmish_$g"; e = @{CAL_CHAR = $g; CAL_CITY = "kowloon"; CAL_BOT_TIME = "360"} }
            $scen += @{n = "crusade_$g";  e = @{CAL_CHAR = $g; CAL_KIND = "prologue"; CAL_BOT_TIME = "1500"} }
        }
    }
    "crusade" {
        foreach ($g in $gods) {
            $scen += @{n = "crusade_$g"; e = @{CAL_CHAR = $g; CAL_KIND = "prologue"; CAL_BOT_TIME = "1500"} }
        }
    }
}

$rows = @()
foreach ($s in $scen) {
    $rep = Join-Path $out "$($s.n).json"
    $errf = Join-Path $out "$($s.n).err.txt"
    if (Test-Path $rep) { Remove-Item $rep -Force }
    $env:CAL_BOT = "1"
    $env:CAL_BOT_REPORT = $rep
    foreach ($k in $s.e.Keys) { Set-Item "env:$k" $s.e[$k] }
    Write-Host ">> $($s.n)" -ForegroundColor Cyan
    $timeoutMs = ([int]$s.e.CAL_BOT_TIME + 90) * 1000
    $p = Start-Process -FilePath $godot -ArgumentList "--path", $root, "res://main.tscn" `
        -PassThru -RedirectStandardError $errf
    if (-not $p.WaitForExit($timeoutMs)) { Stop-Process -Id $p.Id -Force; Write-Host "   killed (hard timeout)" }
    foreach ($k in $s.e.Keys) { Remove-Item "env:$k" -ErrorAction SilentlyContinue }
    Remove-Item env:CAL_BOT, env:CAL_BOT_REPORT -ErrorAction SilentlyContinue

    $errors = @(Get-Content $errf -ErrorAction SilentlyContinue | Select-String "SCRIPT ERROR" | Select-Object -First 5)
    $result = "NO REPORT"
    $extra = ""
    if (Test-Path $rep) {
        $j = Get-Content $rep -Raw | ConvertFrom-Json
        $result = $j.result
        $extra = "t=$($j.time)s fps_min=$($j.fps_min) act=$($j.act) razed=$($j.razed) roar=$($j.roar)"
    }
    $rows += [pscustomobject]@{scenario = $s.n; result = $result; errors = $errors.Count; detail = $extra }
}

""
$rows | Format-Table -AutoSize
$bad = @($rows | Where-Object { $_.result -in @("softlock", "map_stuck", "NO REPORT") -or $_.errors -gt 0 })
if ($bad.Count -gt 0) { Write-Host "FAILURES: $($bad.Count)" -ForegroundColor Red; exit 1 }
Write-Host "ALL PASS" -ForegroundColor Green
