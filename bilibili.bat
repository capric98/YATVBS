@echo off
chcp 65001 >nul
cls

REM Check if prerequisites were fit.
where /q ffmpeg || echo 未找到ffmpeg. && goto :eof
where /q python || echo 未找到Python.
where /q vspipe || echo 未找到vspipe(可能是没有安装VapourSynth^). && goto :eof
where /q x264   || echo 未找到x264. && goto :eof
where /q ffmpeg || echo 未找到ffmpeg. && goto :eof
where /q ffprobe || echo 未找到ffprobe(请下载安装完整ffmpeg^). && goto :eof

set HIRES=
set RESIZE=
set REFINE=
set DENOISE=
set isAMDNAVI=False

if "%%1"=="" (
    echo 请输入视频文件地址：
    set /p FILE=
) else (
    set FILE=%1
)
for %%i in (%FILE%) do (
    set FNAME=%%~dpni
)

ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=nw=1:nk=1 %FILE% > "%FNAME%.hinfo"
set /p HEIGHT=<"%FNAME%.hinfo"
del /F /Q "%FNAME%.hinfo"
ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=nw=1:nk=1 %FILE% > "%FNAME%.hinfo"
set /p WIDTH=<"%FNAME%.hinfo"
del /F /Q "%FNAME%.hinfo"
ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 %FILE% > "%FNAME%.hinfo"
set /p FPS=<"%FNAME%.hinfo"
del /F /Q "%FNAME%.hinfo"
python -c "print(round(%FPS%*10-20))" > "%FNAME%.hinfo"
set /p KEYINT=<"%FNAME%.hinfo"
del /F /Q "%FNAME%.hinfo"

if %HEIGHT% GTR 1080 (
    set HIRES=True
    if %HEIGHT% LEQ 1440 (
        choice /m 纵向分辨率超过1080像素，但未超过1440像素，这将不会触发B站的4K选项，是否要拉伸视频到4K分辨率
        if ERRORLEVEL 2 (
            REM
        ) else (
            if ERRORLEVEL 1 (
                set RESIZE=True
            )
        )
    )
)

choice /m 是否需要优化画面
if ERRORLEVEL 2 (
    REM
) else (
    if ERRORLEVEL 1 (
        set REFINE=True
        set DENOISE=True
        choice /m "请问你是否使用AMD NaVi核心的显卡"
        if ERRORLEVEL 2 (
            set isAMDNAVI=False
        ) else (
            if ERRORLEVEL 1 (
                set isAMDNAVI=True
            )
        )
    )
)

(
echo import vapoursynth as vs
echo import havsfunc as haf
echo import mvsfunc as mvf
echo.
echo core = vs.get_core(^)
echo core.num_threads = %NUMBER_OF_PROCESSORS%
echo core.max_cache_size = %NUMBER_OF_PROCESSORS%*1000
echo.
echo file = r"%FILE%"
echo __AMD = %isAMDNAVI%
echo.
echo def Denoise16(src16, isAMDNAVI=False^):
echo     __strength = 2.0
echo     if isAMDNAVI:
echo         src16 = mvf.ToRGB(src16, full=True, depth=16^)
echo         denoise = core.knlm.KNLMeansCL(src16,h=__strength,s=3,d=2,a=2,channels="RGB"^)
echo         denoise = mvf.ToYUV(denoise, full=True, css="420", depth=16^)
echo     else:
echo         denoise = core.knlm.KNLMeansCL(src16,h=__strength,s=3,d=2,a=2,channels="Y"^)
echo     return denoise
echo.
echo def Deband16(src16^):
echo     pass1 = core.f3kdb.Deband(src16,8,64,48,48,0,0,output_depth=16^)
echo     pass2 = core.f3kdb.Deband(pass1,8,64,48,48,0,0,output_depth=16^)
echo     return mvf.LimitFilter(pass2, src16, thr=0.4, thrc=0.3, elast=3.0^)
echo.
echo src = core.lsmas.LWLibavSource(source=file^)
echo src16 = core.fmtc.bitdepth(src,bits=16^)
if defined RESIZE (
    echo.
    echo import nnedi3_rpow2
    echo src16 = nnedi3_rpow2.nnedi3_rpow2(src16^)
    echo src16 = core.fmtc.resample(src16, w=round(2160*%WIDTH%/%HEIGHT%^), h=2160^)
)
echo.
if defined REFINE (
    if defined DENOISE (
        echo denoise = Denoise16(src16, isAMDNAVI=__AMD^)
        echo deblock = core.deblock.Deblock(denoise, quant=15^)
    ) else (
        echo deblock = core.deblock.Deblock(src16, quant=15^)
    )
    echo tmp = Deband16(deblock^)
) else (
    echo tmp = src16
)
echo.
echo bright = mvf.Depth(tmp, 8, dither=1^)
echo dark = mvf.Depth(tmp, 8, dither=0, ampo=1.5^)
echo fin = core.std.MaskedMerge(dark, bright, core.std.Binarize(bright, 96, planes=0^), first_plane=True^)
echo.
echo fin.set_output(0^)
)>"%FNAME%.vpy"

if defined RESIZE (
    vspipe --y4m "%FNAME%.vpy" - | x264 --demuxer y4m - ^
        --level 5.1 --preset veryslow --deblock 0:0 ^
        --ref 4 --bframes 8 --min-keyint 1 --keyint %KEYINT% ^
        --crf 19 --no-mbtree --b-adapt 2 --me umh --merange 32 ^
        --vbv-bufsize 300000 --vbv-maxrate 58000 ^
        --aq-mode=1 --aq-strength 0.9 --psy-rd 0:0.2 --rc-lookahead 70 --no-fast-pskip ^
        --colormatrix bt709 --fgo 1 -o "%FNAME%.tmp.mkv"
) else (
    vspipe --y4m "%FNAME%.vpy" - | x264 --demuxer y4m - ^
        --level 5.1 --preset veryslow --deblock 0:0 ^
        --ref 12 --bframes 15 --min-keyint 1 --keyint %KEYINT% ^
        --bitrate 5960 --no-mbtree --b-adapt 2 --me umh --merange 32 ^
        --vbv-bufsize 300000 --vbv-maxrate 22000 ^
        --aq-mode=1 --aq-strength 0.9 --psy-rd 0:0.2 --rc-lookahead 70 --no-fast-pskip ^
        --colormatrix bt709 --fgo 1 -o "%FNAME%.pass1.mkv" --pass 1 --slow-firstpass --stats "%FNAME%.stats"
    vspipe --y4m "%FNAME%.vpy" - | x264 --demuxer y4m - ^
        --level 5.1 --preset veryslow --deblock 0:0 ^
        --ref 12 --bframes 15 --min-keyint 1 --keyint %KEYINT% ^
        --bitrate 5960 --no-mbtree --b-adapt 2 --me umh --merange 32 ^
        --vbv-bufsize 300000 --vbv-maxrate 22000 ^
        --aq-mode=1 --aq-strength 0.9 --psy-rd 0:0.2 --rc-lookahead 70 --no-fast-pskip ^
        --colormatrix bt709 --fgo 1 --pass 2 --stats "%FNAME%.stats" -o "%FNAME%.pass2.mkv"
    del /F /Q "%FNAME%.stats"
    del /F /Q "%FNAME%.pass1.mkv"
    move "%FNAME%.pass2.mkv" "%FNAME%.tmp.mkv">nul
)

ffmpeg -i "%FILE%" -vn -c copy "%FNAME%.m4a"
ffmpeg -i "%FNAME%.tmp.mkv" -i "%FNAME%.m4a" -c copy "%FNAME%.fin.mp4"
del /F /Q "%FILE%.lwi"
del /F /Q "%FNAME%.vpy"
del /F /Q "%FNAME%.m4a"
del /F /Q "%FNAME%.tmp.mkv"

pause
