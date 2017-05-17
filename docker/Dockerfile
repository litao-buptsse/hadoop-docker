# FROM docker.registry.clouddev.sogou:5000/library/sogou-rhel-base:6.6
FROM docker.registry.clouddev.sogou:5000/library/sogou-centos7-base:7

#RUN rm -f /etc/yum.repos.d/sogou-ws-gym-puppet3.repo \
#    && curl http://yumrepo.clouddev.sogou/yum/sogou-ws-gym.repo -o /etc/yum.repos.d/sogou-ws-gym.repo \
#    && curl http://yumrepo.clouddev.sogou/yum/sogou-ws-cdh5.repo -o /etc/yum.repos.d/sogou-ws-cdh5.repo \
#    && curl http://yumrepo.clouddev.sogou/yum/sogou-ws-cdh5.3.2.repo -o /etc/yum.repos.d/sogou-ws-cdh5.3.2.repo \
#    && curl http://yumrepo.clouddev.sogou/yum/sogou-ws-cdh5_hbase98.repo -o /etc/yum.repos.d/sogou-ws-cdh5-whit-hbase.repo
# RUN yum clean all  && yum install which java-1.7.0-oracle-devel.x86_64 -y && yum clean all
RUN yum clean all  && yum install java-1.7.0-openjdk-devel.x86_64 -y && yum clean all

ENV APPROOT /search/hadoop
WORKDIR $APPROOT
ADD .zookeeper /search/zookeeper
ADD .hadoop $APPROOT
