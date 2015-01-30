ZEN-proxy
=========

This is the module for reverse proxy and load balancing mechanism to distribute incoming traffic. The important thing is that ZEN-proxy is focused on NodeJS platform.

As the same as [ZENserver][1], ZEN-proxy looks for high performance in a simple way to use it.

All setting are defined at `zen.proxy.yml` file.

[1]: <https://github.com/soyjavi/zen-server>

1. Inicio
---------
### 1.1 Install ZEN-proxy

```bash
  npm install zenproxy --save-dev
```

Next, we need create the `zen.proxy.js` file to launch it:

```js
  "use strict"
  require('zenproxy').start();
```

And the `zen.proxy.yml` file with all configuration about proxy rules.

You also can add at you package.json the dependencie:

```json
{
  "name"            : "zen-proxy-instance",
  "version"         : "1.0.0",
  "devDependencies" : {
    "zenproxy" : "^1.1.19" },
  "scripts"         : {"start": "node zen.proxy.js zen"},
  "engines"         : {"node": "*"}
}
```

### 1.2 Launching

You can start ZEN-proxy running the following command where the first parameter is the js file and the second is the yml file. You can rename files as you like.

```bash
  node zen.proxy zen.proxy
```

### 1.3 Base configuration
All settings are at `zen.proxy.yml` file. We are seeing how it works:

```yaml
protocol: http # or https
host    : localhost
port    : 8888
timezone: Europe/Amsterdam
timeout : 60000 # ms
```

As you can see, this is the general configuration about proxy.

2. Rules
---------
### 2.1 Basic configuration

The `yaml` file continues with rules for each node instance you want to run.

```yaml
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

In this case we are listening one domain and balancing the traffic between two instances. Let's see what attributes means:

-   **name**    : Name of rule
-   **domain**  : Name of domain that the proxy is listening
-   **query**   : Path from domain to start
-   **host**    : Node instances to balance the traffic

### 2.2 Load Balancing Mechanism
By default ZEN-proxy use *roundrobin* strategie but *random* is also available. To change it just add the following attribute:

```yaml
rules:
  - name    : mydomain
    strategy: roundrobin
    ...
```





























