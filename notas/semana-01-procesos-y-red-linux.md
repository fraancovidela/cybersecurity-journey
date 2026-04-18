# Semana 1 — Correlación de procesos y red en Linux

## Qué practiqué
Correlación entre procesos activos y conexiones de red para 
identificar qué programa está detrás de cada conexión.

## Comandos utilizados
```bash
# Ver conexiones establecidas con su PID
ss -tanp | grep ESTAB

# Analizar el proceso por su PID
cat /proc/<PID>/status

# Ver el proceso padre (PPID)
cat /proc/<PID>/status | grep PPid
```

## Caso práctico real
Encontré una conexión establecida en la red, obtuve el PID,
y usando /proc descubrí que era Firefox. Al investigar el proceso
padre (PPid) encontré que era gnome-shell, lo cual tiene sentido
porque el escritorio GNOME es quien lanza el navegador.

Esto demuestra cómo rastrear el árbol de procesos para verificar
si una conexión es legítima o sospechosa.

## Checklist de triaje aprendido
Cuando analizo un sistema sospechoso, el orden es:

1. ¿Quién está conectado al sistema?
2. ¿Qué procesos están corriendo?
3. ¿Qué conexiones de red existen y qué proceso las generó?
4. ¿Hay procesos sin ruta legítima o con rutas sospechosas?
5. ¿Hay archivos ejecutables en directorios temporales?
6. ¿Hay conexiones a IPs externas? (excluyendo loopback)
7. ¿Hay cron jobs no autorizados?

## Concepto nuevo: loopback
Dirección de red interna del propio sistema (127.0.0.1).
Es comunicación del sistema consigo mismo, no tráfico externo.
No es sospechosa por sí sola.

## Concepto clave: /var/spool/ vs /usr/local/bin/

| Situación | Dónde guardar |
|-----------|---------------|
| Script propio que debe persistir | `/usr/local/bin/` |
| Automatización seria con crontab | `/usr/local/bin/` |
| CTF: explotar automatización ajena | `/var/spool/` (trampa) |

`/var/spool/` es una zona de paso temporal. El sistema ejecuta
lo que encuentra ahí y lo borra. Útil en CTFs para escalación
de privilegios, pero nunca para guardar scripts propios.

## Pregunta que me surgió y respondí
¿Dónde guardar mis scripts en un sistema real?
→ En /usr/local/bin/ con permisos correctos, y programar
su ejecución con crontab o systemd.
