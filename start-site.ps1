$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8765
$linkFile = Join-Path $env:USERPROFILE "Desktop\sayt-link.txt"
$outLog = Join-Path $root "tunnel.out.log"
$errLog = Join-Path $root "tunnel.err.log"

Set-Location -LiteralPath $root

$listening = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
if (-not $listening) {
  Start-Process -WindowStyle Hidden -FilePath "python" -ArgumentList "-m","http.server","$port","--bind","127.0.0.1" -WorkingDirectory $root
  Start-Sleep -Seconds 2
}

$sshAlive = Get-CimInstance Win32_Process -Filter "Name='ssh.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -match "localhost.run" }
if ($sshAlive) { exit 0 }

foreach ($f in @($outLog, $errLog)) {
  if (Test-Path $f) { Remove-Item $f -Force -ErrorAction SilentlyContinue }
}

$null = Start-Process -FilePath "ssh" -ArgumentList @(
  "-o","StrictHostKeyChecking=accept-new",
  "-o","ServerAliveInterval=30",
  "-o","ExitOnForwardFailure=yes",
  "-R","80:127.0.0.1:$port",
  "nokey@localhost.run"
) -RedirectStandardOutput $outLog -RedirectStandardError $errLog -WindowStyle Hidden -PassThru

$url = $null
for ($i = 0; $i -lt 40; $i++) {
  Start-Sleep -Seconds 1
  $text = ""
  foreach ($f in @($outLog, $errLog)) {
    if (Test-Path $f) { $text += Get-Content $f -Raw -ErrorAction SilentlyContinue }
  }
  if ($text -match "https://[a-z0-9]+\.lhr\.life") {
    $url = $Matches[0]
    break
  }
}

if ($url) {
  $body = @"
Linki sayt (Rasasi):
$url

In linkro ba telefon, WhatsApp va Instagram guzored.
Agar noutbukro khomush kuned, sayt ham khomush meshavad.
Vakte noutbukro kushed, sayt khudash boz meshavad.
"@
  $utf8 = New-Object System.Text.UTF8Encoding $true
  [System.IO.File]::WriteAllText($linkFile, $body, $utf8)
}
