dir=$(dirname $0)
pdir=/etc/puppet

echo "Installing custom site files to $pdir"
sudo mkdir -p $pdir/modules/josiah
sudo mkdir -p $pdir/manifests
sudo cp $dir/modules/josiah/* $pdir/modules/josiah
sudo cp $dir/manifests/* $pdir/manifests
