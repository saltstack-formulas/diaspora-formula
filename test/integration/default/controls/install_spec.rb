# frozen_string_literal: true

control 'diaspora' do
  impact 0.5
  title 'should be installed'

  describe directory('/srv/diaspora/.git') do
    it { should be_owned_by 'diaspora' }
  end
end
