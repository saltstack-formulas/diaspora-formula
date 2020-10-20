# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import diaspora with context %}

{{ diaspora.install_path }}/config/database.yml:
  file.managed:
    - user: {{ diaspora.user.username }}
    - mode: 600
    - source: salt://diaspora/files/database.yml
    - template: jinja
    - context:
        database: {{ diaspora.database|json }}

{{ diaspora.install_path }}/config/diaspora.yml:
  file.managed:
    - user: {{ diaspora.user.username }}
    - mode: 600
    - source: salt://diaspora/files/diaspora.yml
    - template: jinja
    - context:
        configuration: {{ diaspora.configuration|json }}
