# User Documentation

This guide covers running and using the Inception WordPress stack.

## Before starting

Install Docker Engine, Docker Compose v2, and Make. Run commands from the
repository root.

Review [`srcs/.env`](srcs/.env) before starting. In particular, change the
database and WordPress passwords if this installation is accessible by other
people.

The Compose file uses `${LOGIN}` to locate persistent storage. The Makefile
sets it to the current system username automatically. To use another home
directory, pass it explicitly:

```bash
make LOGIN=your-login
```

## Starting the website

Validate the rendered Compose configuration and start the stack:

```bash
make config
make
```

The first build can take several minutes because the images install Nginx,
PHP-FPM, WordPress dependencies, and MariaDB packages.

View status and logs:

```bash
make ps
make logs
```

Nginx listens on HTTPS port `443`. Open the domain configured by
`DOMAIN_NAME` in [`srcs/.env`](srcs/.env):

```text
https://<domain-name>
```

The development certificate is self-signed and may need to be accepted in
the browser.

## Stopping and restarting

Stop containers without deleting them:

```bash
make stop
```

Start existing containers again:

```bash
make start
```

Remove the containers:

```bash
make down
```

To restart the complete Compose application:

```bash
make restart
```

## Persistent data

The website and database data are kept on the host at:

```text
/home/<login>/data/wordpress
/home/<login>/data/mariadb
```

These directories are created by `make`, `make up`, and `make build`.
Removing containers does not remove these directories.

`make fclean` removes the Compose project's containers, images, Docker
volumes, and orphan containers. Back up the host data before performing
maintenance or deleting it manually.

## Troubleshooting

### Check service state

```bash
make ps
```

### Inspect logs

```bash
make logs
```

For a single service, use Docker Compose directly:

```bash
LOGIN="$(id -un)" docker compose \
  --env-file srcs/.env \
  -f srcs/docker-compose.yml \
  logs nginx
```

Replace `nginx` with `wordpress` or `mariadb` as needed.

### Rebuild images

After changing a Dockerfile or service configuration:

```bash
make build
make up
```

For a clean image rebuild:

```bash
make re
```

### Port 443 is already in use

Stop the process or service using port 443, or change the host-side port
mapping in [`srcs/docker-compose.yml`](srcs/docker-compose.yml). The
container continues to listen on port 443.
