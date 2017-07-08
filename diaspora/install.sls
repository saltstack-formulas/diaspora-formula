{%- from "diaspora/map.jinja" import diaspora with context %}
{%- set environment = diaspora.configuration.server.rails_environment %}

include:
  - diaspora.config

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

redis_service:
  service.running:
    - name: {{ diaspora.redis_service }}
{%- endif %}

{% set home = diaspora.user.home if 'home' in diaspora.user else '/home/' + diaspora.user.username %}
diaspora_user:
  user.present:
    - name: {{ diaspora.user.username }}
  {%- if 'shell' in diaspora.user %}
    - shell: {{ diaspora.user.shell }}
  {%- endif %}
    - home: {{ home }}

diaspora_rvm_gpg_key:
  cmd.run:
    - name: gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
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

diaspora_reset_schema.rb:
  cmd.run:
    - name: git checkout db/schema.rb
    - runas: {{ diaspora.user.username }}
    - cwd: {{ diaspora.install_path }}
    - onlyif: git rev-parse && ! git diff --name-only --exit-code db/schema.rb

diaspora_git:
  git.latest:
    - name: {{ diaspora.repository }}
    - rev: {{ diaspora.version }}
    - target: {{ diaspora.install_path }}
    - user: {{ diaspora.user.username }}
    - force_fetch: True
    - require:
      - file: diaspora_install_directory
      - cmd: diaspora_reset_schema.rb
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

diaspora_bundle_install:
  cmd.run:
    - name: rvm ruby-{{ diaspora.ruby_version }}@diaspora do bin/bundle install --jobs $(nproc) --deployment --without test development --with {{ diaspora.database.type }}
    - runas: {{ diaspora.user.username }}
    - cwd: {{ diaspora.install_path }}
    - unless: rvm ruby-{{ diaspora.ruby_version }}@diaspora do bin/bundle check
    - env:
      - RAILS_ENV: {{ environment }}
    - require:
      - rvm: diaspora_rvm_gemset
      - cmd: diaspora_rvm_ruby_version_alias
      - git: diaspora_git

diaspora_create_database:
  cmd.run:
    - name: rvm ruby-{{ diaspora.ruby_version }}@diaspora do bin/rake db:create db:schema:load
    - runas: {{ diaspora.user.username }}
    - cwd: {{ diaspora.install_path }}
    - onlyif: rvm ruby-{{ diaspora.ruby_version }}@diaspora do bin/rails runner "ActiveRecord::Base.connection" |& grep "database \"{{ diaspora.database.database }}\" does not exist (ActiveRecord::NoDatabaseError)"
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
    - onlyif: rvm ruby-{{ diaspora.ruby_version }}@diaspora do bin/rake db:migrate:status | grep -oE "^\s+down"
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
