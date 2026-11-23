# User Documentation

This guide covers running and using the Inception WordPress stack.

## Before starting

Install Docker Engine, Docker Compose v2, and Make inside the Linux VM.
Run commands from the repository root in that VM.

On a new clone, create `srcs/.env` from the tracked template if the local
file does not already exist:

```bash
cp srcs/.env.example srcs/.env
```

Fill in all four password values in `srcs/.env` before starting. The local
file is ignored by Git; keep passwords out of the tracked
[`srcs/.env.example`](srcs/.env.example).

The Compose file uses `${LOGIN}` to locate persistent storage. The Makefile
defaults it to `tmkrtumy`. To use another home directory, pass the desired
login on each Make invocation:

```bash
make LOGIN=your-login
```

The supplied domain is `tmkrtumy.42.fr`; configure it to resolve to your VM.
Changing `LOGIN` changes storage paths only. See the README configuration
section before changing the domain.

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

`make fclean` removes the Compose project's containers, network, service
images, Docker volumes, and orphan containers. It keeps the host data
directories and Docker build cache. Back up the host data before performing
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
LOGIN=tmkrtumy docker compose \
  --env-file srcs/.env \
  -f srcs/docker-compose.yml \
  logs nginx
```

Replace `nginx` with `wordpress` or `mariadb` as needed. If you overrode
`LOGIN` when starting the stack, use that same value here.

Nginx access logs and errors at warning level or higher are included.
Docker automatically rotates captured logs for each service, retaining up
to three files of about 10 MB each before compression. Older logs are
removed as the limit is reached.

### Rebuild images

After changing a Dockerfile or service configuration:

```bash
make build
make up
```

For a clean image rebuild:

```bash
make re
make up
```

`make re` rebuilds the images but does not start containers.

### Port 443 is already in use

Stop the process or service using port 443, or change the host-side port
mapping in [`srcs/docker-compose.yml`](srcs/docker-compose.yml). The
container continues to listen on port 443.
