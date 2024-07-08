# DebugMode?
$isDebug = $false
#$isDebug = $true

function EndMake() {
    if (!$isDebug) {
        Stop-Transcript | Out-Null
    }

    ''
    Read-Host "終了するには何かキーを教えてください..."
    exit
}

# 現在のディレクトリを取得する
$cd = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $cd

if (!$isDebug) {
    Start-Transcript make.log | Out-Null
}

# target
$targetClientDirectory = Get-Item .\source\RINGS
$targetDirectories = @($targetClientDirectory)
$depolyDirectory = ".\source\deploy"

# tools
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
if (Test-Path "C:\Program Files\Microsoft Visual Studio\2022\Preview\MSBuild\Current\Bin\MSBuild.exe") {
    $msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Preview\MSBuild\Current\Bin\MSBuild.exe"
}

$appName = "RINGS"
## アーカイブファイル名を決定する
$archiveFileName = $appName + ".zip"

'-> Build'
# Delete Release Directory
foreach ($d in $targetDirectories) {
    $out = Join-Path $d "bin\Release\*"
    if (Test-Path $out) {
        Remove-Item -Recurse -Force $out
    }
}

$target = Get-Item .\source\*.sln
& $msbuild $target /nologo /v:minimal /t:Clean /p:Configuration=Release
Start-Sleep -m 100

'-> Build Client'
$target = Get-Item $targetClientDirectory\*.csproj
& $msbuild $target /nologo /v:minimal /t:Build /p:Configuration=Release | Write-Output
Start-Sleep -m 100

# Successed? build
foreach ($d in $targetDirectories) {
    $out = Join-Path $d "bin\Release"
    if (!(Test-Path $out)) {
        EndMake
    }
}

foreach ($d in $targetDirectories) {
    # pdb を削除する
    Remove-Item -Force (Join-Path $d "bin\Release\*.pdb")

    # app.config を削除する
    $targets = @(
        (Join-Path $d "bin\Release\RINGS.exe.config"),
        (Join-Path $d "bin\Release\aframe.Updater.exe.config"))

    foreach ($t in $targets) {
        if (Test-Path $t) {
            Remove-Item -Force $t
        }
    }
}

'-> Deploy'
# deploy ディレクトリを作る
if (!(Test-Path $depolyDirectory)) {
    New-Item -ItemType Directory $depolyDirectory >$null
}

$deployBase = Join-Path $depolyDirectory $archiveFileName.Replace(".zip", "")
if (Test-Path $deployBase) {
    Get-ChildItem -Path $deployBase -Recurse | Remove-Item -Force -Recurse
    Remove-Item -Recurse -Force $deployBase
}

$deployClient = $deployBase
New-Item -ItemType Directory $deployClient >$null

# client を配置する
'-> Deploy Client'
Copy-Item -Force -Recurse $targetClientDirectory\bin\Release\* $deployClient

# client をアーカイブする
'-> Archive Client'
Compress-Archive -Force $deployClient\* $deployBase\..\$archiveFileName
Get-ChildItem -Path $deployBase -Recurse | Remove-Item -Force -Recurse
Remove-Item -Recurse -Force $deployBase

if (!$isDebug) {
    if (Test-Path .\RELEASE_NOTES.bak) {
        Remove-Item -Force .\RELEASE_NOTES.bak
    }
}

Write-Output "***"
Write-Output ("*** " + $appName + ", Completed! ***")
Write-Output "***"

EndMake
