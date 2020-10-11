# frozen_string_literal: true

control 'diaspora webserver' do
  impact 0.5
  title 'should be working'

  https_header = { 'X-Forwarded-Proto': 'https' }

  30.times do
    break if port(3000).listening?

    puts "Port 3000 isn't ready, retrying.."
    sleep 1
  end

  describe http('http://localhost:3000', headers: https_header) do
    its('status') { should cmp 302 }
    its('headers.Location') { should cmp 'https://localhost:3000/podmin' }
  end

  describe http('http://localhost:3000/podmin', headers: https_header) do
    its('status') { should cmp 200 }
  end
end
