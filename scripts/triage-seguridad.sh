#!/bin/bash
# ============================================
# TRIAJE DE SEGURIDAD
# Autor: fraancovidela
# ============================================

if [ -t 1 ]; then
    ROJO=$'\033[0;31m'
    VERDE=$'\033[0;32m'
    AMARILLO=$'\033[1;33m'
    AZUL=$'\033[0;34m'
    RESET=$'\033[0m'
else
    ROJO=''
    VERDE=''
    AMARILLO=''
    AZUL=''
    RESET=''
fi

REPORTE=~/scripts/reporte_triaje_$(date +%Y-%m-%d_%H-%M-%S).txt
DESTINO="your_email@example.com" 

ejecutar_triaje() {

echo "=============================="
echo " TRIAJE DE SEGURIDAD - INICIO"
echo "=============================="
echo ""
echo "Sistema: $(hostname)"
echo "Fecha:   $(date)"
echo "Usuario: $(whoami)"
echo ""

echo "=============================="
echo " [1] USUARIOS CONECTADOS"
echo "=============================="
w
echo ""

echo "=============================="
echo " [2] ULTIMOS LOGINS"
echo "=============================="
last | head -10
echo ""

echo "=============================="
echo " [3] PROCESOS SOSPECHOSOS"
echo "=============================="
echo "--- Top 10 por CPU ---"
ps aux --sort=-%cpu | head -11
echo ""
echo "--- Procesos con binario borrado del disco ---"
BORRADOS=$(ls -la /proc/*/exe 2>/dev/null | grep deleted)
if [ -z "$BORRADOS" ]; then
    echo "[OK] Sin binarios borrados en memoria"
else
    echo "[ALERTA] Binarios borrados con proceso activo:"
    echo "$BORRADOS"
fi
echo ""

echo "=============================="
echo " [4] CONEXIONES DE RED"
echo "=============================="
echo "--- Puertos en escucha ---"
ss -lntp
echo ""
echo "--- Conexiones activas hacia exterior ---"
EXTERNAS=$(ss -tnp state established | grep -v -E "127\.0\.0|::1")
if [ -z "$EXTERNAS" ]; then
    echo "[OK] Sin conexiones activas hacia exterior"
else
    echo "[INFO] Conexiones activas:"
    echo "$EXTERNAS"
fi
echo ""
echo "--- Puertos sospechosos en escucha ---"
SOSPECHOSO_RED=$(ss -lntp | grep -v -E ":22|:53|:631|:80|:443" | grep LISTEN)
if [ -z "$SOSPECHOSO_RED" ]; then
    echo "[OK] Sin puertos sospechosos"
else
    echo "[ALERTA] Puerto no reconocido en escucha:"
    echo "$SOSPECHOSO_RED"
fi
echo ""

echo "=============================="
echo " [5] EJECUTABLES EN /tmp"
echo "=============================="
SOSPECHOSOS=$(find /tmp /var/tmp /dev/shm -type f -executable 2>/dev/null)
if [ -z "$SOSPECHOSOS" ]; then
    echo "[OK] Sin ejecutables en directorios temporales"
else
    echo "[ALERTA] Ejecutables encontrados:"
    echo "$SOSPECHOSOS"
fi
echo ""

echo "=============================="
echo " [6] BINARIOS SUID"
echo "=============================="
SUID=$(find / -perm -4000 -type f 2>/dev/null | grep -v -E "^/usr/bin|^/usr/lib|^/usr/sbin|^/snap|^/bin|^/sbin|^/opt/VBox")
if [ -z "$SUID" ]; then
    echo "[OK] Sin SUID en rutas sospechosas"
else
    echo "[ALERTA] SUID en ruta inusual:"
    echo "$SUID"
fi
echo ""

echo "=============================="
echo " [7] REVISION DE CRON"
echo "=============================="
CRON_SOSPECHOSO=$(crontab -l 2>/dev/null | grep -v "^#" | grep -E "curl|wget|bash|/tmp|base64|nc ")
if [ -z "$CRON_SOSPECHOSO" ]; then
    echo "[OK] Sin comandos sospechosos en crontab"
else
    echo "[ALERTA] Cron sospechoso detectado:"
    echo "$CRON_SOSPECHOSO"
fi
echo ""

echo "=============================="
echo " TRIAJE FINALIZADO"
echo "=============================="

}

# Ejecutar triaje, guardar reporte y mostrar en pantalla con colores
ejecutar_triaje | tee "$REPORTE"

# Enviar reporte por email
ASUNTO="[TRIAJE] $(hostname) - $(date +%Y-%m-%d_%H:%M)"
cat "$REPORTE" | msmtp "$DESTINO"

if [ $? -eq 0 ]; then
    echo -e "${VERDE}[OK] Reporte enviado a $DESTINO${RESET}"
else
    echo -e "${ROJO}[ERROR] No se pudo enviar el reporte${RESET}"
fi
