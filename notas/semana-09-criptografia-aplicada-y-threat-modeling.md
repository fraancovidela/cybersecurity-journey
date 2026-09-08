# Semana 09 — Criptografía aplicada y threat modeling

El cierre teórico de la Fase 1. Dejé de usar herramientas de cifrado a ciegas y entendí qué pasa por debajo: hashing, derivación de claves, RSA, TLS y por qué un padding oracle rompe la confidencialidad sin romper AES. Todo con la terminal, no con diapositivas.


## 01. Hashing: la calle de una sola mano

Lo primero que desarmé: un hash **no se invierte**. El sistema no 'descifra' tu contraseña — rehashea lo que ingresás y lo compara contra el hash guardado. Generé MD5, SHA-256 y SHA-512 del mismo string y confirmé el **efecto avalancha**: cambiar un solo carácter da un hash completamente distinto.

```bash
# el efecto avalancha: un carácter cambia todo el hash
echo -n 'password'  | sha256sum
echo -n 'Password'  | sha256sum

# simular el formato de /etc/shadow sin tocar el sistema real
python3 -c "import crypt; print(crypt.crypt('mipass', crypt.mksalt(crypt.METHOD_SHA512)))"
```


## 02. KDF vs hashing: por qué no hay 'recuperar contraseña'

Acá cerré la pregunta que me traje de la semana 08. KeePassXC no usa hashing para abrir el vault, usa una **KDF (Argon2d)**: convierte la passphrase directamente en la clave AES-256. No la compara contra nada guardado — la *deriva*. Por eso no hay recuperación posible: no existe ningún lado donde la clave esté guardada, solo se puede volver a derivar desde la passphrase.

Y Argon2 es lento y pesado a propósito: además de iterar, consume RAM configurable. Una GPU tiene miles de núcleos pero poca RAM por núcleo, así que no puede paralelizar el ataque de fuerza bruta como haría con un hash común.


## 03. Encoding, simétrico y asimétrico

Separé tres cosas que al principio mezclaba: **encoding** (Base64, reversible sin clave), **cifrado simétrico** (AES, misma clave para cifrar y descifrar) y **asimétrico** (RSA, par de claves pública/privada). Los probé todos con openssl.

```bash
# simétrico: AES-256-CBC, misma clave las dos veces
openssl enc -aes-256-cbc -pbkdf2 -in mensaje.txt -out mensaje.enc

# asimétrico: generar el par RSA
openssl genrsa -out privada.pem 2048
openssl rsa -in privada.pem -pubout -out publica.pem

# cifrar con la pública, descifrar con la privada
openssl rsautl -encrypt -inkey publica.pem -pubin -in plain.txt -out cif.bin
openssl rsautl -decrypt -inkey privada.pem -in cif.bin
```

La evidencia más clara de que la asimetría es real y no un dibujo: intenté a propósito descifrar con la clave pública y el sistema lo rechazó con un error explícito. Esa falla controlada valió más que cualquier explicación.


## 04. Inspeccionar un certificado TLS real

Bajé la teoría a algo de producción: le miré el certificado a google.com con openssl. Ver el Issuer, la vigencia y a quién fue emitido es un chequeo de rutina para detectar un certificado autofirmado o vencido.

```bash
echo | openssl s_client -connect google.com:443 2>/dev/null \
  | openssl x509 -noout -text \
  | grep -E 'Subject:|Issuer:|Not After'
```


## 05. Threat modeling: la tríada CIA y STRIDE

La otra mitad de la sesión fue teoría de análisis de amenazas. Toda la seguridad gira alrededor de tres propiedades — **Confidentiality, Integrity, Availability** (tríada CIA) — y todo ataque cae en una o más categorías de **STRIDE**. Lo que me lo hizo concreto: no es abstracto, cada herramienta que ya uso ataca uno de estos problemas. Fail2Ban protege Availability, AES protege Confidentiality, un hash protege Integrity.

El threat modeling con STRIDE es lo primero que hace un pentester o auditor antes de tocar una herramienta: mapear activos, atacantes y amenazas. Mapear antes de atacar.


## 06. Lo que no entendía al principio

| Confusión | Cómo lo resolví |

|---|---|

| ¿El hash se puede invertir para recuperar el password? | No, es one-way. El sistema rehashea el input y compara — nunca desarma el original |

| ¿La clave AES de KeePassXC es un hash? | No: Argon2d es una KDF, su output se usa directo como clave, no se compara contra nada |

| ¿Por qué Argon2 es más pesado que bcrypt? | Consume RAM configurable — una GPU no puede paralelizar el ataque eficientemente |

| ¿Qué pasa si AES-256 o Argon2 se rompen algún día? | Sin el `.kdbx` robado no hay nada que atacar; romper la KDF o el cifrado abarata el ataque, no entrega la clave |


## 07. Conexión con el mundo profesional

Esto es lo que separa a alguien que *usa* herramientas de seguridad de alguien que entiende *por qué* funcionan. Entender que un **padding oracle** rompe la confidencialidad sin romper AES es el tipo de razonamiento que se evalúa en eJPT y OSCP, y está detrás de vulnerabilidades reales documentadas como POODLE y Lucky Thirteen. Inspeccionar un certificado TLS o correr un STRIDE sobre un sistema son tareas de rutina del laburo.


## 08. Pregunta pendiente y próximo paso

Me quedó una pregunta fina: en un padding oracle, ¿por qué el atacante ataca primero el último byte del bloque y no el primero? Con eso y unos challenges de CryptoHack pendientes, la **Fase 1 (Fundamentos) queda cerrada**. Lo que viene es Fase 2: Blue Team con foco en SIEM y análisis de logs a escala — y ahí entra la IA aplicada a la detección, que es el diferencial que quiero construir.

— fv
