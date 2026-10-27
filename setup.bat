@echo off
SETLOCAL EnableDelayedExpansion

echo ===============================================
echo     METANODE FINSDK PROJECT SETUP (Windows)   
echo ===============================================
echo.
echo [WARN] This project uses pnpm ONLY.
echo [WARN] Do NOT run "npm install" or "yarn" — that causes .ignored / EPERM errors.
echo.

:: 1. Check Node.js
echo [INFO] Checking Node.js version...
where node >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Node.js is not installed! Please install Node.js (version >= 18) and try again.
    goto error
)

for /f "tokens=1,2,3 delims=." %%a in ('node -v') do (
    set "version=%%a"
    set "NODE_MAJOR=!version:~1!"
)

if !NODE_MAJOR! lss 18 (
    echo [ERROR] Your Node.js version is older than v18. Version >= 18 is required.
    goto error
)
echo [SUCCESS] Node.js v!NODE_MAJOR! detected.

:: 2. Check pnpm
echo [INFO] Checking pnpm...
where pnpm >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [WARN] pnpm is not installed. Attempting to install pnpm via corepack...
    where corepack >nul 2>nul
    if !ERRORLEVEL! eq 0 (
        call corepack enable
        call corepack prepare pnpm@9.0.0 --activate
    ) else (
        echo [WARN] Corepack is not available. Attempting npm global install...
        call npm install -g pnpm@9.0.0
    )
)

where pnpm >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Could not install pnpm automatically. Please install pnpm manually (npm install -g pnpm) and rerun.
    goto error
)
echo [SUCCESS] pnpm detected.

:: 3. Setup Env Files
echo [INFO] Configuring environment files...
if exist .env.example (
    if not exist .env.development (
        copy .env.example .env.development >nul
        echo [SUCCESS] Created .env.development from template.
    ) else (
        echo [INFO] .env.development already exists, skipping.
    )

    if not exist .env.production (
        copy .env.example .env.production >nul
        echo [SUCCESS] Created .env.production from template.
    ) else (
        echo [INFO] .env.production already exists, skipping.
    )
) else (
    echo [WARN] .env.example not found. Cannot auto-generate environment files.
)

:: 4. Stop processes that lock node_modules, remove npm/yarn leftovers, clean install trees
echo [INFO] Releasing file locks...
taskkill /F /IM node.exe >nul 2>nul
taskkill /F /IM esbuild.exe >nul 2>nul
timeout /t 2 /nobreak >nul

echo [INFO] Removing foreign lockfiles (npm/yarn) if present...
call :remove_foreign_locks .
for /d %%d in (apps\* frames\* packages\*) do (
    if exist "%%d" call :remove_foreign_locks "%%d"
)

echo [INFO] Cleaning node_modules (including .ignored from mixed package managers)...
call :clean_node_modules .
for /d %%d in (apps\* frames\* packages\*) do (
    if exist "%%d" call :clean_node_modules "%%d"
)

:: Verify connect-wallet is fully gone (most common EPERM path)
if exist "apps\connect-wallet\node_modules" (
    echo [WARN] apps\connect-wallet\node_modules still exists — forcing remove...
    call :force_remove_dir "apps\connect-wallet\node_modules"
)
if exist "apps\connect-wallet\node_modules" (
    echo [ERROR] Cannot delete apps\connect-wallet\node_modules
    echo [HINT] 1^) Close Cursor/VS Code completely
    echo [HINT] 2^) Open CMD as Administrator in C:\metanode-sdk
    echo [HINT] 3^) Run: rmdir /s /q apps\connect-wallet\node_modules
    echo [HINT] 4^) Rerun setup.bat — never use npm install in this repo
    goto error
)
echo [SUCCESS] Cleanup completed.

:: 5. Install dependencies (retry once on EPERM)
echo [INFO] Installing dependencies with pnpm...
set "npm_config_package_import_method=clone-or-copy"
call pnpm install
if %ERRORLEVEL% neq 0 (
    echo [WARN] First install failed. Retrying after another cleanup...
    taskkill /F /IM node.exe >nul 2>nul
    timeout /t 2 /nobreak >nul
    call :clean_node_modules .
    for /d %%d in (apps\* frames\* packages\*) do (
        if exist "%%d" call :clean_node_modules "%%d"
    )
    call pnpm install --force
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Dependency installation failed.
        echo [HINT] Close Cursor/VS Code, exclude C:\metanode-sdk from Windows Defender, then rerun setup.bat
        echo [HINT] Cause is often leftover npm node_modules — never run npm install here
        goto error
    )
)
echo [SUCCESS] Dependencies installed successfully.

:: 6. Build workspace packages
echo [INFO] Building workspace packages...
call pnpm --filter @metanodejs/bls-crypto --filter @metanodejs/meta-proto --filter @metanodejs/fiai-sdk build
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to build workspace packages.
    goto error
)
echo [SUCCESS] Workspace packages built successfully.

echo.
echo ===============================================
echo     SETUP COMPLETED SUCCESSFULLY!              
echo ===============================================
echo.
echo You can now start the development server using:
echo   pnpm dev
echo.

set /p START_DEV="Do you want to start the development server now? (y/n): "
if /I "%START_DEV%"=="y" (
    echo [INFO] Starting development server...
    call pnpm dev
)
goto end

:remove_foreign_locks
set "TARGET=%~1"
if exist "%TARGET%\package-lock.json" (
    echo [WARN] Deleting %TARGET%\package-lock.json ^(npm leftover^)
    del /f /q "%TARGET%\package-lock.json" >nul 2>nul
)
if exist "%TARGET%\yarn.lock" (
    echo [WARN] Deleting %TARGET%\yarn.lock ^(yarn leftover^)
    del /f /q "%TARGET%\yarn.lock" >nul 2>nul
)
if exist "%TARGET%\npm-shrinkwrap.json" (
    del /f /q "%TARGET%\npm-shrinkwrap.json" >nul 2>nul
)
goto :eof

:clean_node_modules
set "TARGET=%~1"
if exist "%TARGET%\node_modules" (
    echo [INFO] Removing %TARGET%\node_modules ...
    call :force_remove_dir "%TARGET%\node_modules"
)
goto :eof

:force_remove_dir
set "DIR=%~1"
if not exist "%DIR%" goto :eof
:: Standard delete
rmdir /s /q "%DIR%" 2>nul
if not exist "%DIR%" goto :eof
:: PowerShell fallback
powershell -NoProfile -ExecutionPolicy Bypass -Command "Remove-Item -LiteralPath '%DIR%' -Recurse -Force -ErrorAction SilentlyContinue" >nul 2>nul
if not exist "%DIR%" goto :eof
:: robocopy mirror empty dir (most reliable on Windows for locked trees)
set "EMPTY=%TEMP%\metanode_empty_nm"
if exist "%EMPTY%" rmdir /s /q "%EMPTY%" 2>nul
mkdir "%EMPTY%" >nul 2>nul
robocopy "%EMPTY%" "%DIR%" /mir /r:1 /w:1 >nul 2>nul
rmdir /s /q "%DIR%" 2>nul
rmdir /s /q "%EMPTY%" 2>nul
goto :eof

:error
echo [ERROR] Setup failed!
exit /b 1

:end
ENDLOCAL
pause
