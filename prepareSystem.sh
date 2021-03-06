echo "Installing puppet"
sudo apt-get -y install puppet

echo "Installing cdh module"
sudo git clone https://github.com/wikimedia/puppet-cdh.git /etc/puppet/modules/cdh

echo "Installing l23network module"
sudo git clone https://github.com/xenolog/l23network.git /etc/puppet/modules/l23network

#modules="puppetlabs-apt puppetlabs-stdlib puppetlabs-vcsrepo puppetlabs-mysql puppetlabs-postgresql stahnma-epel puppetlabs-java_ks darin-zypprepo herculesteam-augeasproviders_sysctl razorsedge-cloudera"

modules="puppetlabs-apt puppetlabs-stdlib puppetlabs-vcsrepo camptocamp-nfs"

for m as $modules; do
	echo "Installing $m module"
	sudo puppet module install $m
done
