# diaspora-formula

A saltstack formula to install and configure the distributed social network, [diaspora*](https://diasporafoundation.org/).

> Note: See the full [Salt Formulas installation and usage instructions](http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html).
>
> This formula only manages diaspora. You are responsible for installing/configuring PostgreSQL or MariaDB as appropriate.

## Available states

### `diaspora`

Install, configure and run diaspora as a service.

### `diaspora.install`

Installs diaspora from github.

### `diaspora.config`

Configures diaspora.

### `diaspora.service`

Creates a service for diaspora and runs it.
