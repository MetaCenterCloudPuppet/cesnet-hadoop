# == Class hadoop::historyserver::config
#
class hadoop::historyserver::config {
	contain hadoop::common::config
	contain hadoop::common::hdfs::config
	contain hadoop::common::mapred::config
	contain hadoop::common::yarn::config

	if $hadoop::daemon_historyserver and $hadoop::realm {
		$keytab = "/etc/security/keytab/jhs.service.keytab"

		file { $keytab:
			owner => "mapred",
			group => "mapred",
			mode => "0400",
			alias => "jhs.service.keytab",
			before => File["mapred-site.xml"],
		}

		if $hadoop::features["krbrefresh"] {
			$user = "mapred"
			$file = "/tmp/krb5cc_jhs"
			$principal = "jhs/${::fqdn}@${hadoop::realm}"

			file { "/etc/cron.d/hadoop-historyserver-krb5cc":
				owner => "root",
				group => "root",
				mode => "0644",
				alias => "jhs-cron",
				content => template("hadoop/cron.erb"),
			}

			exec { "jhs-kinit":
				command => "kinit -k -t ${keytab} ${principal}",
				user => $user,
				path => "/bin:/usr/bin",
				environment => [ "KRB5CCNAME=FILE:${file}" ],
				creates => $file,
			}

			File[$keytab] -> Exec["jhs-kinit"]

			file { "/etc/sysconfig/hadoop-historyserver":
				owner => "root",
				group => "root",
				alias => "jhs-env",
				source => "puppet:///modules/hadoop/hadoop-historyserver",
			}
		}
	}
}
