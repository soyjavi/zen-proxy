ZEN-proxy
=========

This is the module for reverse proxy and load balancing mechanism to distribute incoming traffic. The important thing is that ZENproxy is focused on NodeJS platform.

As the same as [ZENserver][1], ZENproxy looks for high performance in a simple way to use it.

All setting are defined at `zen.proxy.yml` file.

[1]: <https://github.com/soyjavi/zen-server>

1. Start
---------
### 1.1 Install ZENproxy

```bash
  npm install zenproxy --save-dev
```

Next, we need create `zen.proxy.js` file to launch proxy with the following configuration:

```js
  "use strict"
  require('zenproxy').start();
```

And create `zen.proxy.yml` file. In this file we will describe all rules about proxy.

Also, you can add ZENproxy at your package.json:

```json
{
  "name"            : "zen-proxy-instance",
  "version"         : "1.0.0",
  "devDependencies" : {
    "zenproxy" : "^1.1.19" },
  "scripts"         : {"start": "node zen.proxy zen.proxy"},
  "engines"         : {"node": "*"}
}
```

### 1.2 Launching

You can start ZENproxy running the following command where the first parameter is the js file and the second is the yaml file. You can rename files as you like.

```bash
  node zen.proxy zen.proxy
```

### 1.3 Base configuration
All settings are at `zen.proxy.yml` file. The following lines are at the beginning of the file:


```yaml
protocol: http # or https
host    : localhost
port    : 8888
timezone: Europe/Amsterdam
timeout : 60000 # ms
```

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

-   **name**   : name of rule
-   **domain** : name of domain that the proxy is listening
-   **query**  : path from domain to start
-   **hosts**  : node instances to balance the traffic

### 2.2 Load Balancing Mechanism
By default ZEN-proxy use *roundrobin* strategie but *random* is also available. To change it just add the following attribute:

```yaml
rules:
  - name    : mydomain
    domain  : domain.com
    strategy: roundrobin
    ...
```

### 2.2 RegExp at URLs

You can use `query` attribute to decide how to process the request URI. You can configure a RegExp or literal path. Let's see with some examples:

```yaml
rules:
  - name    : mydomain
    domain  : domain.com
    query   : \/site\/([a-z])\w+.*.html
    hosts   :
      - address : 127.0.0.1
        port    : 1981

  - name    : mydomain
    domain  : domain.com
    query   : /user
    hosts   :
      - address : 127.0.0.1
        port    : 1982
```

The first query match URIs with `http://domain.com/site/foo.html` or `http://domain.com/site/bar.html` and direct traffic to instance listening at 1981. The second query direct traffic to instance listening at 1982 when the path is exactly `/user`.

### 2.3 Subdomain

With the attribute `subdomain` you can manage subdomains. Let's check following example:

```yaml
rules:
  - name      : mysubdomain
    domain    : domain.com
    subdomain : my
    query     : /
    hosts   :
      - address : localhost
        port    : 1980
      - address : localhost
        port    : 1983

  - name    : mydomain
    domain  : domain.com
    query   : /
    hosts   :
      - address : localhost
        port    : 1981
```

### 2.4 Block Incoming Port

You can block ports of your instances adding the attribute `block: true`. In this way, ZENproxy will block incoming ports using IPTable rules and your instances will not be accesed like `http://mydomain.com:1980`.

```yaml
rules:
  - name    : mydomain
    block   : true
    ...
```

3. Static files
---------------
ZENProxy let's you load balancing from your resources when ZENProxy and instances are at the same machine:

```yaml
  - name    : statics
    domain  : mydomain.com
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

As you can see, accessing at *http://mydomain.com/files* traffic will be redirect at instances 1986 and 1987 using *roundrobin* strategy.

About statics files, when a request comes to *http://mydomain.com/files/css* ZENProxy will look for files at *~/assets/stylesheets* (remember set abosolute path).

Working with statics you can save request latency.

4. Configuring HTTPS servers
-------------------
ZENProxy can work with SSL certificates. In the following example we can see attributes required to serve https content:

```yaml
protocol: https
host    : localhost
port    : 443
timezone: Europe/Amsterdam
timeout : 60000
cert    : cert.pem
key     : key.pem
```

It's necessary save your certificate files at */certificates* folder. ZenProxy will look for *cert.pem* and *key.pem* and will redirect traffic at instances declared at rules:

```yaml
rules:
  - name    : mydomain
    domain  : mydomain.com
    strategy: random
    https   : true
    query   : /
    hosts   :
      - address : localhost
        port    : 1980
      - address : localhost
        port    : 1983
```

Note that *https: true* attribute need to be added.

