@echo off
echo ===================================================
echo SchildiChat Next - Update von Upstream holen
echo ===================================================
echo.

echo 1. Pruefe auf Updates von SchildiChat Next (upstream)...
git fetch upstream
if %errorlevel% neq 0 (
    echo.
    echo [FEHLER] Konnte keine Daten vom Upstream-Repository laden.
    echo Bitte Internetverbindung pruefen.
    echo.
    pause
    exit /b %errorlevel%
)

echo 2. Wende Updates an und uebernehme eigene Anpassungen...
git rebase upstream/main
if %errorlevel% neq 0 (
    echo.
    echo [HINWEIS] Beim automatischen Zusammenfuehren gab es einen Konflikt.
    echo Mit 'git rebase --abort' koennen Sie zum vorherigen Stand zurueckkehren.
    echo.
    pause
    exit /b %errorlevel%
)

echo.
echo ===================================================
echo ERFOLG: Update wurde vollstaendig eingespielt!
echo Die Warnungen bleiben weiterhin ausgeblendet.
echo ===================================================
echo.
pause
