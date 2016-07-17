require 'spec_helper'

describe 'hadoop::httpfs::config', :type => 'class' do
  on_supported_os($test_os).each do |os,facts|
    path = $test_config_dir[facts[:operatingsystem]]
    path_httpfs = $httpfs_config_dir[facts[:operatingsystem]]

    context "on #{os}" do
      let(:facts) do
        facts
      end
      it { should compile.with_all_deps }
      it { should contain_file(path + '/core-site.xml') }
      it { should contain_file(path + '/hdfs-site.xml') }
      it { should contain_file(path_httpfs + '/httpfs-env.sh') }
      it { should contain_file(path_httpfs + '/httpfs-site.xml') }
    end
  end
end

describe 'hadoop::httpfs', :type => 'class' do
  on_supported_os($test_os).each do |os,facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { should compile.with_all_deps }
      it { should contain_class('hadoop::httpfs') }
      it { should contain_class('hadoop::common::config') }
      it { should contain_class('hadoop::httpfs::install') }
      it { should contain_class('hadoop::httpfs::config') }
      it { should contain_class('hadoop::httpfs::service') }
    end
  end
end
