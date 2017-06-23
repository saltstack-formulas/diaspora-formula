{%- from "diaspora/map.jinja" import diaspora with context %}

include:
  - diaspora.install
  - diaspora.config

/etc/systemd/system/diaspora.service:
  file.managed:
    - user: root
    - mode: 644
    - source: salt://diaspora/files/diaspora.service
    - template: jinja
    - context:
        diaspora: {{ diaspora|json }}

diaspora_service:
  service.running:
    - name: diaspora
    - enable: True
    - requre:
      - cmd: diaspora_precompile_assets
    - watch:
      - git: diaspora_git
      - file: {{ diaspora.install_path }}/config/database.yml
      - file: {{ diaspora.install_path }}/config/diaspora.yml
