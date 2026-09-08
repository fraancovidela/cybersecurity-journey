# Semana 01 — Redes, protocolos y análisis de tráfico

Empecé por lo más básico y lo que casi nadie mira de cerca: cómo viajan los datos por una red, y qué se puede leer de ellos con Wireshark abierto. La primera sorpresa fue cuánto habla mi PC sola.


## 01. El modelo OSI y TCP/IP

Arranqué con el modelo OSI porque es el mapa que todo el mundo usa para hablar de redes. Son 7 capas y cada una tiene una responsabilidad: de los bits en el cable (capa 1) hasta lo que ve el usuario en el navegador (capa 7). Lo que me quedó grabado es que la mayoría de los ataques viven en las capas 3, 4 y 7 — que es justo donde están los controles defensivos.

OSI es la teoría; **TCP/IP es lo que internet usa de verdad**. Cuatro capas en vez de siete, pero los dos protagonistas están en la capa de transporte: TCP y UDP.

| Capa | Protocolos y función |

|---|---|

| 7 · Aplicación | HTTP, HTTPS, DNS, FTP — lo que ve el usuario |

| 4 · Transporte | TCP, UDP, puertos — entrega confiable o rápida |

| 3 · Red | IP, routers — dirección lógica |

| 2 · Enlace | Ethernet, MAC — dirección física local |


## 02. TCP vs UDP y el handshake de 3 pasos

TCP es orientado a conexión: antes de mandar nada hace el **three-way handshake** — SYN, SYN-ACK, ACK. Garantiza que los datos lleguen completos y en orden, y si un paquete se pierde lo reenvía. UDP no: no hay handshake, no verifica nada, es más rápido pero no confiable. Se usa para streaming, videollamadas, juegos y DNS.

El ataque que conecta con esto es el **SYN flood**: el atacante manda miles de SYN sin nunca responder el SYN-ACK, y llena la tabla de conexiones del servidor hasta tirarlo. Es un DoS clásico y de repente el handshake dejó de ser un diagrama aburrido.


## 03. DNS — la guía telefónica sin candado

DNS traduce `google.com` a una IP como `142.250.78.142`. Lo importante para seguridad: fue diseñado para ser rápido, no seguro. Las consultas viajan **sin cifrar**. Sobre eso se montan DNS spoofing (respuesta falsa), cache poisoning (corromper el caché del servidor) y DNS tunneling (exfiltrar datos escondidos en consultas).

Dato concreto de la práctica: mi servidor DNS es `181.30.140.134`, de Fibertel. Todas mis consultas pasan en texto plano por ahí. Verlo en Wireshark fue distinto a leerlo en un apunte.


## 04. HTTP vs HTTPS y el SNI

HTTP viaja en texto plano por el puerto 80: cualquiera en la red lee exactamente qué páginas visitás y qué mandás. HTTPS es HTTP con TLS encima (puerto 443), el contenido va cifrado. Pero hay una fuga que no esperaba: el **SNI** (el nombre del servidor) viaja en texto plano durante el handshake TLS. O sea, HTTPS protege *qué* decís, no *con quién* hablás.


## 05. Los ataques de capa 7

Los firewalls viejos bloqueaban puertos, pero hoy casi todo pasa por el 443, así que el tráfico malicioso se mezcla con el legítimo. Los tres que anoté:

- **SQLi** — inyectar SQL en un campo que la app no valida. Escribir `' OR '1'='1` convierte la query en siempre verdadera y entrás sin contraseña.
- **XSS** — inyectar JavaScript en una página que lo muestra sin sanitizar. No ataca al servidor: ataca al navegador de la víctima usando el servidor de intermediario.
- **DDoS de capa 7** — requests HTTP legítimas pero caras de procesar. El firewall no las ve raras porque parecen normales. Se mitigan con un WAF.


## 06. Wireshark en la práctica — 5 misiones

Acá dejé de leer y abrí la herramienta. Cinco misiones, cada una con su filtro. Los que más usé:

```bash
# ver el DNS en acción
dns

# leer HTTP en texto plano
http

# confirmar que HTTPS cifra (pero deja ver el SNI)
tls

# ver el handshake TCP
tcp.flags.syn == 1
```

Lo que encontré: leí una request HTTP de Avast (`ncc.avast.com`) **entera, en texto plano** — método, User-Agent y respuesta. Confirmé que en HTTPS el contenido es basura ilegible pero el SNI (`activity.windows.com`) se lee igual. Vi el handshake completo SYN → SYN-ACK → ACK contra Google. Y en la misión 5, sin tocar nada 30 segundos, la PC hablaba sola con Google, Microsoft, Avast y Spotify. Todo limpio, verificado en VirusTotal, pero la lección quedó.


## 07. Lo que no entendía al principio

| Confusión | Cómo lo resolví |

|---|---|

| Por qué UDP se usa si no es confiable | Para streaming/juegos la velocidad importa más que perder un paquete |

| Qué diferencia hay entre OSI y TCP/IP | OSI es el modelo teórico de 7 capas; TCP/IP es la implementación real de 4 |

| Si HTTPS cifra todo, por qué se ve el sitio | El SNI viaja en texto plano en el handshake — se ve a quién te conectás |

| Una IP sin nombre DNS en `nslookup` es maliciosa? | No necesariamente, pero es señal de investigar — la crucé con VirusTotal |


## 08. Conexión con el mundo profesional

Esto es literalmente lo que hace un analista cuando revisa una máquina sospechosa: quién habla con quién, cuándo, y cuántos datos intercambia. La misión 5 —capturar tráfico en reposo y clasificar cada IP— es un mini-triaje forense de red. Entender el handshake y el SNI es la base para leer después logs de un IDS o un SIEM.


## 09. Pregunta pendiente y próximo paso

Me quedó picando: si el SNI se ve igual, ¿cómo se protege eso? (spoiler para más adelante: ECH / Encrypted Client Hello). Lo próximo era bajar de la red al sistema: **Linux y línea de comandos**, que es el idioma nativo del laburo.

— fv
