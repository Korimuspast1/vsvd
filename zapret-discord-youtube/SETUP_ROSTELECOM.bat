@echo off
chcp 65001 >nul
cd /d "%~dp0"

net session >nul 2>&1
if not %errorlevel%==0 (
  echo Требуются права администратора. Запрашиваю их...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
  exit /b
)

echo [1/5] Останавливаю старую службу zapret...
sc stop zapret >nul 2>&1
sc delete zapret >nul 2>&1

echo [2/5] Инициализирую пользовательские списки...
call service.bat load_user_lists

if not exist "lists\list-general-user.txt" echo # custom domains>"lists\list-general-user.txt"
if not exist "lists\list-exclude-user.txt" echo # exclusions>"lists\list-exclude-user.txt"
if not exist "lists\ipset-exclude-user.txt" echo 203.0.113.113/32>"lists\ipset-exclude-user.txt"

echo [3/5] Сбрасываю DNS и сетевой кэш...
ipconfig /flushdns >nul
netsh winhttp reset proxy >nul

 echo [4/5] Запускаю базовую стратегию для проверки...
call "general (ALT).bat"

echo.
echo [5/5] Готово. Проверьте YouTube, Discord и Telegram.
echo Если сайты открываются, выполните:
echo    service.bat ^> Install Service
 echo и выберите general (ALT).bat для автозапуска Windows.
echo.
pause
