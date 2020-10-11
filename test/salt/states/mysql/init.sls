mysql_package:
  pkg.installed:
    - pkgs:
      - mariadb-server
      - python3-mysqldb

mysql_service:
  service.running:
    - name: mariadb
    - require:
      - pkg: mysql_package

mysql_user:
  mysql_user.present:
    - name: {{ salt['pillar.get']('diaspora:database:username') }}
    - password: {{ salt['pillar.get']('diaspora:database:password') }}
    - require:
      - service: mysql_service
  mysql_grants.present:
    - grant: all privileges
    - database: {{ salt['pillar.get']('diaspora:database:database') }}.*
    - user: {{ salt['pillar.get']('diaspora:database:username') }}
    - require:
      - mysql_user: mysql_user
    - require_in:
      - cmd: diaspora_create_database
