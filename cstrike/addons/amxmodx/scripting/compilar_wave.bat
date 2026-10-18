@echo off
title Compilador AMX Mod X - Wave Survival Co-op
echo ==============================================
echo   Compilando wave_survival.sma ...
echo ==============================================
amxxpc.exe wave_survival.sma -o..\plugins\wave_survival.amxx
echo.
if %ERRORLEVEL% EQU 0 (
    echo [EXITO] Plugin compilado y copiado a addons\amxmodx\plugins\wave_survival.amxx
) else (
    echo [ERROR] Hubo un error al compilar el codigo.
)
echo.
pause
