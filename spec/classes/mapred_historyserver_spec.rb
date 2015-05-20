require 'spec_helper'

describe 'hadoop::historyserver::config', :type => 'class' do
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
      it { should contain_file(path + '/mapred-site.xml') }
      it { should contain_file(path + '/yarn-site.xml') }
    end
  end
end

describe 'hadoop::historyserver', :type => 'class' do
  $test_os.each do |facts|
    os = facts['operatingsystem']
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { should compile.with_all_deps }
      it { should contain_class('hadoop::common::config') }
      it { should contain_class('hadoop::historyserver::install') }
      it { should contain_class('hadoop::historyserver::config') }
      it { should contain_class('hadoop::historyserver::service') }
    end
  end
end
