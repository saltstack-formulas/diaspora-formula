{%- from "diaspora/map.jinja" import diaspora with context %}

diaspora_dependencies:
  pkg.installed:
    - pkgs: {{ diaspora.dependencies|json }}
    - require:
      - pkg: diaspora_database_dependency

diaspora_database_dependency:
  pkg.installed:
  {%- if diaspora.database.type == "mysql" %}
    - name: {{ diaspora.mysql_package }}
  {%- else %}
    - name: {{ diaspora.postgresql_package }}
  {%- endif %}

{%- if diaspora.install_redis %}
redis_package:
  pkg.installed:
    - name: {{ diaspora.redis_package }}
{%- endif %}

diaspora_user:
  user.present:
    - name: {{ diaspora.user.username }}
  {%- if 'shell' in diaspora.user %}
    - shell: {{ diaspora.user.shell }}
  {%- endif %}
  {%- if 'home' in diaspora.user %}
    - home: {{ diaspora.user.home }}
  {%- endif %}

diaspora_rvm_gpg_key:
  cmd.run:
    - name: gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    - unless: gpg --list-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    - runas: {{ diaspora.user.username }}
    - require:
      - user: diaspora_user

diaspora_rvm_ruby:
  rvm.installed:
    - name: ruby-{{ diaspora.ruby_version }}
    - user: {{ diaspora.user.username }}
    - default: True
    - require:
      - pkg: diaspora_dependencies
      - cmd: diaspora_rvm_gpg_key

diaspora_rvm_gemset:
  rvm.gemset_present:
    - name: diaspora
    - ruby: ruby-{{ diaspora.ruby_version }}
    - user: {{ diaspora.user.username }}
    - require:
      - rvm: diaspora_rvm_ruby

diaspora_install_bundler:
  gem.installed:
    - name: bundler
    - user: {{ diaspora.user.username }}
    - ruby: ruby-{{ diaspora.ruby_version }}@diaspora
    - require:
      - rvm: diaspora_rvm_gemset

diaspora_install_directory:
  file.directory:
    - name: {{ diaspora.install_path }}
    - user: {{ diaspora.user.username }}
    - mode: 755
    - require:
      - user: diaspora_user

diaspora_git:
  git.latest:
    - name: {{ diaspora.repository }}
    - rev: {{ diaspora.version }}
    - target: {{ diaspora.install_path }}
    - user: {{ diaspora.user.username }}
    - require:
      - file: diaspora_install_directory
