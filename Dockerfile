# Creates 64bit hadoop native libs 2.7.2
# Builds it on Ubuntu 14, which means you need to run it on a GLIBC 2.14+
# So not CentOS 6 :(

# need 14.04 as that has v1.5 proto buf
FROM ubuntu:14.04
MAINTAINER kimptoc - chris@kimptoc.net

#USER root

RUN apt-get update && apt-get install -y wget

# hadoop
RUN wget -qO- http://www.eu.apache.org/dist/hadoop/common/hadoop-2.7.2/hadoop-2.7.2-src.tar.gz | tar -xz -C /usr/local/

# maven
RUN wget -qO- http://mirror.ox.ac.uk/sites/rsync.apache.org/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz | tar -xz -C /usr/local
RUN cd /usr/local && ln -s ./apache-maven-3.3.9 maven
ENV MAVEN_HOME /usr/local/maven
RUN ln -s $MAVEN_HOME/bin/mvn /usr/bin/mvn

# ant
RUN wget -qO- http://mirror.vorboss.net/apache//ant/binaries/apache-ant-1.9.6-bin.tar.gz | tar -xz -C /usr/local
RUN cd /usr/local && ln -s ./apache-ant-1.9.6 ant
ENV ANT_HOME /usr/local/ant
RUN ln -s $ANT_HOME/bin/ant /usr/bin/ant

# only java7 available on 14.04
RUN apt-get install -y openjdk-7-jdk build-essential autoconf automake libtool cmake zlib1g-dev pkg-config libssl-dev libprotobuf-dev protobuf-compiler

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin
RUN rm /usr/bin/java && ln -s $JAVA_HOME/bin/java /usr/bin/java

# build hadoop and native libs
RUN cd /usr/local/hadoop-2.7.2-src && mvn package -Pdist,native -DskipTests -Dtar && mv hadoop-dist/target/hadoop-2.7.2/ /usr/local/hadoop

ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
# RUN . $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_PREFIX/input
RUN cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

# pseudo distributed
ADD core-site.xml.template $HADOOP_PREFIX/etc/hadoop/core-site.xml.template
RUN sed s/HOSTNAME/localhost/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
ADD hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

ADD mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

# workingaround docker.io build error
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh
