# Builds the Microsoft Store MSIX from the Tauri release exe.
# Run `npm run tauri build` first. Output: src-tauri/target/release/bundle/msix/
# The package is unsigned; the Store signs it on submission.
$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent
$tauri = Join-Path $root 'src-tauri'

# The Store requires the fourth version part to be 0.
$version = (Get-Content (Join-Path $tauri 'tauri.conf.json') -Raw | ConvertFrom-Json).package.version
$msixVersion = "$version.0"

$makeappx = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\10.*\x64\makeappx.exe" -ErrorAction SilentlyContinue |
  Sort-Object { [version]$_.Directory.Parent.Name } | Select-Object -Last 1
if (-not $makeappx) { throw 'makeappx.exe not found. Install the Windows SDK.' }
$makepri = Join-Path $makeappx.DirectoryName 'makepri.exe'

$exe = Join-Path $tauri 'target\release\PhilsDictationApp.exe'
if (-not (Test-Path $exe)) { throw "Missing $exe. Run 'npm run tauri build' first." }

$work = Join-Path $tauri 'target\msix'
$stage = Join-Path $work 'staging'
$outDir = Join-Path $tauri 'target\release\bundle\msix'
$out = Join-Path $outDir "PhilsDictationApp_${msixVersion}_x64.msix"

Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
$exeDir = Join-Path $stage 'VFS\ProgramFilesX64\PhilsDictationApp'
New-Item -ItemType Directory $exeDir, $outDir -Force | Out-Null

# Same layout as the 1.0.0.0 package, but only the app and its logos.
Copy-Item $exe $exeDir
Copy-Item (Join-Path $tauri 'msix\Assets') $stage -Recurse

$manifest = New-Object System.Xml.XmlDocument
$manifest.PreserveWhitespace = $true
$manifest.Load((Join-Path $tauri 'msix\AppxManifest.xml'))
$manifest.Package.Identity.Version = $msixVersion
$manifest.Save((Join-Path $stage 'AppxManifest.xml'))

# resources.pri maps logo names like StoreLogo.png to their scale-specific files.
$priConfig = Join-Path $work 'priconfig.xml'
& $makepri createconfig /cf $priConfig /dq en-US /o | Out-Null
if ($LASTEXITCODE) { throw "makepri createconfig failed ($LASTEXITCODE)" }
# Keep every scale in one resources.pri; split .pri files are only for resource packs in bundles.
[xml]$cfg = Get-Content $priConfig -Raw
$cfg.SelectNodes('//packaging') | ForEach-Object { $_.ParentNode.RemoveChild($_) | Out-Null }
$cfg.Save($priConfig)
& $makepri new /pr $stage /cf $priConfig /mn (Join-Path $stage 'AppxManifest.xml') /of (Join-Path $stage 'resources.pri') /o
if ($LASTEXITCODE) { throw "makepri new failed ($LASTEXITCODE)" }

& $makeappx pack /d $stage /p $out /o
if ($LASTEXITCODE) { throw "makeappx pack failed ($LASTEXITCODE)" }

Write-Host "Built $out"
