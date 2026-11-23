# Developer Documentation

## Repository layout

The working directory after local setup contains:

```text
.
├── .gitignore
├── Makefile
├── README.md
├── DEV_DOC.md
├── USER_DOC.md
└── srcs
    ├── .env.example
    ├── .env              # Local configuration, ignored by Git
    ├── docker-compose.yml
    └── requirements
        ├── mariadb
        │   ├── Dockerfile
        │   ├── conf
        │   └── tools
        ├── nginx
        │   ├── Dockerfile
        │   ├── nginx.conf
        │   └── tools
        └── wordpress
            ├── Dockerfile
            ├── confs
            └── tools
```

## Local setup

Use a Linux VM with Docker Engine, Docker Compose v2, and GNU Make installed.
Run the following from the repository root on a new clone, when `srcs/.env`
does not already exist:

```bash
cp srcs/.env.example srcs/.env
```

Fill in `SQL_PASSWORD`, `SQL_ROOT_PASSWORD`, `ADMIN_PASSWORD`, and
`USER_PASSWORD` locally. Track variable names and non-sensitive defaults in
[`srcs/.env.example`](srcs/.env.example); `.gitignore` excludes `srcs/.env`.

The Makefile defaults `LOGIN` to `tmkrtumy`. If needed, override it on every
Make invocation with `make LOGIN=your-login <target>`. Ensure the VM user
can create `/home/<login>/data/mariadb` and `/home/<login>/data/wordpress`.
Configure `tmkrtumy.42.fr` to resolve to the VM. A domain change also requires
updating `DOMAIN_NAME` in `srcs/.env`, Nginx's `server_name`, and the
certificate subject in `nginx_setup.sh`, then rebuilding and recreating
the stack.

## Service responsibilities

### MariaDB

The MariaDB image installs the database server, copies its server
configuration, and runs `mariadb_setup.sh` as its entrypoint. The setup script
initializes the data directory on first use, creates the WordPress database
and application user, then starts `mysqld`.

### WordPress

The WordPress image installs PHP-FPM and the PHP extensions required by the
application. Its setup script downloads WP-CLI when necessary, downloads
WordPress, creates `wp-config.php`, and performs the initial site installation.
PHP-FPM listens on the internal port `9000`.

### Nginx

The Nginx image installs Nginx and OpenSSL. Its setup script prepares the TLS
certificate directory before starting Nginx. Nginx listens on port `443`,
serves WordPress files, and forwards PHP requests to `wordpress:9000`.
Access logs go to `/dev/stdout`; errors at warning level or higher go to
`/dev/stderr`, allowing Docker to collect them.

## Compose configuration

[`srcs/docker-compose.yml`](srcs/docker-compose.yml) defines:

- the `mariadb`, `wordpress`, and `nginx` services;
- the `inception` bridge network;
- the `mariadb_data` and `wordpress_data` persistent volumes;
- service startup dependencies;
- the host-side HTTPS port mapping;
- the `local` logging driver for each service, with `max-size: "10m"` and
  `max-file: "3"` for automatic rotation.

The Compose file reads runtime values from the ignored local `srcs/.env`. The
`LOGIN` value is supplied by the Makefile because it is used in the host
volume paths.

Rotation applies to container standard output and standard error captured
by Docker, retaining roughly 30 MB per container before compression. It
does not rotate separate files written inside containers or data volumes.

## Makefile workflow

The Makefile is intentionally the main developer interface:

```bash
make config
make build
make up
```

Before making changes, inspect the rendered configuration with `make config`.
Its output includes resolved environment values, so keep it local. To
validate without printing those values, use:

```bash
LOGIN=tmkrtumy docker compose --env-file srcs/.env \
  -f srcs/docker-compose.yml config --quiet
```

Use the same `LOGIN` value as your Make commands. After changing a Dockerfile
or configuration copied into an image, rebuild the affected images. Recreate
containers after changing logging settings. To apply both types of change:

```bash
make build
make down
make up
```

Use `make logs` and `make ps` to diagnose startup and dependency problems.

Targets that remove Docker resources are intentionally separate:

- `make clean` stops and removes containers and the project network.
- `make fclean` also removes service images, volumes, and project orphan
  containers.
- `make re` performs `fclean` followed by an image build; run `make up`
  afterward to start the services.

The Makefile keeps `/home/<login>/data` and Docker build cache. Persistent
host data must be deleted explicitly and only after it has been backed up.

For resource checks in the VM, use `docker stats --no-stream` for running
container memory usage, `docker system df` for Docker disk usage, and
`df -h` for filesystem free space. BuildKit manages build cache through
garbage collection; global cache pruning is separate from project cleanup.

## Development workflow

1. Make a focused change in the relevant service directory.
2. Update `srcs/.env` for local configuration values. When adding variables,
   also update `srcs/.env.example` with empty password values; do not commit
   local credentials.
3. Run `make config`.
4. Build and start with `make build` and `make up`.
5. Check `make ps` and inspect `make logs`.
6. Exercise the website through the HTTPS endpoint.
7. Review the diff before committing.

Configuration files copied into images must match the paths used by their
Dockerfiles. Setup scripts must remain executable and should fail clearly
when a required initialization step cannot complete.

## Networking and storage

Containers communicate by Compose service name on the `inception` network:

```text
nginx -> wordpress:9000
wordpress -> mariadb
```

Only Nginx publishes a host port. MariaDB and PHP-FPM remain internal
services. WordPress files are shared with Nginx through the read-only
`wordpress_data` mount, while MariaDB uses `mariadb_data`.

## Security notes

- Set all passwords in the local `srcs/.env`; the template leaves them empty.
- Do not commit local `.env` files, passwords, private keys, or certificates.
- Keep MariaDB and PHP-FPM unexposed to the host unless there is a specific
  operational requirement.
- Replace the development self-signed TLS certificate with a trusted
  certificate for production use.
