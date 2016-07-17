require 'spec_helper'

describe 'hadoop::namenode::config', :type => 'class' do
  on_supported_os($test_os).each do |os,facts|
    path = $test_config_dir[facts[:operatingsystem]]

    context "on #{os}" do
      let(:facts) do
        facts
      end
      it { should compile.with_all_deps }
      it { should contain_file(path + '/core-site.xml') }
      it { should contain_file(path + '/hdfs-site.xml') }
    end
  end
end

describe 'hadoop::namenode', :type => 'class' do
  on_supported_os($test_os).each do |os,facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { should compile.with_all_deps }
      it { should contain_class('hadoop::namenode') }
      it { should contain_class('hadoop::common::config') }
      it { should contain_class('hadoop::namenode::install') }
      it { should contain_class('hadoop::namenode::config') }
      it { should contain_class('hadoop::namenode::service') }
    end
  end
end
