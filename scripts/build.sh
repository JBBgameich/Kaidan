#!/bin/bash

export pkgname=kaidan
export project=Kaidan
export version=0.2.0-dev
export deb_pkg_user=kaidanim 
export deb_pkg_repo=packaging_deb
export deb_pkg_host=github.com
export pbuilder_basetgz=kaidan-debian-sid.tgz
export pbuilder_basetgz_url=https://archive.org/download/debian-sid-build-env

echo "Starting build in `pwd`";
mkdir ../cache;
rm -rf .git .travis.yml;

echo " ";
echo "Compressing to tar.gz"
echo " ";

tar -cvzf ../package.tar.gz *;

echo " ";
echo "Renaming to $pkgname`echo _`$version+git`date +%Y%m%d`.orig.tar.gz";
echo " ";

mv ../package.tar.gz ../$pkgname`echo _`$version+git`date +%Y%m%d`.orig.tar.gz;

echo " ";
echo "Fetching debian packaging files from $deb_pkg_host/$deb_pkg_user/$deb_pkg_repo";
echo " ";

git clone http://$deb_pkg_host/$deb_pkg_user/$deb_pkg_repo ../cache/$deb_pkg_repo;
rm ../cache/$dev_pkf_repo/.git/ -rf;
mv ../cache/$deb_pkg_repo/* ../$project;

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

cd ..;

echo "Building in path `pwd`";

echo "updating the pbuilder env, then starting the actual build"

sudo pbuilder update --basetgz cache/$pbuilder_basetgz;

sudo pbuilder build --basetgz cache/$pbuilder_basetgz $pkgname`echo _`$version+git`date +%Y%m%d`-1.dsc

echo " ";
echo "Now running lintian tests on the package";
echo " ";

cd $pkgname
lintian;

rm cache -rf;
