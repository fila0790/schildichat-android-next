@echo off
setlocal enabledelayedexpansion

:: Sicherstellen, dass das Skript im eigenen Ordner ausgefuehrt wird
cd /d "%~dp0"

echo ===================================================
echo SchildiChat Next - Vollautomatisches Update ^& Build
echo ===================================================
echo.

:: 1. Updates vom Original (Upstream) abrufen
echo [1/5] Suche nach Updates vom Original (SchildiChat upstream)...
git fetch upstream
if !errorlevel! neq 0 (
    echo.
    echo [FEHLER] Konnte keine Daten von upstream abrufen. Internetverbindung oder Remote pruefen!
    echo.
    pause
    exit /b 1
)

:: 2. Pruefen ob neue Commits vorhanden sind
set "NEED_BUILD=0"
set "BEHIND_COUNT=0"
for /f "delims=" %%i in ('git rev-list HEAD..upstream/main --count 2^>nul') do set "BEHIND_COUNT=%%i"

if "!BEHIND_COUNT!"=="0" (
    echo Kein neues Update bei SchildiChat verfuegbar ^(Stand ist aktuell^).
    set "USER_CHOICE="
    set /p USER_CHOICE="Moechtest du die App trotzdem neu bauen und pushen? (j/n): "
    if /i "!USER_CHOICE!"=="j" (
        set "NEED_BUILD=1"
    ) else (
        echo Vorgang beendet.
        pause
        exit /b 0
    )
) else (
    echo Es gibt !BEHIND_COUNT! neue^(s^) Update^(s^) von SchildiChat!
    set "NEED_BUILD=1"
)

:: 3. Rebase: Upstream-Aenderungen einpflegen, eigene Anpassung oben drauf halten
echo.
echo [2/5] Wende SchildiChat-Updates an und uebernehme deine Anpassung...
git rebase upstream/main
if !errorlevel! neq 0 (
    echo.
    echo [KONFLIKT] Beim Zusammenfuehren gab es einen Versionskonflikt.
    echo Bitte Konflikte pruefen oder mit 'git rebase --abort' abbrechen.
    echo.
    pause
    exit /b 1
)

:: 4. Aktualisierten Stand in dein GitHub-Repo pushen
echo.
echo [3/5] Pushe den neuen Stand in dein GitHub-Repository (origin)...
git push origin main --force-with-lease
if !errorlevel! neq 0 (
    echo.
    echo [WARNUNG] Push zu GitHub fehlgeschlagen oder Berechtigung verweigert.
    echo Der lokale Build wird trotzdem fortgesetzt...
)

:: 5. APK automatisch bauen
echo.
echo [4/5] Baue die neue App-Version (APK)...
echo (Dies kann ein paar Minuten dauern)...
echo.
call gradlew.bat :app:assembleFdroidScDefaultDebug
if !errorlevel! neq 0 (
    echo.
    echo [FEHLER] Der Build-Vorgang ist fehlgeschlagen!
    echo.
    pause
    exit /b 1
)

:: 6. APK in Zielordner kopieren und bereitstellen
echo.
echo [5/5] Bereite fertige APK vor...
set "OUTPUT_DIR=%~dp0Fertige_APK"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

set "SRC_APK=%~dp0app\build\outputs\apk\fdroidScDefault\debug\app-fdroid-sc-default-universal.apk"
if exist "%SRC_APK%" (
    copy /y "%SRC_APK%" "%OUTPUT_DIR%\SchildiChat-Next-Universal.apk" >nul
    echo.
    echo ===================================================
    echo ERFOLG: Neue App-Version wurde erfolgreich gebaut!
    echo Datei: %OUTPUT_DIR%\SchildiChat-Next-Universal.apk
    echo ===================================================

    :: Pruefen ob ein Smartphone per USB/ADB verbunden ist
    adb devices 2>nul | findstr /r /c:"[0-9a-zA-Z][ 	]*device$" >nul
    if !errorlevel! equ 0 (
        echo.
        echo Smartphone per USB erkannt!
        set "INSTALL_CHOICE="
        set /p INSTALL_CHOICE="Moechtest du die APK direkt auf dem Handy installieren? (j/n): "
        if /i "!INSTALL_CHOICE!"=="j" (
            echo Installiere Update auf Smartphone...
            adb install -r "%OUTPUT_DIR%\SchildiChat-Next-Universal.apk"
            if !errorlevel! equ 0 (
                echo Installation erfolgreich!
            ) else (
                echo [HINWEIS] Installation per ADB fehlgeschlagen. Bitte manuell installieren.
            )
        )
    )

    :: Ordner mit der fertigen APK im Windows Explorer oeffnen
    explorer "%OUTPUT_DIR%"
) else (
    echo [FEHLER] Die generierte APK wurde nicht im erwarteten Pfad gefunden:
    echo %SRC_APK%
)

echo.
echo Alles erledigt!
pause
