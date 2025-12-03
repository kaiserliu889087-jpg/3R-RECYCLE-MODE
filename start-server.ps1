# 簡單的 HTTP 服務器腳本
$port = 8000
$url = "http://localhost:$port/"

Write-Host "正在啟動本地服務器..." -ForegroundColor Green
Write-Host "服務器地址: $url" -ForegroundColor Cyan
Write-Host "按 Ctrl+C 停止服務器" -ForegroundColor Yellow
Write-Host ""

# 檢查端口是否被占用
$listener = $null
try {
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add($url)
    $listener.Start()
    
    Write-Host "服務器已啟動！" -ForegroundColor Green
    Write-Host "在瀏覽器中打開: $url" -ForegroundColor Cyan
    Write-Host ""
    
    # 自動打開瀏覽器
    Start-Process $url
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $localPath = $request.Url.LocalPath
        if ($localPath -eq "/" -or $localPath -eq "") {
            $localPath = "/index.html"
        }
        
        $filePath = Join-Path $PSScriptRoot $localPath.TrimStart('/')
        
        if (Test-Path $filePath) {
            $content = [System.IO.File]::ReadAllBytes($filePath)
            $extension = [System.IO.Path]::GetExtension($filePath)
            
            # 設置 MIME 類型
            $mimeTypes = @{
                ".html" = "text/html; charset=utf-8"
                ".css" = "text/css"
                ".js" = "application/javascript"
                ".json" = "application/json"
                ".png" = "image/png"
                ".jpg" = "image/jpeg"
                ".jpeg" = "image/jpeg"
                ".gif" = "image/gif"
                ".svg" = "image/svg+xml"
            }
            
            $contentType = $mimeTypes[$extension]
            if (-not $contentType) {
                $contentType = "application/octet-stream"
            }
            
            $response.ContentType = $contentType
            $response.ContentLength64 = $content.Length
            $response.StatusCode = 200
            $response.OutputStream.Write($content, 0, $content.Length)
        } else {
            $response.StatusCode = 404
            $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 - 找不到文件")
            $response.ContentLength64 = $notFound.Length
            $response.OutputStream.Write($notFound, 0, $notFound.Length)
        }
        
        $response.Close()
    }
} catch {
    Write-Host "錯誤: $_" -ForegroundColor Red
    Write-Host "端口 $port 可能已被占用，請嘗試關閉其他使用該端口的程序" -ForegroundColor Yellow
} finally {
    if ($listener) {
        $listener.Stop()
        $listener.Close()
    }
}

