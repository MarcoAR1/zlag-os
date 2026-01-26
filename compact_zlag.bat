@echo off
setlocal enabledelayedexpansion

echo ====================================================
echo 🛡️  ZLAG AUTOMATIC DISK COMPACTOR
echo ====================================================

echo [1/3] Cerrando instancias de WSL...
wsl --shutdown

echo [2/3] Buscando archivos de disco vhdx...
:: Usamos PowerShell para encontrar las rutas de los discos instalados
set "SEARCH_CMD=Get-ChildItem -Path $env:LOCALAPPDATA\Packages -Filter ext4.vhdx -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName"

for /f "delims=" %%i in ('powershell -Command "%SEARCH_CMD%"') do (
    set "VHDX_PATH=%%i"
    echo 📍 Encontrado: !VHDX_PATH!
    
    echo [3/3] Compactando disco...
    echo select vdisk file="!VHDX_PATH!" > %temp%\diskpart_script.txt
    echo attach vdisk readonly >> %temp%\diskpart_script.txt
    echo compact vdisk >> %temp%\diskpart_script.txt
    echo detach vdisk >> %temp%\diskpart_script.txt
    
    :: Ejecuta diskpart con el script generado para esta ruta
    powershell -Command "Start-Process diskpart -ArgumentList '/s %temp%\diskpart_script.txt' -Verb RunAs -Wait"
    
    if !errorlevel! equ 0 (
        echo ✅ Compactacion exitosa para: !VHDX_PATH!
    ) else (
        echo ❌ Error al compactar: !VHDX_PATH!
    )
    del %temp%\diskpart_script.txt
)

echo ====================================================
echo 🎉 PROCESO TERMINADO - Espacio recuperado
echo ====================================================
pause