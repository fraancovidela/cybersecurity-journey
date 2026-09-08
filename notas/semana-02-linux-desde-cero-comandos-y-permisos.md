# Semana 02 — Linux desde cero: comandos y permisos

El 96% de los servidores del mundo corre Linux, así que no había forma de esquivarlo. Dos sesiones: orientarme en el sistema como lo hace un analista, y entender el sistema de permisos —que después resultó ser la base de todo lo demás.


## 01. Lo primero que hace un profesional: orientarse

La idea que me ordenó todo: cuando entrás a un sistema, antes que nada preguntás quién sos y dónde estás parado. No es memorizar comandos sueltos, es una rutina.

```bash
# quién soy y con qué privilegios
whoami
id

# dónde estoy y qué sistema corre (buscar CVEs del kernel)
pwd
uname -a

# ver todo, incluyendo ocultos y permisos
ls -la
```

Armé un mini reporte forense encadenando esto y guardándolo en un archivo. Al cuarto día me salía de memoria, que era el punto: la navegación con propósito hace que los comandos salgan solos, no memorizándolos en el vacío.


## 02. Las carpetas que importan

No todas las rutas valen lo mismo para seguridad. Estas son las que un atacante y un defensor miran primero:

| Ruta | Por qué importa |

|---|---|

| `/etc` | Configuración del sistema — oro para los dos lados |

| `/etc/passwd` | Lista de usuarios — enumeración de cuentas |

| `/etc/shadow` | Contraseñas hasheadas — solo root las lee |

| `/var/log` | Logs — detección de intrusiones |

| `/tmp` | Escribible por todos — los atacantes suben malware acá |

| `/proc` | Estado del kernel en vivo — análisis de procesos |


## 03. El sistema de permisos

Cada archivo tiene tres juegos de llaves: dueño, grupo y otros. Cada uno puede leer (r), escribir (w) o ejecutar (x). Lo que me costó al principio fue el sistema octal, hasta que lo vi como una suma: **r=4, w=2, x=1**.

| Notación | Octal | Uso típico |

|---|---|---|

| `-rwxr-xr-x` | 755 | Scripts y binarios |

| `-rw-r--r--` | 644 | Archivos de configuración |

| `-rw-------` | 600 | Claves SSH privadas |

| `-rwxrwxrwx` | 777 | Abierto total — nunca en producción |

El `777` parece cómodo cuando estás probando, pero es dejar la puerta abierta con las llaves puestas: cualquiera puede reescribir el contenido. Si es un script que corre el admin, un atacante lo envenena y espera.


## 04. Buscar lo que está mal configurado

Estos comandos son estándar en cualquier auditoría. El `2>/dev/null` descarta los errores de permiso para que no tapen los resultados útiles — me tardé en entender que el `2` es stderr y `/dev/null` es el agujero negro de Linux.

```bash
# binarios que se ejecutan como root aunque los llame otro usuario
find / -perm -4000 2>/dev/null

# archivos escribibles en /tmp (depósito de malware)
find /tmp -writable 2>/dev/null

# archivos que solo root debería poder leer
ls -la /etc/shadow
```

> **↳ Consejo del panel** El 70% de las escaladas de privilegios reales se explota por permisos mal configurados. No hay que memorizar: hay que entender el mecanismo.


## 05. Lo que no entendía al principio

| Confusión | Cómo lo resolví |

|---|---|

| Por qué el sistema usa números para los permisos | Es una suma: r=4, w=2, x=1 por cada grupo (dueño/grupo/otros) |

| Qué hace `2>/dev/null` al final de `find` | Manda los errores de 'permiso denegado' a la basura y deja solo lo útil |

| Por qué `/etc/passwd` es legible por todos si tiene los usuarios | El sistema lo necesita; las contraseñas reales están aparte en `/etc/shadow` |

| Por qué `rm` no pregunta y no hay papelera | En Linux `rm` es irreversible — se aprende a la mala una vez |


## 06. Conexión con el mundo profesional

La orientación (`whoami`, `id`, `uname`, `ls -la`) es el arranque de cualquier triaje real. Y la búsqueda de permisos peligrosos es un paso fijo tanto en una auditoría defensiva como en la post-explotación de un pentest. Los mismos comandos, distinta intención.


## 07. Pregunta pendiente y próximo paso

Me quedó la duda de por qué un binario como `passwd` puede escribir en `/etc/shadow` si yo no puedo — y eso es exactamente el bit SUID, el tema de la semana siguiente.

— fv
