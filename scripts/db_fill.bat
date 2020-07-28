
@echo off

call vars_python_2.bat

set Bin=%~dp0
python %Bin%\db_fill.py %*
