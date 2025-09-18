@echo off
setlocal enabledelayedexpansion

echo. Recupere le chemin du fichier passe en argument
set "input_file=%~1"

echo. Verifie si un fichier a ete passe en argument
if "%input_file%"=="" (
    echo Aucun fichier n'a ete selectionne.
    pause
    exit /b
)

echo. Verifie si le fichier a l'extension .HEIC
set "ext=%~x1"
if /i not "%ext%"==".HEIC" (
    echo Le fichier selectionne n'est pas un fichier HEIC.
    pause
    exit /b
)

echo. Specifie le chemin de sortie en utilisant le meme dossier et le meme nom, mais en .jpg
set "output_file=%~dp1%~n1.jpg"

echo. Effectue la conversion avec ImageMagick
echo Conversion de "%input_file%" vers "%output_file%"...

:: Utiliser la commande magick au lieu de convert
magick "%input_file%" "%output_file%"

:: Verifier si la conversion a reussi
echo. Verifie si la conversion a reussi
if exist "%output_file%" (
    echo Conversion reussie.
) else (
    echo La conversion a echoue.
)

echo. Confirme la fin de la conversion
echo Conversion terminee.
timeout /t 5
exit
