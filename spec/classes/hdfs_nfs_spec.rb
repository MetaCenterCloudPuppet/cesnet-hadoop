require 'spec_helper'

describe 'hadoop::nfs::config', :type => 'class' do
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

describe 'hadoop::nfs', :type => 'class' do
  on_supported_os($test_os).each do |os,facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { should compile.with_all_deps }
      it { should contain_class('hadoop::nfs') }
      it { should contain_class('hadoop::common::config') }
      it { should contain_class('hadoop::nfs::install') }
      it { should contain_class('hadoop::nfs::config') }
      it { should contain_class('hadoop::nfs::service') }
      it { should contain_mount('/hdfs').with({'ensure'=>'mounted'}) }
    end
  end
end
