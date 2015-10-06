# The following was generated from the rules layed out at http://tiny.cloudera.com/yarn-config
module Puppet::Parser::Functions
	newfunction(:get_hadoop_parameters_cloudera, :type => :rvalue) do |args|
		numNodes = args[0]
		ram = lookupvar('memorysize_mb').to_f
		cores = lookupvar('processorcount').to_f

		# TODO: Get the number of disks
		disks = 1.0
		
		coresForOS = 2
		coresForNodeManager = 1
		coresForDataNode = 1
		containers = cores - (coresForOS + coresForNodeManager + coresForDataNode)
		ramPerContainer = ram/(containers.to_f)

		memoryForOS = 0.1*ram
		memoryForNodeManager = 1024
		memoryForDataNode = 1024
		memoryForTaskOverhead = 1024

		params = Hash.new
		params["yarn_nodemanager_resource_cpu_vcores"] = [2*disks, containers].min
		params["yarn_nodemanager_resource_memory"] = ram - (memoryForOS + memoryForNodeManager + memoryForDataNode + memoryForTaskOverhead)

		params["yarn_scheduler_minimum_allocation"] = ramPerContainer.to_i
		params["yarn_scheduler_maximum_allocation"] = (containers*ramPerContainer).to_i
		params["mapreduce_map_memory_mb"] = ramPerContainer.to_i
		params["mapreduce_reduce_memory_mb"] = (2*ramPerContainer).to_i
		params["mapreduce_map_java_opts"] = sprintf("-Xmx%dm", 0.8*params["mapreduce_map_memory_mb"])
		params["mapreduce_map_java_opts"] = sprintf("-Xmx%dm", 0.8*params["mapreduce_reduce_memory_mb"])
		# Didn't include yarn.app.mapreduce.am options

		return params
	end
end
