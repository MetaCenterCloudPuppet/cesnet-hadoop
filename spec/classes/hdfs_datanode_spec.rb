require 'spec_helper'

describe 'hadoop::datanode::config', :type => 'class' do
  $test_os.each do |facts|
    os = facts['operatingsystem']
    path = $test_config_dir[os]

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

describe 'hadoop::datanode', :type => 'class' do
  $test_os.each do |facts|
    os = facts['operatingsystem']
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { should compile.with_all_deps }
      it { should contain_class('hadoop::common::config') }
      it { should contain_class('hadoop::datanode::install') }
      it { should contain_class('hadoop::datanode::config') }
      it { should contain_class('hadoop::datanode::service') }
    end
  end
end
