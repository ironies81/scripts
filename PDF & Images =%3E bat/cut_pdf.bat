@echo off
setlocal ENABLEDELAYEDEXPANSION

:: Vérifier si un fichier a été passé en argument
if "%~1"=="" (
    echo Aucun fichier sélectionné.
    pause
    exit /b
)

:: Récupérer le chemin complet, le dossier et le nom du fichier sans extension
set "PDF_FILE=%~1"
set "PDF_DIR=%~dp1"
set "PDF_NAME=%~n1"
set "OUTPUT_DIR=%PDF_DIR%%PDF_NAME%"

:: Créer un dossier portant le nom du PDF
mkdir "%OUTPUT_DIR%" 2>nul

:: Découper chaque page et renommer correctement
pdftk "%PDF_FILE%" burst output "%OUTPUT_DIR%\temp_%%02d.pdf"

:: Renommer chaque page avec le bon format "NomOrigine_page_XX.pdf"
for %%F in ("%OUTPUT_DIR%\temp_*.pdf") do (
    set "OLD_NAME=%%~nxF"
    set "PAGE_NUM=%%~nF"
    set "PAGE_NUM=!PAGE_NUM:temp_=!"
    ren "%%F" "%PDF_NAME%_page_!PAGE_NUM!.pdf"
)

echo Decoupage termine. Les fichiers sont dans "%OUTPUT_DIR%"
endlocal
