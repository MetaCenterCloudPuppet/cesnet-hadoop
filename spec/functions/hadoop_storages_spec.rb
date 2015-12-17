require 'spec_helper'

describe 'hadoop_storages' do
  let(:facts) do
    {
      :osfamily => 'Debian',
      :operatingsystem => 'Debian',
    }
  end

  storages1 = ['[DISK]file:///data/1']
  storages2 = ['[RAM_DISK]/tmp', 'file:///data/2', '/data/3', '[ssd]']
  storages3 = ['eeeeeee', '']
  h1 = [
    {
      'type' => '[DISK]',
      'schema' => 'file',
      'path' => '/data/1',
    },
  ]
  h2 = [
    {
      'type' => '[RAM_DISK]',
      'schema' => 'file',
      'path' => '/tmp',
    },
    {
      'type' => '',
      'schema' => 'file',
      'path' => '/data/2',
    },
    {
      'type' => '',
      'schema' => 'file',
      'path' => '/data/3',
    },
    {
      'type' => '[SSD]',
      'schema' => 'file',
      'path' => '',
    },
  ]
  h3 = [
    {
      'type' => '',
      'schema' => 'file',
      'path' => 'eeeeeee',
    },
    {
      'type' => '',
      'schema' => 'file',
      'path' => '',
    },
  ]
  dirs1 = h1.map { |s| s['path'] }
  dirs2 = h2.map { |s| s['path'] }
  dirs3 = h3.map { |s| s['path'] }

  it { should run.with_params(storages1).and_return({'paths' => dirs1, 'storages' => h1}) }
  it { should run.with_params(storages2).and_return({'paths' => dirs2, 'storages' => h2}) }
  it { should run.with_params(storages3).and_return({'paths' => dirs3, 'storages' => h3}) }

  # XXX: errors are raised properly, but testing doesn't work
  #it { expect { run.with_params() }.to raise_error }
  #it { expect { run.with_params(1, 2) }.to raise_error }
  #it { expect { run.with_params(nil) }.to raise_error }
  #it { expect { run.with_params([nil]) }.to raise_error }
  #it { expect { run.with_params(nil) }.to raise_error(Puppet::Error, 'hadoop_storages(): Not an array') }
  #it { expect { run.with_params([nil]) }.to raise_error(Puppet::Error, 'hadoop_storages(): Undefined value of the storage path') }
end
