@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem Se placer dans le dossier du script (indispensable si lance "en tant qu'administrateur")
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

rem --- Journal : un fichier par poste dans le dossier logs ---
if not exist logs mkdir logs
set "LOG=%~dp0logs\%ComputerName%.log"
>>"%LOG%" echo.
>>"%LOG%" echo ===== Installation eleve - %DATE% %TIME% - %ComputerName% =====

set "ETAPE=Copie de la configuration"
echo %ETAPE%...
xcopy config\config.json "%ProgramData%\Veyon\" /R /H /Y >>"%LOG%" 2>&1
if errorlevel 1 goto :echec

set "ETAPE=Installation de Veyon"
echo %ETAPE%, patientez...
start "" /wait veyon-setup.exe /S /NoMaster /ApplyConfig="%ProgramData%\Veyon\config.json"
if errorlevel 1 goto :echec

set "ETAPE=Copie des cles"
echo %ETAPE%...
xcopy config\cles_eleves "%ProgramData%\Veyon\" /S /E /R /H /Y >>"%LOG%" 2>&1
if errorlevel 1 goto :echec

set "ETAPE=Redemarrage du service Veyon"
echo %ETAPE%...
net stop VeyonService >>"%LOG%" 2>&1
net start VeyonService >>"%LOG%" 2>&1
if errorlevel 1 goto :echec

>>"%LOG%" echo Installation OK
echo.
echo ############################################
echo Nom Windows de l'ordinateur : %ComputerName%
echo ############################################
echo.

rem --- Nom affiche dans Veyon (le nom Windows n'est PAS modifie) ---
rem Nomenclature : SALLE-PC01, SALLE-PC02, ...
rem Les postes sont enregistres dans postes.csv, a cote de ce script.
rem Ce fichier sera ensuite importe sur le poste prof avec importer_postes_veyon.bat
rem Format d'une ligne : nom Windows;salle;nom affiche
set "SALLE="
set "NOM_AFFICHE="
set "MAX=0"

rem Lecture du CSV existant : salle de la derniere ligne, et ce poste y est-il deja ?
if exist postes.csv (
    for /f "usebackq tokens=1-3 delims=;" %%a in ("postes.csv") do (
        set "SALLE=%%b"
        if /i "%%a"=="%ComputerName%" set "NOM_AFFICHE=%%c"
    )
)

rem Premier lancement : on demande la salle
if not defined SALLE (
    echo Premier poste : indiquez la salle.
    echo Caracteres autorises : lettres sans accent, chiffres, espace, point, - et _
    call :demander SALLE "Salle, ex : S12"
)

if defined NOM_AFFICHE (
    rem Reinstallation : le poste garde son nom, rien n'est ajoute au CSV
    echo Ce poste est deja enregistre : il garde son nom.
    >>"%LOG%" echo Reinstallation, nom conserve : !NOM_AFFICHE!
) else (
    rem Plus grand numero deja utilise dans cette salle
    if exist postes.csv (
        for /f "usebackq tokens=1-3 delims=;" %%a in ("postes.csv") do (
            if /i "%%b"=="!SALLE!" call :numero "%%c"
        )
    )
    set /a SUIVANT=MAX+1
    if !SUIVANT! lss 10 (set "NUM=0!SUIVANT!") else (set "NUM=!SUIVANT!")
    set "NOM_AFFICHE=!SALLE!-PC!NUM!"

    set "ETAPE=Enregistrement dans postes.csv"
    >>postes.csv echo %ComputerName%;!SALLE!;!NOM_AFFICHE!
    if errorlevel 1 goto :echec
    >>"%LOG%" echo Nom affiche : !NOM_AFFICHE! - Salle : !SALLE!
)

color 2F
echo.
echo ############################################
echo  INSTALLATION TERMINEE
echo  %ComputerName% sera affiche "!NOM_AFFICHE!" dans "!SALLE!"
echo ############################################
pause
exit /b 0


rem ==========================================================
rem  Pose une question et refuse les caracteres non autorises
rem  %1 = variable a remplir, %2 = question
rem ==========================================================
:demander
set "SAISIE="
set /p "SAISIE=%~2 : "
if not defined SAISIE goto :demander
>"%TEMP%\veyon_saisie.txt" echo(!SAISIE!
findstr /r /x /c:"[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ._-]*" "%TEMP%\veyon_saisie.txt" >nul
if errorlevel 1 (
    echo   Caracteres non autorises, recommencez.
    goto :demander
)
set "%~1=!SAISIE!"
exit /b 0


rem ==========================================================
rem  Lit le numero d'un nom du type SALLE-PC07 et met a jour MAX
rem  %1 = nom affiche
rem ==========================================================
:numero
set "N=%~1"
rem Garde ce qui suit "-PC" (si absent, le nom est ignore)
if "!N:*-PC=!"=="!N!" exit /b 0
set "N=!N:*-PC=!"
rem Retire les zeros de tete (sinon 08 et 09 sont mal compris)
:numero_zeros
if not "!N:~0,1!"=="0" goto :numero_suite
if "!N!"=="0" goto :numero_suite
set "N=!N:~1!"
goto :numero_zeros
:numero_suite
if not defined N exit /b 0
rem Ignore si ce n'est pas uniquement des chiffres
for /f "delims=0123456789" %%x in ("!N!") do exit /b 0
if !N! gtr !MAX! set "MAX=!N!"
exit /b 0


:echec
color 4F
>>"%LOG%" echo ECHEC : %ETAPE%
echo.
echo ############################################
echo  ECHEC : %ETAPE%
echo  Details dans le journal :
echo  %LOG%
echo ############################################
pause
exit /b 1
