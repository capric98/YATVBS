@echo off
chcp 65001

set THREADS=32
set CACHESIZE=32000
set KEYINT=180

set FILE=%~dpn1

echo import vapoursynth as vs> "%FILE%.vpy"
echo import mvsfunc as mvf>> "%FILE%.vpy"
echo.>> "%FILE%.vpy"
echo core = vs.get_core(threads=%THREADS%)>> "%FILE%.vpy"
echo core.max_cache_size = %CACHESIZE%>> "%FILE%.vpy"
echo.>> "%FILE%.vpy"
echo f = r"%1">> "%FILE%.vpy"
echo src = core.lsmas.LWLibavSource(source=f, format="yuv420p16")>> "%FILE%.vpy"
echo.>> "%FILE%.vpy"
echo # ordered dither>> "%FILE%.vpy"
echo bright = mvf.Depth(src, 8, dither=1)>> "%FILE%.vpy"
echo dark = mvf.Depth(src, 8, dither=0, ampo=1.5)>> "%FILE%.vpy"
echo # merge & output>> "%FILE%.vpy"
echo res = core.std.MaskedMerge(dark, bright, core.std.Binarize(bright, 96, planes=0), first_plane=True)>> "%FILE%.vpy"
echo res.set_output(0)>> "%FILE%.vpy"

vspipe --y4m "%FILE%.vpy" - | x264 --demuxer y4m - ^
    --level 5.1 --preset veryslow --deblock 0:0 ^
    --ref 12 --bframes 12 --min-keyint 1 --keyint %KEYINT% ^
    --bitrate 5800 --no-mbtree --b-adapt 2 --me umh --merange 32 ^
    --vbv-bufsize 300000 --vbv-maxrate 22000 ^
    --aq-mode=1 --aq-strength 0.9 --psy-rd 0:0.2 --rc-lookahead 70 --no-fast-pskip ^
    --colormatrix bt709 --fgo 1 -o "%FILE%.pass1.mkv" --pass 1 --slow-firstpass --stats "%FILE%.stats"
vspipe --y4m "%FILE%.vpy" - | x264 --demuxer y4m - ^
    --level 5.1 --preset veryslow --deblock 0:0 ^
    --ref 12 --bframes 12 --min-keyint 1 --keyint %KEYINT% ^
    --bitrate 5800 --no-mbtree --b-adapt 2 --me umh --merange 32 ^
    --vbv-bufsize 300000 --vbv-maxrate 22000 ^
    --aq-mode=1 --aq-strength 0.9 --psy-rd 0:0.2 --rc-lookahead 70 --no-fast-pskip ^
    --colormatrix bt709 --fgo 1 --pass 2 --stats "%FILE%.stats" -o "%FILE%.2pass.mkv"

REM del /F /Q "%FILE%.vpy"
del /F /Q "%FILE%.stats"
pause
