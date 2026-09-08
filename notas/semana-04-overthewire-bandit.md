# Semana 04 — OverTheWire Bandit: Linux con las manos

34 niveles de Linux puro, cada uno con una contraseña escondida que abre el siguiente. Fue donde todo lo que había leído sobre comandos, permisos y SSH se volvió memoria muscular. Anoté cada nivel, cada comando y cada vez que me trabé.


## 01. Qué es Bandit y cómo se juega

Bandit es un CTF gratuito de OverTheWire pensado para aprender Linux desde cero. La regla de oro: la contraseña que encontrás en el nivel X es la que usás para entrar al X+1. Cada usuario solo puede leer su propio archivo en `/etc/bandit_pass/`.

```bash
# punto de entrada
ssh bandit0@bandit.labs.overthewire.org -p 2220

# guardar cada contraseña antes de cerrar la terminal
echo 'banditX: CONTRASENA' >> ~/bandit_passwords.txt
```


## 02. Niveles 0–12: leer archivos que no se dejan leer

La primera tanda es todo trucos de lectura. Un archivo llamado `-` (que `cat` interpreta como el teclado, se resuelve con `./-`), nombres con espacios, ocultos, y filtrar por propiedades con `find`.

```bash
# archivo legible, no ejecutable, de exactamente 1033 bytes
find . -type f -size 1033c ! -executable

# extraer texto de un binario y filtrar
strings data.txt | grep '=='

# base64 NO es cifrado, es codificación
base64 -d data.txt
```

Lo que me quedó: `base64` y ROT13 (`tr 'A-Za-z' 'N-ZA-Mn-za-m'`) no son cifrado, son codificación — cualquiera los revierte sin clave. Y `strings` es la puerta de entrada al análisis de malware: ver texto legible dentro de un binario sin descompilarlo.


## 03. Niveles 13–18: SSH, netcat y openssl

Acá empezó lo de red. Autenticación SSH con llave privada (y el detalle de que SSH rechaza la llave si los permisos no son `600`), mandar datos a un puerto con `nc`, y conectarse a un puerto cifrado con `openssl`.

```bash
# conectarse con llave privada en vez de contraseña
chmod 600 sshkey.private
ssh -i sshkey.private bandit14@bandit.labs.overthewire.org -p 2220

# mandar datos a un puerto sin cifrar
echo 'PASSWORD' | nc localhost 30000

# a un puerto con SSL/TLS
echo 'PASSWORD' | openssl s_client -connect localhost:30001 -quiet
```

> **↳ La que me confundió a mí y a todos** En `ssh` el puerto es `-p` minúscula; en `scp` es `-P` mayúscula. Es una inconsistencia histórica y no hay lógica, se memoriza y listo.


## 04. Niveles 19–24: SUID, cron y un brute force propio

El tramo que más conectó con las semanas anteriores. Un binario SUID (`bandit20-do`) para leer un archivo ajeno, y varios niveles de cron — donde vi de primera mano por qué los atacantes lo usan para persistencia. El nivel 24 pedía probar los 10000 PIN posibles: mi primer script de fuerza bruta en bash.

```bash
# ver tareas programadas (persistencia común de atacantes)
ls /etc/cron.d/
cat /usr/bin/cronjob_bandit22.sh

# fuerza bruta de 0000 a 9999 contra un puerto
for pin in $(seq -w 0000 9999); do
  echo "PASSWORD $pin"
done | nc localhost 30002
```


## 05. Lo que no entendía al principio

| Confusión | Cómo lo resolví |

|---|---|

| Por qué `cat -` no leía el archivo `-` | `-` significa 'leé del teclado'; hay que usar `./-` para forzar el archivo local |

| Base64 es cifrado? | No — es codificación. Se revierte sin clave con `base64 -d` |

| Por qué SSH rechazaba mi llave privada | Los permisos tienen que ser `600`; SSH no acepta llaves con permisos más abiertos |

| Diferencia entre `nc` y `openssl s_client` | `nc` para puertos sin cifrar; `openssl` cuando el puerto habla SSL/TLS |


## 06. Conexión con el mundo profesional

Bandit es el mejor gimnasio para los fundamentos que un analista usa todos los días: `grep`, `find`, `awk`, pipes, SSH con llaves, escaneo con `nmap`, y la lógica de cron para detectar persistencia. Terminar los primeros 24 niveles me dejó cómodo en la terminal, que era el objetivo real antes de meterme en procesos y forense.


## 07. Pregunta pendiente y próximo paso

La pregunta que me llevé: si un proceso malicioso arranca desde cron y después borra su ejecutable, ¿cómo lo encontrás? Eso empalma justo con la semana siguiente — **correlación de procesos y red**, cruzar `ps` con `ss` para ver qué programa está detrás de cada conexión.

— fv
