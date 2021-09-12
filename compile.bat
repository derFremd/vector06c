@echo off
if exist utils_demo.bin del utils_demo.bin
if exist utils_demo.lst del utils_demo.lst
if exist utils_demo.exp del utils_demo.exp
if exist utils_demo.wav del utils_demo.wav
if exist utils_demo.com del utils_demo.com

tools\pasmo --w8080 utils_demo.asm utils_demo.rom utils_demo.txt
if errorlevel 1 goto Failed

tools\bin2wav.exe utils_demo.rom utils_demo.wav -n util-dem -m v06c-rom

echo.
echo SUCCESS
start c:\WinApp\Emu80qt_40362\Emu80qt.exe utils_demo.rom
goto Exit


:Failed
echo. 
echo FAILED
pause

:Exit
timeout /t 5
