#!/bin/bash

if [ $# -ne 1 ]; then
  echo "usage: $0 <branch>"
  exit 1
fi

branch=$1

# clone code
if [ ! -d hadoop ]; then
  git clone git@gitlab.dev.sogou-inc.com:xianmaoyuan/hadoop.git
  pushd hadoop; git checkout -b $branch origin/$branch; popd
fi

# pull latest, compile
pushd hadoop
git pull origin
# mvn package -DskipTests -Pdist -Dtar
popd

registry="docker.registry.clouddev.sogou:5000"
image="hadoop/minicluster"
version=`cat hadoop/pom.xml | grep version | grep cdh | awk -F">" '{print $2}' | awk -F"<" '{print $1}'`

# build docker
pushd docker
rm -fr .zookeeper .hadoop
cp -r ../zookeeper .zookeeper
cp -r ../hadoop/hadoop-dist/target/hadoop-$version .hadoop
docker build -t $image:$version .
docker tag $image:$version $registry/$image:$version
docker push $registry/$image:$version
rm -fr .zookeeper .hadoop
popd
