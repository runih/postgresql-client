# Running PostgreSQL Client using docker.

## Requirements

Docker needs to be install!

It is also recommended to have hava ~/bin in your path

```sh
export PATH=~/bin:$PATH
```

## Version supported

The following version of PostgreSQL is supported: 96, 10, 11, 12, 13, 14, 15, 16

## How to create a symlink

To create a symlink in the `~/bin` folder type the following command:

```sh
scripts/create_link.sh psql
```

This should create a link `~/bin/psql`

The default version is 16. To create an older version enter the following:

```sh
scripts/create_link.sh psql.10
```

Type the following to see if it is the right version:

```sh
psql.10 --version
```

It is also possible to run another version with out a version symlink by using the PG_VERSION environment variable.

```sh
PG_VERSION=13 psql --version
```

## Update

To update the psql wrapper run the following command:

```sh
psql --update
```

This will pull the latest from github. If there is an update to the images the current images will be deleted.

:exclamation: Make sure you don't have a psql running while doing the update!

## Environment variables

- **PG_VERSION** Specify major version
- **PG_NETWORK** Specify a docker network to connect to
- **PG_PASS** Specify a `pgpass` file that will be mounted as [~/.pgpass](~/.pgass.md)
- **PG_DATA** Specify a data directory
