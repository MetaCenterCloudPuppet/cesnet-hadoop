require 'spec_helper'

describe 'hadoop::user', :type => 'define' do
  on_supported_os($test_os).each do |os,facts|
    context "on #{os}" do
      let(:facts) {
        facts
      }
      let(:params) {{
        :hdfs      => true,
        :shell     => true,
        :touchfile => 'user-created',
      }}
      let(:title) { 'hawking' }

      it { should compile.with_all_deps }
      it { should contain_user('hawking').with({
        'shell' => '/bin/bash',
      })}
      it { should contain_hadoop__mkdir('/user/hawking') }
    end
  end
end
