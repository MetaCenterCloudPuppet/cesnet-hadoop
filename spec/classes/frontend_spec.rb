require 'spec_helper'

describe 'hadoop::frontend::config', :type => 'class' do
  on_supported_os($test_os).each do |os,facts|
    path = $test_config_dir[facts[:operatingsystem]]

    context "on #{os}" do
      let(:facts) do
        facts
      end
      it { should compile.with_all_deps }
      it { should contain_file(path + '/core-site.xml') }
      it { should contain_file(path + '/hdfs-site.xml') }
      it { should contain_file(path + '/mapred-site.xml') }
      it { should contain_file(path + '/yarn-site.xml') }
    end
  end
end

describe 'hadoop::frontend', :type => 'class' do
  on_supported_os($test_os).each do |os,facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { should compile.with_all_deps }
      it { should contain_class('hadoop::frontend') }
      it { should contain_class('hadoop::frontend::install') }
      it { should contain_class('hadoop::frontend::config') }
    end
  end
end
