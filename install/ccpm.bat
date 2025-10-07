@echo off

set REPO_URL=https://github.com/automazeio/ccpm.git
set TEMP_DIR=temp-ccpm-%RANDOM%
set TARGET_DIR=.claude

echo Installing CCPM to %TARGET_DIR%...

REM Check if .claude already exists
if exist "%TARGET_DIR%" (
    echo Warning: %TARGET_DIR% already exists.
    set /p REPLY="Backup and replace? (y/N): "
    if /i not "%REPLY%"=="y" (
        echo Installation cancelled.
        exit /b 0
    )
    REM Backup existing .claude
    set BACKUP_DIR=.claude.backup.%RANDOM%
    echo Backing up to %BACKUP_DIR%...
    move "%TARGET_DIR%" "%BACKUP_DIR%" >nul
)

REM Clone to temporary directory
echo Cloning repository...
git clone %REPO_URL% %TEMP_DIR%

if %ERRORLEVEL% EQU 0 (
    echo Clone successful. Installing files...

    REM Copy ccpm directory to .claude
    xcopy /E /I /Q "%TEMP_DIR%\ccpm" "%TARGET_DIR%" >nul

    REM Clean up
    rmdir /s /q "%TEMP_DIR%" 2>nul

    echo.
    echo ✅ CCPM installed successfully to %TARGET_DIR%\
    echo.
    echo Next steps:
    echo   1. Run: /pm:init
    echo   2. Follow the initialization prompts
    echo.
) else (
    echo ❌ Error: Failed to clone repository.
    exit /b 1
)
