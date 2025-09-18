@echo off
setlocal ENABLEDELAYEDEXPANSION

:: Vérifier si un fichier a été passé en argument
if "%~1"=="" (
    echo Aucun fichier sélectionné.
    pause
    exit /b
)

:: Récupérer les informations du fichier image
set "IMG_FILE=%~1"
set "IMG_DIR=%~dp1"
set "IMG_NAME=%~n1"
set "OUTPUT_DIR=%IMG_DIR%%IMG_NAME%"

:: Créer un dossier portant le nom de l'image
mkdir "%OUTPUT_DIR%" 2>nul

:: Convertir l'image en PDF dans ce dossier
magick "%IMG_FILE%" "%OUTPUT_DIR%\%IMG_NAME%.pdf"

echo Conversion terminée. Le fichier est dans "%OUTPUT_DIR%"
endlocal
timeout /t 5
exit