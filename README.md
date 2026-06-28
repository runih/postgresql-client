# PostgreSQL Client via Docker

Run PostgreSQL client tools (`psql`, `pg_dump`, `pg_dumpall`, `pg_restore`, `pg_basebackup`) inside a single Docker image built with Nix, supporting all major PostgreSQL versions.

## Requirements

- **Docker**
- **Nix** (for building the image)

It is also recommended to have `~/bin` in your path:

```sh
export PATH=~/bin:$PATH
```

## Supported versions

96, 10, 11, 12, 13, 14, 15, 16, 17, 18

> Note: PostgreSQL 9.6 only supports `psql`.

## Building the image

The first time you run a command, the image is built automatically. To build it manually:

```sh
docker load < "$(nix-build docker-image.nix --no-out-link)"
```

## How to create a symlink

To create a symlink in the `~/bin` folder:

```sh
scripts/create_link.sh psql
```

This creates `~/bin/psql`, which defaults to PostgreSQL 18. To create a version-specific symlink:

```sh
scripts/create_link.sh psql.16
```

Check the version:

```sh
psql.16 --version
```

You can also override the version at runtime using `PG_VERSION`:

```sh
PG_VERSION=13 psql --version
```

## Update

```sh
psql --update
```

This pulls the latest from GitHub and rebuilds the Docker image with Nix.

> Make sure you don't have a psql session running while updating!

## Environment variables

| Variable | Description |
|---|---|
| `PG_VERSION` | PostgreSQL major version (default: `18`) |
| `PG_NETWORK` | Docker network to connect to |
| `PG_PASS` | Path to a `pgpass` file, mounted as `~/.pgpass` |
| `PG_DATA` | Data directory (required for `pg_dump`, `pg_dumpall`, `pg_restore`, `pg_basebackup`) |
| `PG_HISTORY` | Path to psql history file (default: `~/.psql_history`) |
| `PG_CERTFOLDER` | Directory containing SSL certificates |
| `PG_SSLCERT` | SSL client certificate filename (relative to `PG_CERTFOLDER`) |
| `PG_SSLKEY` | SSL client key filename (relative to `PG_CERTFOLDER`) |
| `PG_SSLROOTCERT` | SSL root certificate filename (relative to `PG_CERTFOLDER`) |
| `PG_SSLMODE` | SSL mode passed as `PGSSLMODE` into the container (default: `require`) |
| `PG_DOCKER_CONTEXT` | Docker context to use |
