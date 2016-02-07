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
RUN apt-get install -y openssh-server

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
ENV PATH $PATH:$JAVA_HOME/bin
RUN rm /usr/bin/java && ln -s $JAVA_HOME/bin/java /usr/bin/java

# build hadoop and native libs
RUN cd /usr/local/hadoop-2.7.2-src && mvn package -Pdist,native -DskipTests -Dtar && mv hadoop-dist/target/hadoop-2.7.2/ /usr/local/hadoop

# passwordless ssh
RUN rm /etc/ssh/ssh_host_dsa_key*
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN rm /etc/ssh/ssh_host_rsa_key*
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys


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

RUN $HADOOP_PREFIX/bin/hdfs namenode -format

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

# # installing supervisord
# RUN yum install -y python-setuptools
# RUN easy_install pip
# RUN curl https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -o - | python
# RUN pip install supervisor
#
# ADD supervisord.conf /etc/supervisord.conf

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

ENV BOOTSTRAP /etc/bootstrap.sh

# workingaround docker.io build error
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
RUN echo "Port 2122" >> /etc/ssh/sshd_config

RUN service ssh start && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/root
RUN service ssh start && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -put $HADOOP_PREFIX/etc/hadoop/ input

CMD ["/etc/bootstrap.sh", "-d"]

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Mapred ports
EXPOSE 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122
