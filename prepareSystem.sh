echo "Installing puppet"
sudo apt-get -y install puppet

echo "Installing cdh module"
sudo git clone git://github.com/wikimedia/puppet-cdh.git /etc/puppet/modules/cdh

echo "Installing apt module"
sudo puppet module install puppetlabs-apt

echo "Installing stdlib module"
sudo puppet module install puppetlabs-stlib

echo "Installing vcsrepo module"
sudo puppet module install puppetlabs-vcsrepo
