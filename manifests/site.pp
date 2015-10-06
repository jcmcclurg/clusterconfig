class josiah_common {

	# It's really annoying to have the server wait two minutes to start if the network isn't up #
	file { '/etc/init/failsafe.conf':
		ensure => file,
		source => 'puppet:///modules/josiah/failsafe.conf',
		mode => 644,
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

class josiah_no_hadoop {
	service {'hadoop-hdfs-datanode':
		ensure => stopped,
	}
	service {'hadoop-hdfs-namenode':
		ensure => stopped,
	}
	service {'hadoop-mapreduce-historyserver':
		ensure => stopped,
	}
	service {'hadoop-yarn-nodemanager':
		ensure => stopped,
	}
	service {'hadoop-yarn-resourcemanager':
		ensure => stopped,
	}
}
