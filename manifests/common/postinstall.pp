# == Class hadoop::common::postinstall
#
# Preparation steps after installation. It switches hadoop-conf alternative, if enabled.
#
class hadoop::common::postinstall {
  ::hadoop_lib::postinstall{ 'hadoop':
    alternatives => $::hadoop::alternatives,
  }
}
