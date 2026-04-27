#!/bin/bash
# ============================================
# DETECTOR DE SSH BRUTE FORCE
# Autor: fraancovidela
# ============================================
LOG=$(journalctl --since "1 hour ago" | grep "Invalid user" | grep "sshd")
TOTAL=$(echo "$LOG" | wc -l)
IPS=$(echo "$LOG" | awk '{print $10}' | sort | uniq -c | sort -rn)
USUARIOS=$(echo "$LOG" | awk '{print $8}' | sort | uniq -c | sort -rn)
UMBRAL=10
FECHA=$(date "+%Y-%m-%d_%H-%M-%S")
REPORTE="/home/ciberseguridad/seguridad/reportes/reporte_ssh_$FECHA.txt"
if [ "$TOTAL" -gt "$UMBRAL" ]; then
    ALERTA="🚨 ALERTA CRÍTICA — Posible brute force detectado"
    # Extraer IPs únicas para bloquear
    IPS_BLOQUEAR=$(echo "$LOG" | awk '{print $10}' | sort -u)
    # Bloquear cada IP en el firewall
    for IP in $IPS_BLOQUEAR; do
        ufw deny from "$IP" to any
    done
    # Enviar alerta por email
    {
    echo "Subject: 🚨 ALERTA SSH Brute Force Detectado"
    echo ""
    echo "Fecha: $FECHA"
    echo "Total intentos: $TOTAL"
    echo "Umbral: $UMBRAL"
    echo ""
    echo "IPs bloqueadas:"
    echo "$IPS_BLOQUEAR"
    echo ""
    echo "Usuarios intentados:"
    echo "$USUARIOS"
    } | msmtp -a gmail "your_email@example.com" 
else
    ALERTA="✅ Normal — Intentos dentro del umbral"
fi
{
echo "========================================="
echo "   DETECTOR DE SSH BRUTE FORCE"
echo "   Análisis: $FECHA"
echo "========================================="
echo ""
echo "[*] $ALERTA"
echo ""
echo "[*] Total de intentos fallidos: $TOTAL"
echo "[*] Umbral configurado: $UMBRAL"
echo ""
echo "[*] IPs atacantes (frecuencia):"
if [ "$TOTAL" -gt "$UMBRAL" ]; then
    echo "$IPS"
else
    echo "    Sin actividad sospechosa detectada"
fi
echo ""
echo "[*] Usuarios intentados (frecuencia):"
if [ "$TOTAL" -gt "$UMBRAL" ]; then
    echo "$USUARIOS"
else
    echo "    Sin actividad sospechosa detectada"
fi
echo "========================================="
} | tee "$REPORTE"
