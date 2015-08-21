class my::ubuntu {
	package { 'isc-dhcp-client':
		ensure => present,
	}

	file { '/etc/dhcp/dhclient.conf':
		ensure => file,
		source => 'puppet:///modules/josiah/dhclient.conf',
		require => Package['isc-dhcp-client'],
	}

	file { '/etc/environment':
		ensure => file,
		source => 'puppet:///modules/josiah/environment',
	}
}


class my::hadoop inherits my::ubuntu {
	include apt

	# We need Cloudera's repositories to be installed before we can use the cdh::hadoop module
	apt::source { 'cloudera-apt':
		comment => "Cloudera's distribution for Hadoop",
		architecture => 'amd64',
		key => {
			'id' => 'F36A89E33CC1BD0F71079007327574EE02A818DD',
			'source' => 'http://archive.cloudera.com/cdh5/ubuntu/trusty/amd64/cdh/archive.key',
		},
		include => {
			'deb' => true,
			'src' => true,
		},
		location => 'http://archive.cloudera.com/cdh5/ubuntu/trusty/amd64/cdh',
		release => 'trusty-cdh5',
		repos => 'contrib',
		before => [Class['cdh::hadoop'],Package['zookeeper']],
	}

	class { 'cdh::hadoop':
		# Logical Hadoop cluster name.
		cluster_name	   => 'josiah_cluster',
		# Must pass an array of hosts here, even if you are
		# not using HA and only have a single NameNode.
		namenode_hosts	 => ['jjpowerserver.jjcluster.net'],
		datanode_mounts		=> ['/var/lib/hadoop/data/mount1'],
		dfs_name_dir			=> '/var/lib/hadoop/name',
	}

	# We need mahout on all the nodes to run the HiBench demos
	package { 'mahout':
		ensure => present
	}
}

class my::hadoop::master inherits my::hadoop {
	include cdh::hadoop::master

	# We don't want the master to also be a datanode
	service { 'hadoop-hdfs-datanode':
		ensure => stopped,
	}

	#########################################################
	# The x2go server is needed for graphical remote login. #
	#########################################################
	/*
	include apt
	apt::ppa { 'ppa:x2go/stable':
		ensure => present,
		before => [Package['x2goserver'], Package['x2goserver-xsession']]
	}
	*/

	package { 'x2goserver':
		ensure => present,
	}

	# Makes sure the session cleaning only happens once every hour rather than once every two seconds. This reduces the resultant power spikes.
	file { '/usr/sbin/x2gocleansessions':
		source => 'puppet:///modules/josiah/x2gocleansessions',
		require => Package['x2goserver'],
	}

	package { 'x2goserver-xsession':
		ensure => present,
	}

	############################################################################
	# HiBench-CDH5 is a benchmark needed for testing workloads on the cluster. #
	############################################################################
	vcsrepo { '/opt/HiBench-CDH5':
		ensure => present,
		provider => git,
		source => 'https://github.com/yanghaogn/HiBench-CDH5.git',
		revision => 'master',
		#excludes => '/opt/HiBench-CDH5/bin/hibench-config.sh',
	}

	# We need to make sure the configuration script is set up right.
	file { '/opt/HiBench-CDH5/bin/hibench-config.sh':
		ensure => file,
		source => 'puppet:///modules/josiah/hibench-config.sh',
		mode => 755,
		require => Vcsrepo['/opt/HiBench-CDH5'],
	}

	# We need to make sure all the scripts are runnable.
	file { [	'/opt/HiBench-CDH5/TestDFSIO/bin/read.sh',
				'/opt/HiBench-CDH5/TestDFSIO/bin/run.sh',
				'/opt/HiBench-CDH5/TestDFSIO/bin/write.sh',
				'/opt/HiBench-CDH5/TestDFSIO/conf/configure.sh',
				'/opt/HiBench-CDH5/bin/run-all.sh',
				'/opt/HiBench-CDH5/conf/funcs.sh',
				'/opt/HiBench-CDH5/dfsioe/bin/prepare-read.sh',
				'/opt/HiBench-CDH5/dfsioe/bin/run-read.sh',
				'/opt/HiBench-CDH5/dfsioe/bin/run-write.sh',
				'/opt/HiBench-CDH5/dfsioe/conf/configure.sh',
				'/opt/HiBench-CDH5/kmeans/bin/prepare.sh',
				'/opt/HiBench-CDH5/kmeans/bin/run.sh',
				'/opt/HiBench-CDH5/kmeans/conf/configure.sh',
				'/opt/HiBench-CDH5/mrbench/bin/run.sh',
				'/opt/HiBench-CDH5/mrbench/conf/configure.sh',
				'/opt/HiBench-CDH5/sort/bin/prepare.sh',
				'/opt/HiBench-CDH5/sort/bin/run.sh',
				'/opt/HiBench-CDH5/sort/conf/configure.sh',
				'/opt/HiBench-CDH5/terasort/bin/prepare.sh',
				'/opt/HiBench-CDH5/terasort/bin/run.sh',
				'/opt/HiBench-CDH5/terasort/conf/configure.sh',
				'/opt/HiBench-CDH5/wordcount/bin/prepare.sh',
				'/opt/HiBench-CDH5/wordcount/bin/run.sh',
				'/opt/HiBench-CDH5/wordcount/conf/configure.sh']:
		mode => 755,
		require => Vcsrepo['/opt/HiBench-CDH5'],
	}

	##################################################################################
	# We need a DNS server to make sure that we can use fully qualified domain names #
	##################################################################################
	package { 'dnsmasq':
		ensure => present,
		before => File['/etc/dnsmasq.conf'],
	}

	file { '/etc/dnsmasq.conf':
		source => 'puppet:///modules/josiah/dnsmasq.conf',
		mode => 644
	}

	file { '/etc/hosts':
		source => 'puppet:///modules/josiah/hosts',
		mode => 644
	}

	###############################################
	# Hipi is a hadoop image processing framework #
	###############################################
	package { 'ant':
		ensure => present,
	}

	vcsrepo { '/opt/hipi':
		ensure => present,
		provider => git,
		source => 'https://github.com/uvagfx/hipi.git',
		revision => 'release',
		require => Package['ant'],
	}
}

class my::hadoop::worker inherits my::hadoop {
	include cdh::hadoop::worker
}

node 'jjpowerserver' {
	include my::hadoop::master
}

node 'jjpowerserver1.jjcluster.net', 'jjpowerserver2.jjcluster.net', 'jjpowerserver3.jjcluster.net', 'jjpowerserver4.jjcluster.net' {
	include my::hadoop::worker
}
