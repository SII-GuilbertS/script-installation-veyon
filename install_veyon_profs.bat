@echo off
setlocal EnableExtensions
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
>>"%LOG%" echo ===== Installation prof - %DATE% %TIME% - %ComputerName% =====

set "ETAPE=Copie de la configuration"
echo %ETAPE%...
xcopy config\config.json "%ProgramData%\Veyon\" /R /H /Y >>"%LOG%" 2>&1
if errorlevel 1 goto :echec

set "ETAPE=Installation de Veyon"
echo %ETAPE%, patientez...
start "" /wait veyon-setup.exe /S /ApplyConfig="%ProgramData%\Veyon\config.json"
if errorlevel 1 goto :echec

set "ETAPE=Copie des cles"
echo %ETAPE%...
xcopy config\cles_profs "%ProgramData%\Veyon\" /S /E /R /H /Y >>"%LOG%" 2>&1
if errorlevel 1 goto :echec

set "ETAPE=Redemarrage du service Veyon"
echo %ETAPE%...
net stop VeyonService >>"%LOG%" 2>&1
net start VeyonService >>"%LOG%" 2>&1
if errorlevel 1 goto :echec

>>"%LOG%" echo Installation OK
color 2F
echo.
echo ############################################
echo  INSTALLATION TERMINEE sur %ComputerName%
echo ############################################
pause
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
