_This project has been created as part of the 42 curriculum by tmkrtumy._

# Inception

## Description

Inception is a 42 project that builds a small WordPress infrastructure with
Docker Compose. Its goal is to create each service from a project-owned
Dockerfile and run every service in its own container:

- **Nginx** is the only public entry point and terminates HTTPS on port 443.
  TLS 1.2 and TLS 1.3 are enabled.
- **WordPress** runs PHP-FPM only and is not exposed directly to the host.
- **MariaDB** provides the WordPress database and is reachable only through
  the private Docker network.

The project sources are organised as follows:

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs
    ├── .env
    ├── docker-compose.yml
    └── requirements
        ├── mariadb
        ├── nginx
        └── wordpress
```

Each service directory contains its Dockerfile, configuration, and startup
script. The Compose file creates the `inception` bridge network and connects
the three containers by service name:

```text
nginx -> wordpress:9000 -> mariadb:3306
```

The two persistent data stores are the MariaDB database files and the
WordPress website files. They are configured as Docker volumes and are
intended to persist under:

```text
/home/<login>/data/mariadb
/home/<login>/data/wordpress
```

Replace `<login>` with the 42 login used for the installation.

## Design choices and comparisons

### Docker versus virtual machines

A virtual machine includes a complete guest operating system for each
workload. Docker containers share the host kernel, start faster, and use fewer
resources while still isolating processes, filesystems, and networks. This
project uses containers because Nginx, PHP-FPM, and MariaDB are separate
services with independent lifecycles, not complete operating systems.

### Secrets versus environment variables

Environment variables are convenient for non-sensitive configuration such as
the domain name, site title, and service names. They are also visible through
container metadata and should not be treated as a secure secret store.
Docker secrets are preferable for production passwords because they are
provided as files with controlled access. This project uses the required
[`srcs/.env`](srcs/.env) file for local configuration; replace its example
credentials and keep real credentials out of version control.

### Docker network versus host network

A user-defined Docker bridge network gives containers private DNS-based
service discovery and limits exposure to explicitly published ports. Host
networking removes that isolation and makes containers share the host network
namespace. This project uses the `inception` bridge network and publishes
only Nginx port 443.

### Docker volumes versus bind mounts

Docker volumes are managed by Docker and can be backed up, inspected, and
attached without coupling the Compose definition to arbitrary host paths.
Bind mounts directly expose a chosen host directory and are useful when a
host path must be controlled explicitly, but they have weaker portability and
permission isolation.

This project declares named volumes for the database and WordPress files and
configures their host-side storage under `/home/<login>/data`. Verify the
volume driver configuration during evaluation because the subject requires
named volumes and does not allow bind mounts for these persistent stores.

## Instructions

### Prerequisites

- A Linux virtual machine, as required by the subject
- Docker Engine
- Docker Compose v2 (`docker compose`)
- GNU Make
- Permission to create `/home/<login>/data`
- The domain `<login>.42.fr` configured to resolve to the local machine

### Configuration

Review [`srcs/.env`](srcs/.env) before starting. It contains:

- `DOMAIN_NAME` and the WordPress site title
- MariaDB database and application-user settings
- WordPress administrator and author settings

The administrator username must not contain `admin` or `administrator`, as
required by the subject. The example uses `iamtheowner`. Do not publish real
passwords, API keys, or certificates in the repository. For a deployment
requiring stronger protection, use Docker secrets and update the service
configuration accordingly.

The Makefile defaults `LOGIN` to the current system username. Override it when
necessary:

```bash
make LOGIN=someuser
```

### Build and start

From the repository root:

```bash
make config
make build
make up
```

`make config` renders and validates the Compose configuration. `make build`
builds the three project-owned images, and `make up` creates the data
directories and starts the stack in the background.

Open the configured site at:

```text
https://<domain-name>
```

The Nginx container generates a self-signed development certificate, so the
browser will display a certificate warning. The WordPress administration
panel is available at:

```text
https://<domain-name>/wp-admin/
```

Use the administrator credentials from the local `.env` configuration.

### Service management

| Command | Purpose |
| --- | --- |
| `make build` | Build all service images |
| `make up` | Prepare storage and start the stack |
| `make start` | Start existing containers |
| `make stop` | Stop running containers |
| `make restart` | Recreate the stack |
| `make down` | Stop and remove containers |
| `make logs` | Follow logs from all services |
| `make ps` | Show service status |
| `make config` | Render and validate Compose configuration |
| `make clean` | Stop and remove containers |
| `make fclean` | Remove containers, images, volumes, and orphans |
| `make re` | Remove resources and rebuild images |

`make fclean` removes Docker resources associated with this Compose project.
It does not delete the host data directories. Back up persistent data before
performing maintenance.

### Troubleshooting

Check service state and logs first:

```bash
make ps
make logs
```

If a service does not start, rebuild after changing its Dockerfile or
configuration:

```bash
make build
make up
```

If port 443 is already in use, stop the conflicting service or change the
host-side port mapping in [`srcs/docker-compose.yml`](srcs/docker-compose.yml).
The container continues to listen on port 443.

## Resources

- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker volumes documentation](https://docs.docker.com/engine/storage/volumes/)
- [Docker networking documentation](https://docs.docker.com/engine/network/)
- [Nginx documentation](https://nginx.org/en/docs/)
- [PHP-FPM documentation](https://www.php.net/manual/en/install.fpm.php)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [WP-CLI documentation](https://make.wordpress.org/cli/handbook/)
- [WordPress administration documentation](https://wordpress.org/documentation/)

### AI usage

AI assistance was used as a development aid, not as a replacement for
understanding or verification. It was used for:

- reviewing the Docker Compose service relationships, health checks, and
  volume declarations;
- identifying Dockerfile path mismatches and package-version compatibility
  issues;
- checking shell-script and Nginx configuration syntax;
- improving the structure and completeness of the project documentation;
- suggesting focused validation commands for Compose configuration, image
  builds, and service startup.

The project files, configuration decisions, and validation results were
reviewed in the repository. The mandatory subject requirements remain the
source of truth for the final evaluation.

## Additional documentation

- [`USER_DOC.md`](USER_DOC.md) explains operation, credentials, website access,
  and troubleshooting for users and administrators.
- [`DEV_DOC.md`](DEV_DOC.md) explains the repository layout, service
  responsibilities, development workflow, and persistence model.
