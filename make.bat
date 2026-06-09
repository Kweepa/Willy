@echo off
\app\acme\acme -o jsw.prg --vicelabels jsw.lbl jsw.asm
if errorlevel 1 exit /b 1
AcmeLabelSorter jsw.lbl jsws.lbl
python tools\mkroom.py --all rooms rooms\out
python tools\mkdisk.py --out jsw.d64 --prg jsw.prg --rooms rooms/out
\app\vice3.10\bin\xvic -pal +basicload -autostart jsw.d64
