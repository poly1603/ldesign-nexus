# 将 SVG 转换为 ICO 图标
# 需要安装 ImageMagick: https://imagemagick.org/script/download.php

$svgPath = Join-Path $PSScriptRoot "..\logo.svg"
$icoPath = Join-Path $PSScriptRoot "..\windows\runner\resources\app_icon.ico"

Write-Host "正在转换图标..." -ForegroundColor Cyan
Write-Host "源文件: $svgPath" -ForegroundColor Gray
Write-Host "目标文件: $icoPath" -ForegroundColor Gray

# 尝试使用 magick 命令（ImageMagick 7+）
$magickCmd = Get-Command magick -ErrorAction SilentlyContinue
if ($magickCmd) {
    Write-Host "使用 ImageMagick 7+ (magick 命令)" -ForegroundColor Green
    & magick convert -background none -density 256 $svgPath -define icon:auto-resize=256,128,96,64,48,32,16 $icoPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 图标转换成功！" -ForegroundColor Green
        exit 0
    }
}

# 尝试查找 ImageMagick 6 的 convert.exe
$programFiles = $env:ProgramFiles
$programFiles86 = ${env:ProgramFiles(x86)}

$searchPaths = @(
    "$programFiles\ImageMagick-*\convert.exe",
    "$programFiles86\ImageMagick-*\convert.exe"
)

$found = $false
foreach ($pattern in $searchPaths) {
    $items = Get-Item $pattern -ErrorAction SilentlyContinue
    if ($items) {
        $convertExe = $items[0].FullName
        Write-Host "使用 ImageMagick 6 ($convertExe)" -ForegroundColor Green
        & $convertExe -background none -density 256 $svgPath -define icon:auto-resize=256,128,96,64,48,32,16 $icoPath
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 图标转换成功！" -ForegroundColor Green
            $found = $true
            break
        }
    }
}

if (-not $found) {
    Write-Host "❌ 未找到 ImageMagick，无法自动转换图标" -ForegroundColor Red
    Write-Host ""
    Write-Host "请手动转换图标：" -ForegroundColor Yellow
    Write-Host "1. 安装 ImageMagick: https://imagemagick.org/script/download.php" -ForegroundColor Yellow
    Write-Host "2. 或使用在线工具将 logo.svg 转换为 app_icon.ico" -ForegroundColor Yellow
    Write-Host "3. 将生成的 .ico 文件放到: $icoPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "推荐在线工具：" -ForegroundColor Cyan
    Write-Host "  - https://convertio.co/zh/svg-ico/" -ForegroundColor Cyan
    Write-Host "  - https://cloudconvert.com/svg-to-ico" -ForegroundColor Cyan
    exit 1
}
