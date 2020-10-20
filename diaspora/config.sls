# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import diaspora with context %}
{%- from tplroot ~ "/libtofs.jinja" import files_switch with context %}

{{ diaspora.install_path }}/config/database.yml:
  file.managed:
    - user: {{ diaspora.user.username }}
    - mode: 600
    - source: {{ files_switch(['database.yml'],
                              lookup='database_config'
                 )
              }}
    - template: jinja
    - context:
        database: {{ diaspora.database|json }}

{{ diaspora.install_path }}/config/diaspora.yml:
  file.managed:
    - user: {{ diaspora.user.username }}
    - mode: 600
    - source: {{ files_switch(['diaspora.yml'],
                              lookup='diaspora_config'
                 )
              }}
    - template: jinja
    - context:
        configuration: {{ diaspora.configuration|json }}
