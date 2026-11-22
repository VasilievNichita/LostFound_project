param([string]$BaseUrl = 'http://127.0.0.1:8080', [string]$Work = 'D:\PAM\Lab5\work\curl')
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $Work | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
$bodyPath = Join-Path $Work 'body.json'
$responsePath = Join-Path $Work 'response.json'
function Send-Curl($method, $path, $body, $token) {
    $arguments = @('--silent','--show-error','-X',$method,'-o',$responsePath,'-w','%{http_code}',"$BaseUrl$path")
    if ($body) {
        [IO.File]::WriteAllText($bodyPath, ($body | ConvertTo-Json -Compress), $utf8)
        $arguments += @('-H','Content-Type: application/json','--data-binary',"@$bodyPath")
    }
    if ($token) { $arguments += @('-H',"Authorization: Bearer $token") }
    $status = & curl.exe @arguments
    if ($LASTEXITCODE -ne 0) { throw 'curl failed' }
    $json = Get-Content $responsePath -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "$method $path -> HTTP $status"
    return $json
}
$email = 'curl-' + [Guid]::NewGuid().ToString('N') + '@example.org'
$auth = Send-Curl POST '/auth/register' @{email=$email;password='sample123';name='Curl check'} $null
Write-Host 'Response: token=<redacted>, user created'
$unauthorized = Send-Curl GET '/items' $null $null
Write-Host ($unauthorized | ConvertTo-Json -Compress)
$item = Send-Curl POST '/items' @{type='found';title='Curl pencil case';description='Blue fabric';location='Библиотека'} $auth.token
Write-Host ($item | ConvertTo-Json -Compress)
$list = Send-Curl GET '/items?search=Curl%20pencil&page=1&limit=20' $null $auth.token
Write-Host ($list | ConvertTo-Json -Compress -Depth 5)
# Token and sample password are never retained in the transcript or work files.
Remove-Item -LiteralPath $bodyPath,$responsePath
