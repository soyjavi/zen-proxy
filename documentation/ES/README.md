ZEN-proxy
=========

Es el modulo de ZEN destinado a tareas de reverse-proxy y balanceo de carga.
Actualmente existen opciones maduras como pueden ser [NGINX][1] o [HAPROXY][2]
pero estas no funcionan bajo NodeJS. En el caso de que quieras tener tu propio
proxy corriendo sobre la plataforma de NodeJS te recomendamos que utilices
ZENproxy que, al igual que [ZENserver][3], su premisa es la sencillez y el
rendimiento. A diferencia con este último, no necesitaremos programar ninguna
linea de código puesto que toda la lógica estará definida en el fichero de
configuración `zen.yml`

[1]: <http://nginx.org/>

[2]: <http://www.haproxy.org/>

[3]: <https://github.com/soyjavi/zen-server>

1. Inicio
---------

### 1.1 Instalación

Para instalar una nueva instancia de ZENproxy únicamente tienes que ejecutar el
comando:

```
npm install zenproxy --save-dev
```

El siguiente paso es crear el fichero zen.yml que contendrá la configuracion del
proxy y el fichero zen.js con el siguiente contenido:

```
"use strict"
require('zenproxy').start();
```

Otra manera, algo más rudimentaria, es modificar el fichero `package.json`
incluyendo esta nueva dependencia:

```
{
  "name"            : "zen-proxy-instance",
  "version"         : "1.0.0",
  "dependencies": {
    "zenproxy"     : "*" },
  "scripts"         : {"start": "node zen.js zen"},
  "engines"         : {"node": "*"}
}
```

### 1.2 Arranque

El proxy se ejecua mediante el siguiente comando:

```
$ node zen.js zen
```

O en su defecto, el nombre del fichero *.js* y el fichero *.yml* que hayas
creado.

### 1.3 Configuración básica

Uno de los beneficios de usar ZEN es que el fichero de configuración (`zen.yml`)
cobra una gran importancia a la hora de configurar el proxy y balancer. Vamos a
ir analizando cada una de las opciones que nos permite establecer el fichero
`zen.yml`:

```
protocol: http # or https
host    : localhost
port    : 8888
timezone: Europe/Amsterdam
timeout : 2000 # ms
```

Esta sección te permite establecer la configuración general de tu ZENproxy; el
**protocolo** que vas a utilizar (`http` o `https`), el **nombre** del host,
**puerto**, **zona horaria** y el **timeout** máximo para cada respuesta.

2. Reglas
---------

### 2.1 Configuración básica

Una vez tengas la configuración básica solo nos queda configurar las reglas de
nuestro proxy. Para ello utilizaremos crearemos un atributo `rules` en nuestro
fichero `zen.yml` e iremos incluyendo cada una de ellas. Comencemos con nuestra
primera regla:

```
rules:
  - name    : mydomain
    domain  : domain.com
    query   : /
    hosts   :
      - address : localhost
        port    : 1980
      - address : localhost
        port    : 1983
```

Esta sería la regla más sencilla que podemos configurar en ZENproxy, veamos cada
uno de sus atributos:

-   **name**: El nombre de la regla

-   **domain**: Dominio que quieres que controle el proxy

-   **query**: Ruta que quieres controlar

-   **hosts**: Servidor (o servidores) a los que tiene que acceder cuando se
    ejecute la regla.

### 2.1 Estrategia de balanceo

Como ves es muy sencillo, y habrás podido deducir que en el atributo **hosts**
si estableces más de un servidor ZENproxy actuará automáticamente como un
balanceador. Por defecto, como estrategia de balanceo, utiliza *random* en el
caso de que quisieses utilizar la famosa estrategia *RoundRobin* simplemente
tienes que especificarlo en la regla:

```
rules:
  - name    : mydomain
    strategy: roundrobin
    ...
```

### 2.2 URLs con expresiones regulares

Al comienzo de este capitulo vimos que podíamos establecer una url específica
por medio del atributo `query`. Por ejemplo si quisieramos controlar la url
*http://dominio.es/users* deberíamos hacer una configuración tal que asi:

```
  ...
  - name    : midominio
    domain  : dominio.es
    query   : /users
    ...
```

En el caso de que queramos controlar urls más complejas podemos utilizar
*regular expresions* para ello, veamos un ejemplo:

```
  ...
  - name    : midominio
    domain  : dominio.es
    query   : /regex/prefix-.*/hello-.*
    ...
```

En este ejemplo ZENproxy ejecutará la regla cuando la url comience por
*http://dominio.es/regex/prefix-*. Esta funcionalidad puede ser muy util por
ejemplo

### 2.3 Subdominios

Si quieres controlar un determinado subdominio solo tienes que hacer uso del
atributo `subdomain`, obvio. Esto puede ser muy útil si en tu estrategia de
balanceo quieres que a un determinado subdominio controle un grupo específico de
máquinas. Veamos como quedaría:

```
rules:
  - name    : mydomain
    domain  : domain.com
    query   : /
    hosts   :
      - address : localhost
        port    : 1980
      - address : localhost
        port    : 1983

  - name      : mysubdomain
    domain    : domain.com
    subdomain : my
    query     : /
    hosts   :
      - address : localhost
        port    : 2014
```

### 2.4 Bloqueo de IPTables

Otra opción muy interesante es el bloqueo IPTables cuando ZENproxy y los
servidores de respuesta están ejecutandose en la misma máquina. Por ejemplo,
tenemos nuestro *dominio.es* que va a acceder a dos instancias NodeJS que se
ejecutan en la misma máquina en los puertos `1980` y `1983`:

```
rules:
  - name    : midominio
    domain  : dominio.es
    query   : /
    hosts   :
      - address : localhost
        port    : 1980
      - address : localhost
        port    : 1983
```

Si no tienes bloqueados los puertos 1980 y 1983, cualquier usuario podría
acceder a *http://dominio.es:1980* (o 1983) puesto que esos puertos están
visibles. Para que ZENproxy bloquee automáticamente estos puertos mediante
reglas IPTables, solo tienes que utilizar el atributo `block`:

```
rules:
  - name    : midominio
    block   : true
```

3. Servidor de archivos estáticos
---------------------------------

Por último vamos a aprender como crear un balanceador de recursos, sigue siendo
igual de sencillo. Creamos una nueva nueva regla la cual controlará la url
*http://127.0.0.1/files*:

```
  - name    : statics
    domain  : 127.0.0.1
    query   : /files
    strategy: roundrobin
    hosts:
      - address : localhost
        port    : 1986
      - address : 127.0.0.1
        port    : 1987
    statics:
      - url     : /css
        folder  : ~/assets/stylesheets
        maxage  : 60 #1 minute
      - url     : /img
        folder  : /avatars
        maxage  : 3600 #1 hour
      - url     : /js
        folder  : ~/assets/javascripts
```

Como vemos, cuando se ejecute la regla responderán las máquinas *localhost:1986*
y *127.0.0.1:1987* por medio de la estrategia *RoundRobin*. En el caso de los
ficheros estáticos, cada vez que se acceda a *http://127.0.0.1/files/css* se
servirán los archivos contenidos en la ruta */assets/stylesheets* del directorio
de tu host. En el atributo *folder*, es necesario especificar la ruta completa
hasta ese directorio.

Utilizando esta técnica puedes ahorrar latencia puesto que ZENproxy no tiene que
pedir los ficheros estáticos a cada uno de los hosts, sino que el se ocupará de
buscarlos. Evidentemente esta técnica solo es efectiva cuando tanto ZENproxy
como los hosts se ejecutan en la misma maquina.
