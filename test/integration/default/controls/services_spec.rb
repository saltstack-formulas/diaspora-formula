# frozen_string_literal: true

control 'diaspora services' do
  impact 0.5
  title 'should be running and enabled'

  services = ['diaspora-sidekiq.service', 'diaspora-web.service']

  services.each do |service_name|
    describe service(service_name) do
      it { should be_installed }
      it { should be_enabled }
      it { should be_running }
    end
  end
end
