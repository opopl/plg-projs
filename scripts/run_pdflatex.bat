@echo off

set Bin=%~dp0
perl %Bin%\run_pdflatex.pl %*
