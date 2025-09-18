@Echo Off
Title Reg Converter v1.2 & Color 1A
cd %systemroot%\system32
call :IsAdmin

Reg.exe add "HKCR\*\shell\DecouperPDF" /ve /t REG_SZ /d "Découper ce PDF" /f
Reg.exe add "HKCR\*\shell\DecouperPDF\command" /ve /t REG_SZ /d "\"C:\_install\cut_pdf.bat\" \"%%1\"" /f
Exit

:IsAdmin
Reg.exe query "HKU\S-1-5-19\Environment"
If Not %ERRORLEVEL% EQU 0 (
 Cls & Echo You must have administrator rights to continue ... 
 Pause & Exit
)
Cls
goto:eof

cd %systemroot%\system32
call :IsAdmin

Reg.exe add "HKCR\*\shell\Image2PDF" /ve /t REG_SZ /d "Convertir l'image en PDF" /f
Reg.exe add "HKCR\*\shell\Image2PDF\command" /ve /t REG_SZ /d "\"C:\_install\img2pdf.bat\" \"%%1\"" /f
Exit

:IsAdmin
Reg.exe query "HKU\S-1-5-19\Environment"
If Not %ERRORLEVEL% EQU 0 (
 Cls & Echo You must have administrator rights to continue ... 
 Pause & Exit
)
Cls
goto:eof
exit