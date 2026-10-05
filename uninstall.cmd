@net session >nul 2>&1 || (powershell.exe -NoProfile -Command "Start-Process -Verb RunAs -FilePath '%~f0'" & exit /b)
@powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\install.ps1" -Uninstall
@pause
