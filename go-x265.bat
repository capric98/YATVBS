@echo off
set FILE=%~dpn1

vspipe --y4m "%1" - | x265 --input-depth 16 --y4m - --profile main10 --pools + --pmode --ctu 32 --min-cu-size 8 --tu-intra-depth 3 --tu-inter-depth 2 --limit-tu 2 --limit-refs 0 --rd 5 --psy-rd 0.8 --rdoq-level 2 --psy-rdoq 1.6 --ssim-rd --max-merge 4 --ref 4 --me 3 --subme 5 --merange 32 --rect --amp --limit-modes --keyint 240 --rc-lookahead 50 --bframes 6 --crf 20 --colormatrix bt709 -o "%FILE%.mkv"

pause
