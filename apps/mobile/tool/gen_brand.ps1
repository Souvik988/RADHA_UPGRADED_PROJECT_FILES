param(
  [string]$OutDir = "assets/brand"
)

Add-Type -AssemblyName System.Drawing

function New-BrandPng {
  param(
    [int]$Size,
    [string]$Path,
    [bool]$DrawMark
  )

  $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  # Orange brand background #EA580C
  $bg = [System.Drawing.Color]::FromArgb(255, 234, 88, 12)
  $g.Clear($bg)

  if ($DrawMark) {
    # Draw a centered cream "R" wordmark (#FFFBF5)
    $fontSize = [int]($Size * 0.62)
    # Use Plus Jakarta Sans if available, otherwise fall back to Segoe UI Bold
    $fontName = "Segoe UI"
    try {
      $testFont = New-Object System.Drawing.Font("Plus Jakarta Sans", $fontSize, [System.Drawing.FontStyle]::Bold)
      if ($testFont.Name -eq "Plus Jakarta Sans") { $fontName = "Plus Jakarta Sans" }
      $testFont.Dispose()
    } catch {}

    $font = New-Object System.Drawing.Font($fontName, $fontSize, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 251, 245))
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    # Slight optical adjustment so the R sits in the center
    $rect = New-Object System.Drawing.RectangleF(0, [single]($Size * -0.03), [single]$Size, [single]$Size)
    $g.DrawString("R", $font, $brush, $rect, $sf)
    $font.Dispose()
    $brush.Dispose()
    $sf.Dispose()
  }

  $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
  Write-Host "Wrote $Path ($Size x $Size)"
}

if (-not (Test-Path $OutDir)) {
  New-Item -ItemType Directory -Path $OutDir | Out-Null
}

New-BrandPng -Size 1024 -Path (Join-Path $OutDir "icon.png") -DrawMark $true
New-BrandPng -Size 1024 -Path (Join-Path $OutDir "icon_foreground.png") -DrawMark $true
New-BrandPng -Size 1024 -Path (Join-Path $OutDir "splash.png") -DrawMark $true
