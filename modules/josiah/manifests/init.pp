class josiah_hadoop() {
	$params = get_hadoop_parameters_cloudera()

	# We need to make sure that the proper logging libraries are on the command line
	file { '/etc/environment':
		ensure => file,
		source => 'puppet:///modules/josiah/environment',
	}

	# We need Cloudera's repositories to be installed before we can use the cdh::hadoop module
	include apt
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
		namenode_hosts                       => ['jjpowerserver.jjcluster.net'],
		datanode_mounts                      => ['/var/lib/hadoop/data/mount1'],
		dfs_name_dir                         => '/var/lib/hadoop/name',
		#yarn_nodemanager_resource_cpu_vcores => $processorcount,
		yarn_nodemanager_resource_cpu_vcores => $params['yarn_nodemanager_resource_cpu_vcores'],
		yarn_nodemanager_resource_memory_mb  => $params['yarn_nodemanager_resource_memory'],
		yarn_scheduler_minimum_allocation_mb => $params['yarn_scheduler_minimum_allocation'],
		yarn_scheduler_maximum_allocation_mb => $params['yarn_scheduler_maximum_allocation'],
		mapreduce_map_memory_mb              => $params['mapreduce_map_memory_mb'],
		mapreduce_reduce_memory_mb           => $params['mapreduce_reduce_memory_mb'],
		mapreduce_map_java_opts              => $params['mapreduce_map_java_opts'],
		mapreduce_reduce_java_opts           => $params['mapreduce_reduce_java_opts'],
		webhdfs_enabled                      => true,
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
