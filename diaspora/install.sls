# -*- coding: utf-8 -*-
# vim: ft=sls

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import diaspora with context %}
{%- set environment = diaspora.configuration.server.rails_environment %}

include:
  - {{ tplroot }}.config

{%- if grains.os == 'CentOS' and grains.osmajorrelease >= 8 %}
diaspora_centos_enable_powertools_repo:
  file.replace:
    - name: /etc/yum.repos.d/CentOS-PowerTools.repo
    - pattern: '^enabled=[0,1]'
    - repl: 'enabled=1'
    - require_in:
      - pkg: diaspora_dependencies
{%- endif %}

{%- if grains.os_family == 'Arch' %}
diaspora_arch_install_devel_group:
  pkg.group_installed:
    - name: base-devel
    - require_in:
      - pkg: diaspora_dependencies
{%- endif %}

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

{% set home = diaspora.user.get('home', '/home/' + diaspora.user.username) -%}
diaspora_user:
  user.present:
    - name: {{ diaspora.user.username }}
  {%- if 'shell' in diaspora.user %}
    - shell: {{ diaspora.user.shell }}
  {%- endif %}
    - home: {{ home }}

diaspora_rvm_gpg_key_mpapis:
  cmd.run:
    - name: gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    - unless: gpg --list-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    - runas: {{ diaspora.user.username }}
    - require:
      - user: diaspora_user

diaspora_rvm_gpg_key_pkuczynski:
  cmd.run:
    - name: gpg --keyserver hkp://keys.gnupg.net --recv-keys 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    - unless: gpg --list-keys 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
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
      - cmd: diaspora_rvm_gpg_key_mpapis
      - cmd: diaspora_rvm_gpg_key_pkuczynski

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
    - force_fetch: True
    - require:
      - file: diaspora_install_directory
    - require_in:
      - file: {{ diaspora.install_path }}/config/database.yml

diaspora_rvm_ruby_version_alias:
  cmd.run:
    - name: rvm alias create $(cat {{ diaspora.install_path }}/.ruby-version) ruby-{{ diaspora.ruby_version }}
    - runas: {{ diaspora.user.username }}
    - unless: rvm alias list | grep "$(cat {{ diaspora.install_path }}/.ruby-version) => ruby-{{ diaspora.ruby_version }}"
    - require:
      - rvm: diaspora_rvm_ruby
      - git: diaspora_git

diaspora_rails_env_for_login_shell:
  file.replace:
  {%- if 'shell' in diaspora.user and diaspora.user.shell == "/bin/zsh" %}
    - name: {{ home }}/.zshrc
  {%- else %}
    - name: {{ home }}/.bashrc
  {%- endif %}
    - pattern: "export RAILS_ENV=\"[a-z]*\""
    - repl: "export RAILS_ENV=\"{{ environment }}\""
    - append_if_not_found: True
    - not_found_content: "\nexport RAILS_ENV=\"{{ environment }}\""
    - ignore_if_missing: True
    - require:
      - rvm: diaspora_rvm_ruby

diaspora_configure_bundler:
  cmd.run:
    - name: rvm ruby-{{ diaspora.ruby_version }}@diaspora do script/configure_bundler
    - runas: {{ diaspora.user.username }}
    - cwd: {{ diaspora.install_path }}
    - env:
      - RAILS_ENV: {{ environment }}
    - require:
      - gem: diaspora_install_bundler
      - cmd: diaspora_rvm_ruby_version_alias
      - file: {{ diaspora.install_path }}/config/database.yml
    - onchanges:
      - git: diaspora_git

diaspora_bundle_install:
  cmd.run:
    - name: rvm ruby-{{ diaspora.ruby_version }}@diaspora do bin/bundle install --full-index
    - runas: {{ diaspora.user.username }}
    - cwd: {{ diaspora.install_path }}
    - unless: bash -c 'cd {{ diaspora.install_path }}; RAILS_ENV={{ environment }} rvm ruby-{{ diaspora.ruby_version }}@diaspora do bin/bundle check'
    - env:
      - RAILS_ENV: {{ environment }}
    - require:
      - cmd: diaspora_configure_bundler

diaspora_create_database:
  cmd.run:
    - name: rvm ruby-{{ diaspora.ruby_version }}@diaspora do bin/rake db:create db:migrate
    - runas: {{ diaspora.user.username }}
    - cwd: {{ diaspora.install_path }}
    - onlyif: >-
        bash -c 'cd {{ diaspora.install_path }}; RAILS_ENV={{ environment }}
        rvm ruby-{{ diaspora.ruby_version }}@diaspora do bin/rails runner "ActiveRecord::Base.connection"'
        |& grep -E "(Unknown database '{{ diaspora.database.database }}'|database \"{{ diaspora.database.database }}\" does not exist)"
        | grep "ActiveRecord::NoDatabaseError"
    - env:
      - RAILS_ENV: {{ environment }}
    - require:
      - cmd: diaspora_bundle_install
      - file: {{ diaspora.install_path }}/config/database.yml
      - file: {{ diaspora.install_path }}/config/diaspora.yml
    - onchanges:
      - git: diaspora_git

diaspora_migrate_database:
  cmd.run:
    - name: rvm ruby-{{ diaspora.ruby_version }}@diaspora do bin/rake db:migrate
    - runas: {{ diaspora.user.username }}
    - cwd: {{ diaspora.install_path }}
    - onlyif: >-
        bash -c 'cd {{ diaspora.install_path }}; RAILS_ENV={{ environment }}
        rvm ruby-{{ diaspora.ruby_version }}@diaspora do bin/rake db:migrate:status' | grep -oE "^\s+down"
    - env:
      - RAILS_ENV: {{ environment }}
    - require:
      - cmd: diaspora_create_database
    - onchanges:
      - git: diaspora_git

diaspora_precompile_assets:
  cmd.run:
    - name: rvm ruby-{{ diaspora.ruby_version }}@diaspora do bin/rake assets:precompile
    - runas: {{ diaspora.user.username }}
    - cwd: {{ diaspora.install_path }}
    - env:
      - RAILS_ENV: {{ environment }}
    - require:
      - cmd: diaspora_migrate_database
    - onchanges:
      - git: diaspora_git
