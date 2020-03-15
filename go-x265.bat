@echo off
set FILE=%~dpn1

vspipe --y4m "%1" - | x265 --input-depth 16 --y4m - --profile main10 --pools + --pmode --ctu 32 --min-cu-size 8 --tu-intra-depth 3 --tu-inter-depth 2 --limit-tu 2 --limit-refs 0 --rd 5 --aq-strength 0.80 --psy-rd 1.8 --rdoq-level 2 --psy-rdoq 1.5 --ssim-rd --max-merge 4 --ref 4 --me 3 --subme 5 --merange 32 --rect --amp --limit-modes --min-keyint 1 --keyint 240 --rc-lookahead 70 --bframes 8 --crf 20 --dither --colormatrix bt709 -o "%FILE%.mkv"

pause
