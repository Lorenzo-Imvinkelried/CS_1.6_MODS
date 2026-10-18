@echo off
title Compilador AMX Mod X - Boss Mod
echo ==============================================
echo   Compilando boss_mod.sma ...
echo ==============================================
amxxpc.exe boss_mod.sma -o..\plugins\boss_mod.amxx
echo.
if %ERRORLEVEL% EQU 0 (
    echo [EXITO] Plugin compilado y copiado a addons\amxmodx\plugins\boss_mod.amxx
) else (
    echo [ERROR] Hubo un error al compilar el codigo.
)
echo.
pause
