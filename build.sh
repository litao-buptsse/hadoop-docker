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

version=`cat hadoop/pom.xml | grep version | grep cdh | awk -F">" '{print $2}' | awk -F"<" '{print $1}'`
registry="docker.registry.clouddev.sogou:5000"

# build docker
for module in hadoop-master hadoop-slave
do
  pushd $module
  rm -fr hadoop
  cp -r ../hadoop/hadoop-dist/target/hadoop-$version hadoop
  image="hadoop/$module"
  docker build -t $image:$version .
  docker tag $image:$version $registry/$image:$version
  docker push $registry/$image:$version
  rm -fr hadoop
  popd
done
