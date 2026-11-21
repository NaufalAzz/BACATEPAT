param(
  [Parameter(Mandatory = $true)][int]$DebugPort,
  [Parameter(Mandatory = $true)][int]$AppPort,
  [string]$NavigateTo = '',
  [int]$Width = 390,
  [int]$Height = 844,
  [int]$ClickX = -1,
  [int]$ClickY = -1,
  [int]$ClickX2 = -1,
  [int]$ClickY2 = -1,
  [string]$Text = '',
  [string]$Text2 = '',
  [string]$Eval = '',
  [string]$WaitBeforeInteractionExpression = '',
  [string]$WaitForExpression = '',
  [int]$WaitTimeoutMilliseconds = 10000,
  [int]$NavigateWaitMilliseconds = 800,
  [int]$CaptureDelayMilliseconds = 1200,
  [Parameter(Mandatory = $true)][string]$Output,
  [switch]$Reload
)

$ErrorActionPreference = 'Stop'
$pages = ConvertFrom-Json -InputObject (Invoke-WebRequest "http://127.0.0.1:$DebugPort/json" -UseBasicParsing).Content
$page = @($pages | Where-Object { $_.type -eq 'page' -and $_.url -match "^http://(localhost|127\.0\.0\.1):$AppPort/" })[0]
if (-not $page) { throw "No Chrome page found for port $AppPort." }
$socket = [System.Net.WebSockets.ClientWebSocket]::new()
$socket.ConnectAsync([Uri]::new([string]$page.webSocketDebuggerUrl), [Threading.CancellationToken]::None).GetAwaiter().GetResult()
$script:cdpId = 0

function Send-Cdp([string]$Method, [hashtable]$Params = @{}) {
  $script:cdpId++
  $currentId = $script:cdpId
  $json = @{ id = $currentId; method = $Method; params = $Params } | ConvertTo-Json -Compress -Depth 8
  $bytes = [Text.Encoding]::UTF8.GetBytes($json)
  $null = $socket.SendAsync([ArraySegment[byte]]::new($bytes), [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
  $buffer = [byte[]]::new(1048576)
  do {
    $message = [IO.MemoryStream]::new()
    do {
      $part = $socket.ReceiveAsync([ArraySegment[byte]]::new($buffer), [Threading.CancellationToken]::None).GetAwaiter().GetResult()
      $message.Write($buffer, 0, $part.Count)
    } while (-not $part.EndOfMessage)
    $response = [Text.Encoding]::UTF8.GetString($message.ToArray()) | ConvertFrom-Json
    $message.Dispose()
  } while ($response.id -ne $currentId)
  return $response
}

Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = $Width; height = $Height; deviceScaleFactor = 1; mobile = $true } | Out-Null
Start-Sleep -Milliseconds 400
if ($Reload) {
  Send-Cdp 'Page.reload' @{ ignoreCache = $true } | Out-Null
  Start-Sleep -Seconds 3
}
if ($NavigateTo) {
  Send-Cdp 'Page.navigate' @{ url = $NavigateTo } | Out-Null
  Start-Sleep -Milliseconds $NavigateWaitMilliseconds
}
if ($WaitBeforeInteractionExpression) {
  $deadline = [DateTime]::UtcNow.AddMilliseconds($WaitTimeoutMilliseconds)
  do {
    $ready = Send-Cdp 'Runtime.evaluate' @{ expression = $WaitBeforeInteractionExpression; returnByValue = $true }
    if ($ready.result.result.value) { break }
    Start-Sleep -Milliseconds 50
  } while ([DateTime]::UtcNow -lt $deadline)
  if (-not $ready.result.result.value) { throw "Timed out waiting before interaction: $WaitBeforeInteractionExpression" }
}
if ($ClickX -ge 0 -and $ClickY -ge 0) {
  Send-Cdp 'Input.dispatchMouseEvent' @{ type = 'mouseMoved'; x = $ClickX; y = $ClickY; button = 'none' } | Out-Null
  Start-Sleep -Milliseconds 100
  Send-Cdp 'Input.dispatchMouseEvent' @{ type = 'mousePressed'; x = $ClickX; y = $ClickY; button = 'left'; clickCount = 1 } | Out-Null
  Send-Cdp 'Input.dispatchMouseEvent' @{ type = 'mouseReleased'; x = $ClickX; y = $ClickY; button = 'left'; clickCount = 1 } | Out-Null
  if ($Text) { Send-Cdp 'Input.insertText' @{ text = $Text } | Out-Null }
}
if ($ClickX2 -ge 0 -and $ClickY2 -ge 0) {
  Start-Sleep -Milliseconds 400
  Send-Cdp 'Input.dispatchMouseEvent' @{ type = 'mouseMoved'; x = $ClickX2; y = $ClickY2; button = 'none' } | Out-Null
  Start-Sleep -Milliseconds 100
  Send-Cdp 'Input.dispatchMouseEvent' @{ type = 'mousePressed'; x = $ClickX2; y = $ClickY2; button = 'left'; clickCount = 1 } | Out-Null
  Send-Cdp 'Input.dispatchMouseEvent' @{ type = 'mouseReleased'; x = $ClickX2; y = $ClickY2; button = 'left'; clickCount = 1 } | Out-Null
  if ($Text2) { Send-Cdp 'Input.insertText' @{ text = $Text2 } | Out-Null }
}
Start-Sleep -Milliseconds $CaptureDelayMilliseconds
if ($Eval) {
  $evaluated = Send-Cdp 'Runtime.evaluate' @{ expression = $Eval; returnByValue = $true }
  Write-Output ($evaluated.result.result.value | ConvertTo-Json -Depth 8)
}
if ($WaitForExpression) {
  $deadline = [DateTime]::UtcNow.AddMilliseconds($WaitTimeoutMilliseconds)
  do {
    $ready = Send-Cdp 'Runtime.evaluate' @{ expression = $WaitForExpression; returnByValue = $true }
    if ($ready.result.result.value) { break }
    Start-Sleep -Milliseconds 50
  } while ([DateTime]::UtcNow -lt $deadline)
  if (-not $ready.result.result.value) { throw "Timed out waiting for expression: $WaitForExpression" }
}
$shot = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; fromSurface = $true; captureBeyondViewport = $false }
[IO.File]::WriteAllBytes($Output, [Convert]::FromBase64String($shot.result.data))
Write-Output "Saved $Output ($Width x $Height)"
$socket.Dispose()
