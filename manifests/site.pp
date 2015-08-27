class my::ubuntu {
	# We need to make sure that the proper logging libraries are on the command line
	file { '/etc/environment':
		ensure => file,
		source => 'puppet:///modules/josiah/environment',
	}

	# It's really annoying to have the server wait two minutes to start if the network isn't up #
	file { '/etc/init/failsafe.conf':
		ensure => file,
		source => 'puppet:///modules/josiah/failsafe.conf',
		mode => 644,
	}

	# There's no need to have window managers running. You can start these manually if you need them.
	service {'lxdm':
		ensure => stopped,
	}

	service {'lightdm':
		ensure => stopped,
	}

	#########################################################
	# The x2go server is needed for graphical remote login. #
	#########################################################

	# Uncomment this section to make sure the x2go ppa is added.
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
		ensure => file,
		source => 'puppet:///modules/josiah/x2gocleansessions',
		require => Package['x2goserver'],
	}

	package { 'x2goserver-xsession':
		ensure => present,
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

	# The following rules were obtained from http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.9.1/bk_installing_manually_book/content/rpm-chap1-11.html
	class { 'cdh::hadoop':
		# Logical Hadoop cluster name.
		cluster_name	   => 'josiah_cluster',
		# Must pass an array of hosts here, even if you are
		# not using HA and only have a single NameNode.
		namenode_hosts	 => ['jjpowerserver.jjcluster.net'],
		datanode_mounts		=> ['/var/lib/hadoop/data/mount1'],
		dfs_name_dir			=> '/var/lib/hadoop/name',
		yarn_nodemanager_resource_cpu_vcores => $processorcount,
		mapreduce_map_java_opts => '-Xmx2048m',
		webhdfs_enabled => true,
	}

	# We want to be able to use the web interface for the hdfs user (the javascript needed some modification)
	file {'/usr/lib/hadoop-hdfs/webapps/hdfs/explorer.js':
		ensure => file,
		mode => 644,
		source => "puppet:///modules/josiah/explorer.js",
		require => Class['cdh::hadoop'],
	}


	# We need mahout on all the nodes to run the HiBench demos
	package { 'mahout':
		ensure => present
	}
}

class my::hadoop::master inherits my::hadoop {
	#############################################
	# The hadoop master controls all the slaves #
	#############################################
	include cdh::hadoop::master

	# We don't want the master to also be a datanode
	file {'/etc/hadoop/conf/hosts.exclude':
		ensure => file,
		mode => 644,
		content => "jjpowerserver.jjcluster.net\n",
		require => Class['cdh::hadoop'],
	}

	service { 'hadoop-hdfs-datanode':
		ensure => stopped,
		require => Class['cdh::hadoop'],
	}

	############################################################################
	# HiBench-CDH5 is a benchmark needed for testing workloads on the cluster. #
	############################################################################
	vcsrepo { '/opt/HiBench-CDH5':
		ensure => present,
		provider => git,
		source => 'https://github.com/yanghaogn/HiBench-CDH5.git',
		revision => 'master',
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
		ensure => present,
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

	service { 'dnsmasq':
		ensure => running,
		require => File['/etc/dnsmasq.conf'],
	}

	file { '/etc/dnsmasq.conf':
		ensure => file,
		source => 'puppet:///modules/josiah/dnsmasq.conf',
		mode => 644,
	}

	file { '/etc/hosts':
		ensure => file,
		source => 'puppet:///modules/josiah/hosts',
		mode => 644,
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
		require => [Package['ant'], Class['cdh::hadoop'] ],
	}

	# We need to make sure the configuration script is set up right.
	file { '/opt/hipi/build.xml':
		ensure => file,
		source => 'puppet:///modules/josiah/build.xml',
		mode => 644,
		require => Vcsrepo['/opt/hipi'],
	}

	######################################
	# Vim syntax highlighting for puppet #
	######################################
	package { 'vim':
		ensure => present,
	}

	vcsrepo { '/opt/puppet-syntax-vim':
		ensure   => present,
		provider => git,
		source   => 'https://github.com/puppetlabs/puppet-syntax-vim.git',
		revision => 'master',
		require  => Package['vim'],
	}

	file { '/usr/share/vim/vim74/ftdetect/puppet.vim':
		ensure => file,
		source => '/opt/puppet-syntax-vim/ftdetect/puppet.vim',
		mode => 644,
		require  => Vcsrepo['/opt/puppet-syntax-vim'],
	}

	file { '/usr/share/vim/vim74/ftplugin/puppet.vim':
		ensure => file,
		source => '/opt/puppet-syntax-vim/ftplugin/puppet.vim',
		mode => 644,
		require  => Vcsrepo['/opt/puppet-syntax-vim'],
	}

	file { '/usr/share/vim/vim74/indent/puppet.vim':
		ensure => file,
		source => '/opt/puppet-syntax-vim/indent/puppet.vim',
		mode => 644,
		require  => Vcsrepo['/opt/puppet-syntax-vim'],
	}

	file { '/usr/share/vim/vim74/syntax/puppet.vim':
		ensure => file,
		source => '/opt/puppet-syntax-vim/syntax/puppet.vim',
		mode => 644,
		require  => Vcsrepo['/opt/puppet-syntax-vim'],
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
