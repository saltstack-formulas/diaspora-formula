{%- if grains.get('osfinger', grains.os) == 'Ubuntu-18.04' %}
redis_config:
  file.replace:
    - name: '/etc/redis/redis.conf'
    - pattern: '^bind .*$'
    - repl: 'bind 127.0.0.1'
    - require:
      - pkg: redis_package
    - require_in:
      - service: redis_service
{%- endif %}
