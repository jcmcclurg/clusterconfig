class josiah_hadoop::master inherits josiah_hadoop(){
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
