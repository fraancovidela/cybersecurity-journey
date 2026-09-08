# Semana 08 — Gestores de contraseñas: ordenar la casa propia

Un analista que no gestiona bien sus propias credenciales no puede asesorar a nadie sobre el tema. Elegí KeePassXC por el formato abierto y el control total, y armé el vault entero desde cero: cifrado, 2FA, backup y sincronización multi-dispositivo.


## 01. Por qué KeePassXC y no un gestor cloud

Comparé KeePassXC, Bitwarden y 1Password. Me decidí por KeePassXC por tres razones: el formato **KDBX es abierto** (lo abren +15 programas en cualquier plataforma), no depende de ningún servicio externo, y el cifrado ocurre entero en mi dispositivo. Si el software desaparece mañana, mis datos siguen accesibles. Eso resolvía el requisito que me había puesto: no depender de un solo programa.


## 02. El vault: cifrado y segundo factor

Creé el vault con **KDBX 4, AES-256 y Argon2d**, con el tiempo de descifrado calibrado en 1 segundo. La contraseña maestra no la inventé yo: usé una **passphrase Diceware de 7 palabras** generada con el wordlist de la EFF (~90 bits de entropía). Y le agregué un **key file** como segundo factor, guardado separado del vault — para abrirlo hacen falta las dos cosas.

| Acción | Cómo |

|---|---|

| Guardar / bloquear el vault | `Ctrl+S` / `Ctrl+L` |

| Nueva entrada | `Ctrl+N` |

| Autofill en el navegador | `Ctrl+Shift+U` |

| Generar passphrase | Ícono de dado → Frase de contraseña |


## 03. El setup completo de punta a punta

No quedó en teoría — migré cuentas reales. Organicé el vault en grupos (Email, Redes Sociales, Finanzas, Estudio, Proyectos), conecté la extensión KeePassXC-Browser en Chrome y Edge, cambié las contraseñas de Gmail y Hotmail por unas de 20 caracteres generadas, y activé **2FA** en las dos, guardando los códigos de respaldo en las notas de cada entrada.

Para el acceso multi-dispositivo sincronicé el vault por Google Drive e instalé Strongbox en el iPhone —otro programa que abre el mismo `.kdbx`, justo la ventaja del formato abierto.


## 04. Lo que no entendía / lo que salió mal

La parte más honesta de la sesión: casi todo lo que aprendí salió de que algo no funcionaba.

| Confusión | Cómo se resolvió |

|---|---|

| El autofill no detectaba Gmail | La URL de login es `accounts.google.com`, no `mail.google.com` — se corrige en la entrada |

| Hotmail pedía PIN de Windows en vez de contraseña | Era un Passkey vinculado al dispositivo, no una falla; activé 2FA igual |

| Strongbox no encontraba el vault en Drive | Estaba en 'Mi PC' (backup); Strongbox solo ve 'Mi unidad' (sync) — lo moví ahí |

| Mandé los códigos de respaldo por un canal de mensajería | Los regeneré al toque. Regla: los códigos van directo al vault, nunca por terceros |

> **↳ La que más me marcó** Transferir el key file al iPhone sin cable me obligó a pensar el canal: lo mandé por email a mi propia cuenta con 2FA y borré el mail inmediatamente después. El segundo factor no se pasea por cualquier lado.


## 05. Concepto clave: zero-knowledge

Lo que separa a KeePassXC de un gestor cloud es la arquitectura **zero-knowledge**: el cifrado pasa entero en el dispositivo, ningún servidor ve las contraseñas. La contracara es que **no existe 'recuperar contraseña'**: si perdés la passphrase, no hay nadie a quien pedírsela. Ese detalle me llevó directo a la pregunta de la semana siguiente sobre cómo se deriva realmente la clave.


## 06. Conexión con el mundo profesional

En un SOC o una empresa, el manejo de credenciales es crítico: los vectores más comunes contra personas y organizaciones son contraseñas débiles, reutilizadas o guardadas sin cifrar. Lo que implementé —gestor con AES-256 + Argon2, 2FA en todo lo crítico, códigos de respaldo protegidos, backup 3-2-1 y el segundo factor separado del material cifrado— es exactamente lo que se exige en entornos profesionales.


## 07. Pregunta pendiente y próximo paso

¿Conviene guardar los códigos TOTP dentro del mismo vault, o tener la contraseña y el segundo factor en el mismo lugar rompe el sentido del 2FA? Me lo llevé sin cerrar. El próximo paso natural fue entender la criptografía por debajo de todo esto: qué es exactamente Argon2d, y por qué no hay vuelta atrás.

— fv
