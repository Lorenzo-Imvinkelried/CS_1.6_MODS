@echo off
title Compilador AMX Mod X - Crazy Powers Mod
echo ==============================================
echo   Compilando crazy_powers.sma ...
echo ==============================================
amxxpc.exe crazy_powers.sma -o..\plugins\crazy_powers.amxx
echo.
if %ERRORLEVEL% EQU 0 (
    echo [EXITO] Plugin compilado y copiado a addons\amxmodx\plugins\crazy_powers.amxx
) else (
    echo [ERROR] Hubo un error al compilar el codigo.
)
echo.
pause
