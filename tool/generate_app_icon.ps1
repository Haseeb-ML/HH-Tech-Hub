Add-Type -AssemblyName System.Drawing

$logoPath = Resolve-Path "assets/logo.png"
$src = [System.Drawing.Image]::FromFile($logoPath)

# 1. Create standard 512x512 square app_icon.png with white background and centered logo
$size = 512
$bmp = New-Object System.Drawing.Bitmap $size, $size
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.Clear([System.Drawing.Color]::White)

# Calculate dimensions to fit inside 70% of 512 so it has safe margins for round/squircle masks
$targetWidth = [int]($size * 0.70)
$aspectRatio = $src.Width / $src.Height
$targetHeight = [int]($targetWidth / $aspectRatio)

if ($targetHeight -gt ($size * 0.70)) {
    $targetHeight = [int]($size * 0.70)
    $targetWidth = [int]($targetHeight * $aspectRatio)
}

$x = [int](($size - $targetWidth) / 2)
$y = [int](($size - $targetHeight) / 2)

$g.DrawImage($src, $x, $y, $targetWidth, $targetHeight)
$bmp.Save((Resolve-Path "assets").Path + "/app_icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

# 2. Create 512x512 adaptive foreground (transparent background, logo in safe center circle 60% of canvas)
$fgBmp = New-Object System.Drawing.Bitmap $size, $size
$fgG = [System.Drawing.Graphics]::FromImage($fgBmp)
$fgG.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$fgG.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$fgG.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$fgG.Clear([System.Drawing.Color]::Transparent)

# In Android adaptive icons, the safe zone is inner 66% (diameter 66dp out of 108dp)
# To avoid any cropping, we fit logo into 60% width
$fgWidth = [int]($size * 0.60)
$fgHeight = [int]($fgWidth / $aspectRatio)
$fgX = [int](($size - $fgWidth) / 2)
$fgY = [int](($size - $fgHeight) / 2)

$fgG.DrawImage($src, $fgX, $fgY, $fgWidth, $fgHeight)
$fgBmp.Save((Resolve-Path "assets").Path + "/app_icon_foreground.png", [System.Drawing.Imaging.ImageFormat]::Png)
$fgG.Dispose()
$fgBmp.Dispose()
$src.Dispose()

# 3. Synchronize mipmap ic_launcher_round.png with ic_launcher.png
Get-ChildItem "android/app/src/main/res/mipmap-*" -Directory | ForEach-Object {
    $launcher = Join-Path $_.FullName "ic_launcher.png"
    $round = Join-Path $_.FullName "ic_launcher_round.png"
    if (Test-Path $launcher) {
        Copy-Item $launcher $round -Force
        Write-Output "Synchronized $round"
    }
}

Write-Output "Successfully generated assets/app_icon.png, assets/app_icon_foreground.png, and updated all Android icons!"
