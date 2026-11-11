@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem A lancer EN TANT QU'ADMINISTRATEUR sur le poste prof (Veyon Master installe).
rem Importe dans Veyon tous les fichiers postes*.csv trouves dans ce dossier
rem et ses sous-dossiers (un dossier par salle, par exemple).
rem Format d'une ligne : nom Windows;salle;nom affiche
cd /d "%~dp0"

rem --- Verification des droits administrateur ---
net session >nul 2>&1
if errorlevel 1 (
    color 4F
    echo.
    echo  Ce script doit etre lance EN TANT QU'ADMINISTRATEUR.
    echo  Clic droit sur le fichier, puis "Executer en tant qu'administrateur".
    echo.
    pause
    exit /b 1
)

if not defined VEYONCLI set "VEYONCLI=%ProgramFiles%\Veyon\veyon-cli.exe"
if not exist "%VEYONCLI%" (
    color 4F
    echo Veyon n'est pas installe sur ce poste : %VEYONCLI% introuvable.
    pause
    exit /b 1
)

set "FUSION=%TEMP%\veyon_import.csv"
set "SALLES=%TEMP%\veyon_salles.txt"
type nul > "%FUSION%"
type nul > "%SALLES%"
set /a NB_FICHIERS=0, NB_POSTES=0, NB_DOUBLONS=0

rem --- Rassemble tous les CSV en un seul, sans doublon (un poste = un nom Windows) ---
echo Fichiers trouves :
echo ------------------------------------------
for /r "%~dp0" %%f in (postes*.csv) do (
    set /a NB_FICHIERS+=1
    set /a N=0
    for /f "usebackq tokens=1-3 delims=;" %%a in ("%%f") do (
        findstr /b /i /c:"%%a;" "%FUSION%" >nul
        if errorlevel 1 (
            >>"%FUSION%" echo %%a;%%b;%%c
            set /a N+=1, NB_POSTES+=1
            findstr /x /i /c:"%%b" "%SALLES%" >nul || >>"%SALLES%" echo %%b
        ) else (
            set /a NB_DOUBLONS+=1
        )
    )
    echo   %%f : !N! poste^(s^)
)
echo ------------------------------------------

if !NB_POSTES! equ 0 (
    color 4F
    echo Aucun poste a importer : aucun fichier postes*.csv trouve dans ce dossier.
    pause
    exit /b 1
)

echo.
echo !NB_POSTES! poste^(s^) dans !NB_FICHIERS! fichier^(s^).
if !NB_DOUBLONS! gtr 0 echo !NB_DOUBLONS! doublon^(s^) ignore^(s^) : meme nom Windows dans plusieurs lignes.
echo Salles concernees :
for /f "usebackq delims=" %%s in ("%SALLES%") do echo   - %%s
echo.
echo   A = Ajouter / mettre a jour : seules les salles ci-dessus sont remplacees,
echo       les autres salles deja presentes dans Veyon sont conservees.
echo   R = Remplacer tout : la liste actuelle de Veyon est entierement effacee.
echo   Q = Quitter sans rien changer.
echo.
choice /c ARQ /m "Votre choix"
if errorlevel 3 exit /b 0
if errorlevel 2 goto :remplacer

:ajouter
echo.
echo Mise a jour des salles...
for /f "usebackq delims=" %%s in ("%SALLES%") do (
    rem Supprime la salle et ses postes si elle existe deja, pour eviter les doublons
    call "%VEYONCLI%" networkobjects remove "%%s" >nul 2>&1
)
goto :importer

:remplacer
echo.
echo Effacement de la liste actuelle...
call "%VEYONCLI%" networkobjects clear
if errorlevel 1 goto :echec

:importer
echo Import des postes...
call "%VEYONCLI%" networkobjects import "%FUSION%" format "%%%%host%%%%;%%%%location%%%%;%%%%name%%%%"
if errorlevel 1 goto :echec

color 2F
echo.
echo ############################################
echo  IMPORT TERMINE : !NB_POSTES! poste^(s^)
echo ############################################
echo.
echo Contenu actuel de Veyon :
call "%VEYONCLI%" networkobjects list
pause
exit /b 0

:echec
color 4F
echo.
echo ############################################
echo  ECHEC de la commande veyon-cli ci-dessus.
echo  La liste des postes de Veyon n'est peut-etre pas complete.
echo ############################################
pause
exit /b 1
