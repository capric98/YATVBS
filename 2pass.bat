@echo off
set FILE=%~dpn1
REM echo "%FILE%"

echo Pass 1...
x264 --level 5.1 --preset veryslow --deblock -1:-1 --ref 12 --bframes 12 --min-keyint 1 --keyint 120 --bitrate 5800 --no-mbtree --b-adapt 2 --me umh --merange 32 --vbv-bufsize 300000 --vbv-maxrate 22000 --aq-mode=1 --aq-strength 1.0 --psy-rd 1.2 --rc-lookahead 70 --no-fast-pskip --colormatrix bt709 "%1" -o "%FILE%.tmp.mkv" --pass 1 --slow-firstpass --stats "%FILE%.stats"
echo Pass 2...
x264 --level 5.1 --preset veryslow --deblock -1:-1 --ref 12 --bframes 12 --min-keyint 1 --keyint 120 --bitrate 5800 --no-mbtree --b-adapt 2 --me umh --merange 32 --vbv-bufsize 300000 --vbv-maxrate 22000 --aq-mode=1 --aq-strength 1.0 --psy-rd 1.2 --rc-lookahead 70 --no-fast-pskip --colormatrix bt709 --pass 2 --stats "%FILE%.stats" "%1" -o "%FILE%.mkv"

del /F /Q "%FILE%.stats"
pause
