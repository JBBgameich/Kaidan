#!/bin/bash

sudo apt install ca-certificates git-core tar gzip devscripts lintian debhelper;

mkdir ../cache; cd ../cache;
wget http://ftp.de.debian.org/debian/pool/main/p/pbuilder/pbuilder_0.228.7_all.deb;
sudo dpkg -i pbuilder_0.228.7_all.deb;
sudo apt install -f -y;
cd ../; rm -r cache;

echo "Finished installing packages for the pbuilder build on trvis-ci host"
