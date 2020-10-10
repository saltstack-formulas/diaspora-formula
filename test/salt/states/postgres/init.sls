{% set pkg = salt['grains.filter_by']({
    'Debian': 'postgresql',
    'RedHat': 'postgresql-server',
}) -%}

pgsql_package:
  pkg.installed:
    - name: {{ pkg }}

{%- if grains.os_family == 'RedHat' %}
pgsql_initdb:
  cmd.run:
    - name: postgresql-setup initdb
    - require:
      - pkg: pgsql_package
pgsql_pg_hba_redhat:
  file.replace:
    - name: /var/lib/pgsql/data/pg_hba.conf
    - pattern: ' ident'
    - repl: ' md5'
    - require:
      - cmd: pgsql_initdb_redhat
    - require_in:
      - service: pgsql_service
{%- endif %}

pgsql_service:
  service.running:
    - name: postgresql
    - require:
      - pkg: pgsql_package

pgsql_user:
  postgres_user.present:
    - name: {{ salt['pillar.get']('diaspora:database:username') }}
    - password: {{ salt['pillar.get']('diaspora:database:password') }}
    - createdb: True
    - require:
      - service: pgsql_service
    - require_in:
      - cmd: diaspora_create_database
