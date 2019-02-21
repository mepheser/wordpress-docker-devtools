# Wordpress theme docker runner
Simple docker based dev runner for wordpress theme development. Ships a docker-compose.yml that provides
* wordpress on port 8000 with mounted dev theme
* phpmyadmin on port 8001
* mysql for internal use


## Installation

Checkout repo and add `wp-dev.sh` to path.

## Convention over configuration

Runner expects a defined directory layout that is mounted into docker:
```
project
└───dev
│   └───cli -> /tmp/cli (init scripts, including wp cli calls)
│   └───lib -> /tmp/lib (optional static dependencies)
│   └───test-data /tmp/test-data (optional wp export xmls)
└───src (theme source code)
└───public -> /var/www/html/wp-content/themes/dev (compiled theme, mounted in wordpress)
```

Make sure wordpress ready theme gets built into `public`

## Commands

* `wp-dev start` Start services as daemon (with `docker-compose up -d`)
* `wp-dev stop` Stop services, keep data (with `docker-compose down`)
* `wp-dev clean` Stop services and clear data (with `docker-compose down -v`)
* `wp-dev run <script>` Execute a script file of `/dev/cli` inside wordpress container (see example below)
* `wp-dev cli <command>` Execute arbitrary wp-cli command
* `wp-dev bash` Open a bash in wordpress container

## Example init script

After first `wp-dev start`, wordpress instance need to be initialized. This may be done manually on http://localhost:8000 
or by script. Define `./dev/cli/init.sh`:
```
#!/bin/bash

wp core install --url=localhost:8000 --title="Wordpress dev"  --admin_user=wordpress --admin_password=wordpress --admin_email=test@test.com --skip-email
wp option update permalink_structure "/%postname%"

wp plugin delete --all
wp plugin install /tmp/lib/advanced-custom-fields-pro.zip
wp plugin activate advanced-custom-fields-pro
wp plugin install wordpress-importer --activate

wp import /tmp/test-data/data-dump.xml --authors=create

wp theme activate dev

```
And execute script in running container:
```
wp-dev run init
```
