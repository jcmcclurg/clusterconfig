echo "Installing puppet"
sudo apt-get -y install puppet

echo "Installing cdh module"
sudo git clone git://github.com/wikimedia/puppet-cdh.git /etc/puppet/modules/cdh

#modules="puppetlabs-apt puppetlabs-stdlib puppetlabs-vcsrepo puppetlabs-mysql puppetlabs-postgresql stahnma-epel puppetlabs-java_ks darin-zypprepo herculesteam-augeasproviders_sysctl razorsedge-cloudera"

modules="puppetlabs-apt puppetlabs-stdlib puppetlabs-vcsrepo"

for m as $modules; do
	echo "Installing $m module"
	sudo puppet module install $m
done
