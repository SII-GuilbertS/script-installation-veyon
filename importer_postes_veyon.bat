@echo off
rem A lancer EN TANT QU'ADMINISTRATEUR sur le poste prof (Veyon Master installe).
rem Importe postes.csv (rempli par install_veyon_eleves.bat) dans la liste des
rem salles et ordinateurs de Veyon, avec les noms affiches choisis.
cd /d "%~dp0"

set "VEYONCLI=%ProgramFiles%\Veyon\veyon-cli.exe"

if not exist "%VEYONCLI%" (
    echo Veyon n'est pas installe sur ce poste : %VEYONCLI% introuvable.
    pause
    exit /b 1
)
if not exist postes.csv (
    echo Fichier postes.csv introuvable a cote de ce script.
    pause
    exit /b 1
)

echo Postes a importer :
echo ------------------------------------------
type postes.csv
echo ------------------------------------------
echo.
echo ATTENTION : la liste actuelle des salles et ordinateurs de Veyon
echo sur ce poste va etre remplacee par le contenu de postes.csv.
choice /c ON /m "Continuer"
if errorlevel 2 exit /b 0

"%VEYONCLI%" networkobjects clear
"%VEYONCLI%" networkobjects import postes.csv format "%%host%%;%%location%%;%%name%%"

echo.
echo Resultat :
"%VEYONCLI%" networkobjects list
pause
