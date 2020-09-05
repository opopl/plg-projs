
@echo off

set Bin=%~dp0

perl %Bin%\bb_pdflatex.pl %*
