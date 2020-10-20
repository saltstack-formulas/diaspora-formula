# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import diaspora with context %}

include:
  - {{ tplroot }}.install
  - {{ tplroot }}.config

/etc/systemd/system/diaspora-sidekiq.service:
  file.managed:
    - user: root
    - mode: 644
    - source: salt://diaspora/files/diaspora-sidekiq.service
    - template: jinja
    - context:
        diaspora: {{ diaspora|json }}

/etc/systemd/system/diaspora-web.service:
  file.managed:
    - user: root
    - mode: 644
    - source: {{ diaspora.systemd.web_template }}
    - template: jinja
    - context:
        diaspora: {{ diaspora|json }}

/etc/systemd/system/diaspora.target:
  file.managed:
    - user: root
    - mode: 644
    - source: salt://diaspora/files/diaspora.target
    - template: jinja
    - context:
        diaspora: {{ diaspora|json }}

{%- if diaspora.install_redis %}
redis_service:
  service.running:
    - name: {{ diaspora.redis_service }}
    - require:
      - pkg: redis_package
    - require_in:
      - service: diaspora_service
{%- endif %}

diaspora_sidekiq_service:
  service.enabled:
    - name: diaspora-sidekiq
    - require:
      - file: /etc/systemd/system/diaspora-sidekiq.service

diaspora_web_service:
  service.enabled:
    - name: diaspora-web
    - require:
      - file: /etc/systemd/system/diaspora-web.service

diaspora_service:
  service.running:
    - name: diaspora.target
    - enable: True
    - require:
      - cmd: diaspora_precompile_assets
      - file: /etc/systemd/system/diaspora.target
      - service: diaspora_sidekiq_service
      - service: diaspora_web_service

diaspora_sidekiq_service_restart:
  service.running:
    - name: diaspora-sidekiq.service
    - require:
      - service: diaspora_service
    - watch:
      - git: diaspora_git
      - file: {{ diaspora.install_path }}/config/database.yml
      - file: {{ diaspora.install_path }}/config/diaspora.yml

diaspora_web_service_restart:
  service.running:
    - name: diaspora-web.service
    - reload: True
    - unless: >-
        systemctl is-active diaspora-web.service | grep -E 'activ(e|ating)' &&
        test $(ps -p $(systemctl show --property MainPID diaspora-web.service | cut -d= -f2) -oetimes=) -lt 10
    - require:
      - service: diaspora_service
    - watch:
      - service: diaspora_sidekiq_service_restart
