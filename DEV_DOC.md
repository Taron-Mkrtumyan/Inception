# Developer Documentation

## Repository layout

```text
.
├── Makefile
├── README.md
├── DEV_DOC.md
├── USER_DOC.md
└── srcs
    ├── .env
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

## Compose configuration

[`srcs/docker-compose.yml`](srcs/docker-compose.yml) defines:

- the `mariadb`, `wordpress`, and `nginx` services;
- the `inception` bridge network;
- the `mariadb_data` and `wordpress_data` persistent volumes;
- service startup dependencies;
- the host-side HTTPS port mapping.

The Compose file reads runtime values from [`srcs/.env`](srcs/.env). The
`LOGIN` value is supplied by the Makefile because it is used in the host
volume paths.

## Makefile workflow

The Makefile is intentionally the main developer interface:

```bash
make config
make build
make up
```

Before making changes, inspect the rendered configuration with `make config`.
After changing a Dockerfile, build the affected images again. Use `make logs`
and `make ps` to diagnose startup and dependency problems.

Targets that remove Docker resources are intentionally separate:

- `make clean` stops and removes containers.
- `make fclean` also removes project images, volumes, and orphan containers.
- `make re` performs `fclean` followed by an image build.

The Makefile does not remove `/home/<login>/data`; persistent host data must be
deleted explicitly and only after it has been backed up.

## Development workflow

1. Make a focused change in the relevant service directory.
2. Update [`srcs/.env`](srcs/.env) only for local configuration values; do not
   commit real credentials.
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

- Do not use the example credentials in a public deployment.
- Do not commit private keys, certificates, or production `.env` files.
- Keep MariaDB and PHP-FPM unexposed to the host unless there is a specific
  operational requirement.
- Replace the development self-signed TLS certificate with a trusted
  certificate for production use.
