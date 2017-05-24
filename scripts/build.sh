#!/bin/bash

export pkgname=kaidan
export user=kaidanim
export version=0.2.0-dev
export project=kaidan
export deb_pkg_user=kaidanim 
export deb_pkg_repo=packaging_deb
export host=github.com
export deb_pkg_host=github.com
export pbuilder_basetgz=kaidan-debian-sid.tgz
export pbuilder_basetgz_url=https://archive.org/download/debian-sid-build-env


rm cache -rf; rm $pkgname -r;

mkdir -p cache; cd cache;

echo " ";
echo "Cloning sources from $host ...";
echo " ";

git clone https://$host/$user/$project.git $project; cd $project;
rm -rf .git; cd ..;

echo " ";
echo "Compressing to tar.gz"
echo " ";

cd $project;
tar -cvzf ../../package.tar.gz *;
cd ../../;

echo " ";
echo "Renaming to $pkgname`echo _`$version+git`date +%Y%m%d`.orig.tar.gz";
echo " ";

mv package.tar.gz $pkgname`echo _`$version+git`date +%Y%m%d`.orig.tar.gz;

echo " ";
echo "Finished";

echo " ";
echo "cleaning up ...";

rm -rf cache;

mkdir $pkgname; cd $pkgname;

echo " ";
echo "Unpacking orig.tar.gz"
echo " ";

tar -xf ../$pkgname`echo _`$version+git`date +%Y%m%d`.orig.tar.gz;
cd ..
mkdir -p cache; cd cache;

echo " ";
echo "Fetching debian packaging files from $deb_pkg_host/$deb_pkg_user/$deb_pkg_repo";
echo " ";

git clone http://$deb_pkg_host/$deb_pkg_user/$deb_pkg_repo;
rm $dev_pkf_repo/.git/ -rf;
mv $deb_pkg_repo/* ../$pkgname;

cd ../$pkgname/;

echo " ";
echo "Updating changelog to new version $version+git`date +%Y%m%d`-1";
echo " ";

dch -v $version+git`date +%Y%m%d`-1 'New git snapshot build';

echo " ";
echo "Creating debian source package";
echo " ";

dpkg-buildpackage -S;

echo " ";
echo "Building package with pbuilder";
echo " ";

cd ../cache;
wget $pbuilder_basetgz_url/$pbuilder_basetgz;

cd ../$pkgname;

cd ..;

echo "Building in path `pwd`";

echo "updating the pbuilder env, then starting the actual build"

sudo pbuilder update  --basetgz cache/$pbuilder_basetgz;

sudo pbuilder build $pkgname`echo _`$version+git`date +%Y%m%d`-1.dsc --basetgz cache/$pbuilder_basetgz;

echo " ";
echo "Now running lintian tests on the package";
echo " ";

cd $pkgname
lintian;

rm cache -rf; rm $pkgname -r;
