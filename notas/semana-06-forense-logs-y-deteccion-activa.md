# Semana 06 — Forense de Logs y Detección Activa

## Qué practiqué

Semana enfocada en pasar del análisis pasivo a la detección activa. Hice triaje
completo de una VM simulando un backdoor real con netcat, construí un script Bash
de seguridad con alertas automáticas y reporte por email, analicé logs forenses en
Ubuntu 24.04 generando evidencia de actividad sospechosa, y cerré la semana
simulando un ataque SSH brute force de 200 intentos contra mi propia máquina y
construyendo el detector desde cero con bloqueo automático via UFW.

## Comandos o herramientas usadas

```bash
# Triaje de procesos y red
ps auxf                          # árbol de procesos con padres e hijos
ss -tanp                         # conexiones activas con proceso dueño
ss -lntp                         # puertos en escucha
ss -tnp state established        # conexiones establecidas
lsof -i :9999                    # proceso dueño de un puerto específico
lsof -p <PID> -n                 # archivos y sockets de un proceso

# Inspección via /proc
ls -la /proc/<PID>/exe           # binario real detrás del proceso
cat /proc/<PID>/cmdline          # comando exacto de lanzamiento
cat /proc/<PID>/status           # estado, UID, PPID y grupos
ls /proc/<PID>/fd/               # file descriptors abiertos

# Simulación y control
nc -lvnp 9999                    # simular backdoor escuchando
kill <PID>                       # terminar proceso por ID

# Persistencia
crontab -l                       # tareas del usuario actual
crontab -e                       # editar cron del usuario
crontab -r                       # eliminar crontab
cat /etc/crontab                 # cron del sistema con columna de usuario
ls -la /etc/cron.d/              # tareas programadas del sistema
cat /etc/cron.d/sysstat          # ejemplo de tarea legítima de baseline

# Script Bash
chmod +x script.sh               # dar permisos de ejecución
chmod 600 archivo_sensible       # restringir lectura a solo el propietario
echo -e "texto"                  # imprimir con colores ANSI
tee archivo.log                  # mostrar y guardar simultáneamente
cat -A script.sh                 # detectar caracteres invisibles
bash -x script.sh                # modo debug paso a paso
ps aux --sort=-%cpu              # procesos ordenados por uso de CPU
find /tmp -type f -executable    # ejecutables sospechosos en /tmp
find / -perm -4000               # binarios con bit SUID

# Forense de logs
journalctl --since "fecha" --until "fecha"   # logs por rango de tiempo
journalctl --rotate                          # rotar logs manualmente
journalctl --vacuum-time=1d                  # limpiar logs viejos
grep -aE "patron" /var/log/auth.log          # buscar en logs con partes binarias

# SSH brute force y detección
ssh -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=no user@host
for i in $(seq 1 200); do ...; done          # loop de intentos
awk '{print $N}'                             # extraer columna N
sort | uniq -c | sort -rn                    # contar y ordenar por frecuencia
wc -l                                        # contar líneas
ufw enable                                   # activar firewall
ufw deny from <IP>                           # bloquear IP
ufw delete deny from <IP>                    # desbloquear IP

# Email
msmtp --account=gmail destinatario@mail.com  # envío de email desde terminal
```

## Caso práctico o ejercicio real

**Día 1–2 — Backdoor en tiempo real:** Lancé `nc -lvnp 9999` en mi VM para simular
un proceso malicioso, luego lo detecté usando `lsof -i :9999`, tracé su árbol de
padres con `ps auxf`, e inspeccioné su binario real via `/proc/<PID>/exe`. El
proceso aparecía dos veces en `ss` porque tenía dos file descriptors simultáneos:
uno para seguir escuchando (fd=3) y otro para mantener la conexión activa (fd=4).

**Día 3 — Script de triaje:** Construí `triage.sh` desde cero: revisa procesos por
CPU, conexiones establecidas, ejecutables en `/tmp`, binarios SUID y persistencia
en cron. Genera un reporte con timestamp y lo envía por email via `msmtp`. El
principal problema fue un loop infinito al intentar que el script se llamara a sí
mismo — se resolvió usando funciones internas.

**Día 4 — Forense de logs:** Generé evidencia real en mi Ubuntu 24.04 (intentos
fallidos de sudo, acceso a `/etc/shadow`) y la rastreé en `auth.log` y
`journalctl` hasta construir una timeline completa del incidente. Aprendí que
`grep` en logs modernos requiere `-a` porque Ubuntu escribe partes binarias en
los logs.

**Día 5 — SSH Brute Force + detector:** Simulé 200 intentos de login fallidos
contra mi propia VM con un loop `for` + `ssh`. Luego construí el script detector:
extrae IPs con `awk`, cuenta intentos con `uniq -c`, bloquea automáticamente via
`ufw deny` al superar el umbral, y notifica por email. Lo automaticé con `cron`
corriendo cada 5 minutos. El problema de que el email funcionaba manual pero no
desde cron se resolvió entendiendo que cron hereda el entorno del usuario que lo
ejecuta — moviéndolo al crontab de root se solucionó.

## Concepto clave aprendido

**Separar código de configuración.** Las credenciales viven en archivos con
permisos restringidos (`chmod 600`), nunca hardcodeadas en el script. Cada proceso
hereda el entorno del usuario que lo lanza — por eso un script que funciona
manualmente puede fallar desde cron si corre como un usuario diferente con otra
`$HOME` y otra configuración.

Complementario: **baseline**. Saber qué es normal en un sistema (como `sysstat`
corriendo como root cada 10 minutos) es el prerequisito para identificar qué es
realmente anómalo. Sin baseline, cualquier proceso legítimo puede parecer sospechoso.

## Qué no entendía al principio y cómo lo resolví

| Confusión | Resolución |
|---|---|
| Por qué excluir loopback al buscar conexiones sospechosas | El loopback es tráfico interno que nunca sale a la red — no representa amenaza externa |
| Por qué el mismo PID aparece dos veces en `ss` | Tiene dos file descriptors: fd=3 escucha, fd=4 mantiene la conexión activa |
| Por qué un virus sigue corriendo si borrás el ejecutable | El proceso ya está cargado en RAM; usa cron o el registro para reaparecer al reiniciar |
| Por qué `grep` en logs devolvía "coincidencia en fichero binario" | Ubuntu 24.04 escribe logs con partes binarias — se resuelve con `-a` o usando `journalctl` |
| Por qué el email funcionaba manual pero no desde cron | Cron hereda el entorno del usuario ejecutor — mover la tarea al crontab de root solucionó el acceso a `.msmtprc` |

## Pregunta que me quedó pendiente

¿Cómo hace Fail2Ban para bloquear IPs automáticamente por tiempo limitado y
desbloquearlas solas sin intervención humana?
