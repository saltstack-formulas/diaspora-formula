# frozen_string_literal: true

control 'diaspora configuration' do
  title 'should match desired lines'

  describe file('/srv/diaspora/config/database.yml') do
    it { should be_file }
    it { should be_owned_by 'diaspora' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0600' }

    its('content') do
      should include '# This file is managed by Salt! Do not edit by hand!'
    end

    its('content') do
      should include <<~CONTENT
        postgresql: &postgresql
          adapter: postgresql
          host: localhost
          port: 5432
          username: diaspora
          password: "secret"
          encoding: unicode
      CONTENT
    end
  end

  ca_file =
    case platform[:family]
    when 'debian'
      '/etc/ssl/certs/ca-certificates.crt'
    when 'redhat'
      '/etc/pki/tls/certs/ca-bundle.crt'
    end

  describe file('/srv/diaspora/config/diaspora.yml') do
    it { should be_file }
    it { should be_owned_by 'diaspora' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0600' }

    its('content') do
      should include '# This file is managed by Salt! Do not edit by hand!'
    end

    its('content') { should include 'rails_environment: production' }
    its('content') { should include "certificate_authorities: #{ca_file}" }
  end
end
