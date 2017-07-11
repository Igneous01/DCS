@echo off
:start
Start "" "C:\xampp\php\php-win.exe" C:\xampp\htdocs\cron.php
timeout 5
cls
goto start