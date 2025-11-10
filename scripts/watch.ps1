# Nexus Watch 模式启动脚本
# 启用热重载，代码修改后自动重新编译和刷新

Write-Host "🚀 启动 Nexus Watch 模式..." -ForegroundColor Green
Write-Host "💡 代码修改会自动热重载" -ForegroundColor Cyan
Write-Host "💡 按 'r' 键手动刷新，按 'R' 键重启应用" -ForegroundColor Cyan
Write-Host "💡 按 Ctrl+C 停止" -ForegroundColor Yellow
Write-Host ""

flutter run -d windows --hot










































