@echo off

set OUT_DIR=build\desktop
if not exist %OUT_DIR% mkdir %OUT_DIR%

odin run src\main_desktop -out:%OUT_DIR%\game_desktop.exe
IF %ERRORLEVEL% NEQ 0 exit /b 1

xcopy /y /e /i assets %OUT_DIR%\assets >nul
IF %ERRORLEVEL% NEQ 0 exit /b 1

echo Desktop build created in %OUT_DIR%