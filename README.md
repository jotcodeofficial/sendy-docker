# Introduction
Welcome to sendy-docker (Sendy Docker for Kubernetes).


# Quick reference
* Where to file issues: [https://github.com/jotcodeofficial/sendy-docker/issues](https://github.com/jotcodeofficial/sendy-docker/issues)


# What is sendy-docker
Sendy Docker for Kubernetes is a docker image based on the one created by bubbajames.
If you just want a docker version and are not using kubernetes then check out his repo:
[https://github.com/bubbajames-docker/sendy](https://github.com/bubbajames-docker/sendy)

For more information and related blog posts, please visit [Jotcode.com](https://jotcode.com).


# What is Sendy?
Sendy is a self-hosted email newsletter application that lets you send trackable emails via [Amazon Simple Email Service (SES)](http://aws.amazon.com/ses/). This makes it possible for you to send authenticated bulk emails at an insanely low price without sacrificing deliverability.

For more information and related downloads for Sendy Server and other products, please visit [Send.co](https://sendy.co/?ref=Hcurv).

<a href="https://sendy.co/?ref=Hcurv" title=""><img src="https://sendy.co/images/banners/125x125_var2.jpg" alt="Check out Sendy, a self hosted newsletter app that lets you send emails 100x cheaper via Amazon SES." width="125" height="125"/></a>

# How to use this image
You can build your application by forking the sendy-kube repo which will auto use this image.
Or you can pull this docker image if you want to build your project from scratch (or import into an existing project) by using:
[https://hub.docker.com/r/jotcode/sendy-docker](https://hub.docker.com/r/jotcode/sendy-docker)

## Environment Varaibles 
### `SENDY_PROTOCOL` (Optional)  
HTTP protocol used in Sendy APP_PATH (`http` or `https`). Default: `http` 
### `SENDY_FQDN` (required)
The fully qualified domain name of your Sendy installation.  This must match the FQDN associated with your license.  You can [purchase a license here](https://sendy.co/?ref=Hcurv).   
### `MYSQL_HOST` (required) 
The MySQL server hosting your Sendy database.  
### `MYSQL_DATABASE` (optional)
The Sendy database name. Default: `sendy`.    
### `MYSQL_USER` (optional) 
Database user.  Default: `sendy`.   
### `MYSQL_PASSWORD` (required)
Database user's password. Not recommended for sensitive data! (see: Docker Secrets)


## Using `Dockerfile`
Pretty minimalistic `Dockerfile` as everything you need is already bundled.  Just provide environment variables.

```dockerfile
FROM jotcode/sendy-docker:5.2

# ... additional apache/php configurations here ... 
# e.g. copy your SSL Certificate and apache configurations if not using a load balancer.  
```
### Start a Sendy instance
The following starts an instance specifying an environment file.

```console
$ docker run -d -name sendy --env_file sendy.env -p 80:80 sendy
```

### Sample environment file
```ini
SENDY_FQDN=campaigns.example.com
MYSQL_HOST=db_sendy
MYSQL_DATABASE=sendy
MYSQL_USER=sendy
MYSQL_PASSWORD_FILE=/run/secrets/db_password
# MYSQL_PASSWORD=db_password
```

## Using `docker-compose`
Starts an HAProxy load balancer instance for SSL termination, a Sendy instance and a MySQL database instance with mounted volume for persisted data between restarts.  Also uses Docker Secrets to avoid exposing sensitive data via 'inspect'.

The latest `docker-compose.yml` and sample files are available from the image [repository](https://github.com/bubbajames-docker/sendy).  It is highly advised to clone this repository to ensure the latest samples are used.

```yaml
version: "3.7"

# Volumes for persisted data.
volumes: 
  data_sendy:
    labels: 
      co.sendy.description: "Data volume for Sendy Database."

# Secret files so they're not exposed via 'docker inspect'
secrets:
  db_password:
    file: secrets/db_password.txt
  db_root_password:
    file: secrets/db_root_password.txt      

services:
  # Database: MySQL
  db_sendy:
    hostname: db_sendy
    container_name: db_sendy
    image: mysql:5.6
    env_file: 
      - sendy.env
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
    secrets:
      - db_root_password
      - db_password      
    volumes: 
      - data_sendy:/var/lib/mysql

  # WebApp: Apache2+PHP+Sendy
  sendy:
    hostname: sendy
    container_name: sendy
    depends_on: 
      - db_sendy
    image: sendy:4.1.0
    build: 
      context: .
      # Uncomment to enabled XDEBUG build
      # target: debug
    env_file: 
      - sendy.env
    secrets:
      - db_password 
    ports:
      - 8080:80

  # Load Balancer: HAProxy
  load-balancer:
    hostname: lb_sendy
    container_name: lb_sendy
    image: lb_sendy
    build:
      context: .
      dockerfile: haproxy/Dockerfile   
    env_file: 
      - sendy.env      
    ports:
      - 80:80
      - 443:443
```

### Start the services
```console
$ docker-compose up -d
```
### Stop the services
```console
$ docker-compose down
```
# Crontab Support
Crontab is installed and configured with the following jobs.

## Scheduled Campaigns
Schedule your marketing campaigns to send at specific times in the future.  This job executes every 5 minutes to determine if any campaigns should be started.

## Autoresponders
Set up autoresponders to incoming emails.  This job executes every 1 minute to determine if any emails require an autoresponse.

## Import Lists
Import list of contacts in CSV files.  This job executes every 1 minute to determine if any Import List jobs have been created and initiate CSV file import if needed.

# Shoutouts 
## Brad Touesnard
Please read Brad Touesnard's article [How to Create Your Own SSL Certificate Authority for Local HTTPS Development](https://deliciousbrains.com/ssl-certificate-authority-for-local-https-development/) which inspired the `generateSSLCerticate.sh` script used in this project. 

# License

Please [see license](https://raw.githubusercontent.com/bubbajames-docker/sendy/master/LICENSE) in repository

As with all Docker images, these likely also contain other software that may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
