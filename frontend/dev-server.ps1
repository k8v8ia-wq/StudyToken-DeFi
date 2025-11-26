param(
  [int]$Port = 5173
)

$Prefix = "http://localhost:$Port/"
$BaseDir = $PSScriptRoot

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($Prefix)
$listener.Start()
Write-Host "Dev server running at $Prefix"
Write-Host "Admin page: ${Prefix}achievement_reward_admin.html"
Write-Host "Front page: ${Prefix}achievement_reward_front.html"

function Get-MimeType($ext) {
  switch ($ext.ToLower()) {
    '.html' { 'text/html; charset=utf-8' }
    '.js'   { 'application/javascript; charset=utf-8' }
    '.css'  { 'text/css; charset=utf-8' }
    '.json' { 'application/json; charset=utf-8' }
    '.png'  { 'image/png' }
    '.jpg'  { 'image/jpeg' }
    '.jpeg' { 'image/jpeg' }
    '.svg'  { 'image/svg+xml' }
    '.ico'  { 'image/x-icon' }
    default { 'application/octet-stream' }
  }
}

while ($true) {
  try {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    $path = $request.Url.AbsolutePath

    if ($path -eq '/' -or [string]::IsNullOrEmpty($path)) {
      $html = @"
<!doctype html>
<html><head><meta charset="utf-8"><title>CDS528 Frontend</title></head>
<body>
  <h1>CDS528 Frontend</h1>
  <ul>
    <li><a href="/achievement_reward_admin.html">achievement_reward_admin.html</a></li>
    <li><a href="/achievement_reward_front.html">achievement_reward_front.html</a></li>
  </ul>
</body></html>
"@
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
      $response.ContentType = 'text/html; charset=utf-8'
      $response.ContentLength64 = $bytes.Length
      $response.OutputStream.Write($bytes,0,$bytes.Length)
      $response.Close()
      continue
    }

    $safePath = $path.TrimStart('/').Replace('\','/')
    $rootDir = Split-Path $BaseDir -Parent
    if ($safePath.StartsWith('abis/')) {
      # 映射 /abis/* 到上一层的 abis 目录
      $filePath = Join-Path $rootDir $safePath
    } else {
      $filePath = Join-Path $BaseDir $safePath
    }

    if (Test-Path $filePath -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($filePath)
      $mime = Get-MimeType $ext
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $response.ContentType = $mime
      $response.ContentLength64 = $bytes.Length
      $response.OutputStream.Write($bytes,0,$bytes.Length)
    } else {
      $msg = 'Not Found'
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
      $response.StatusCode = 404
      $response.ContentType = 'text/plain; charset=utf-8'
      $response.ContentLength64 = $bytes.Length
      $response.OutputStream.Write($bytes,0,$bytes.Length)
    }
    $response.Close()
  } catch {
    Write-Host "Error handling request: $_" -ForegroundColor Red
  }
}