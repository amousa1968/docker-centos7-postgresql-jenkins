#### Introduction
#### This is docker image that builds jenkin imag on ubuntu/centos7 with "jdk8", Postgresql and maven 3.3.9
#### Build
#### docker build -t am255098/jenkins:latest .
#### for jenkins latest means latest version and you don't have to specify a version # 
#### Run   

#### RUN echo 'we are running some # of cool things'

docker run --name am255098CI \
    -p 8080:8080
    -p 5000:5000
    am255098/jenkins:latest

FROM centos7:stable

LABEL description="Jenkins with jdk8 and Maven 3"

MAINTAINER ayman.mousa <ayman.mousa@teradata.com>

# ARG Git
ARG MAVEN_VERSION=3.3.9 
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG POSTGRESQL_VERSION=9.6

RUN apt-get update

RUN apt-get install -y wget

#Install Maven
COPY installers/apache-maven-$MAVEN_VERSION-bin.tar.gz /tmp/
RUN tar -xvf /tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz -C /opt/
RUN ln -s /opt/apache-maven-$MAVEN_VERSION /opt/maven
RUN ln -s /opt/maven/bin/mvn /usr/local/bin
RUN rm -f /tmp/apache-maven-$MAVEN_VERSION.tar.gz
ENV MAVEN_HOME /opt/maven

# install git
RUN apt-get install -y git

# install nano
RUN apt-get install -y nano

# remove download archive files
RUN apt-get clean

# Install Java 8
COPY installers/jdk-8u101-linux-x64.tar.gz /tmp/jdk-8u101-linux-x64.tar.gz
RUN mkdir /opt/java-oracle
RUN tar -xvf /tmp/jdk-8u101-linux-x64.tar.gz -C /opt/java-oracle/
ENV JAVA_HOME /opt/java-oracle/jdk1.8.0_101
ENV PATH $JAVA_HOME/bin:$PATH

RUN rm /tmp/jdk-8u101-linux-x64.tar.gz

RUN update-alternatives --install /usr/bin/java java $JAVA_HOME/bin/java 20000 && update-alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 20000

ENV JENKINS_HOME /jenkins_home
RUN groupadd -g ${gid} ${group} \
    && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

#Install Jenkins
COPY installers/jenkins.war /opt/jenkins.war
RUN chown ${user}:${gid} /opt/jenkins.war
RUN chmod 644 /opt/jenkins.war

# expose for main web interface:
EXPOSE 8080
# expose for attaching slave agents:
EXPOSE 50000

#USER ${user}

RUN echo "America/Los_Angeles" > /etc/timezone    
RUN dpkg-reconfigure -f noninteractive tzdata

ENTRYPOINT ["java", "-jar", "/opt/jenkins.war"]

# Postgresql version
ENV PG_VERSION 9.6
ENV PGVERSION 96

# Set the environment variables
ENV HOME /var/lib/pgsql
ENV PGDATA /var/lib/pgsql/9.6/data

# Install postgresql and run InitDB
RUN rpm -vih https://download.postgresql.org/pub/repos/yum/$PG_VERSION/redhat/rhel-7-x86_64/pgdg-centos$PGVERSION-$PG_VERSION-2.noarch.rpm && \
    yum update -y && \
    yum install -y sudo \
    pwgen \
    postgresql$PGVERSION \
    postgresql$PGVERSION-server \
    postgresql$PGVERSION-contrib && \
    yum clean all

# Copy
COPY data/postgresql-setup /usr/pgsql-$PG_VERSION/bin/postgresql$PGVERSION-setup

# Working directory
WORKDIR /var/lib/pgsql

# Run initdb
RUN /usr/pgsql-$PG_VERSION/bin/postgresql$PGVERSION-setup initdb

# Copy config file
COPY data/postgresql.conf /var/lib/pgsql/$PG_VERSION/data/postgresql.conf
COPY data/pg_hba.conf /var/lib/pgsql/$PG_VERSION/data/pg_hba.conf
COPY data/postgresql.sh /usr/local/bin/postgresql.sh

# Change own user
RUN chown -R postgres:postgres /var/lib/pgsql/$PG_VERSION/data/* && \
    usermod -G wheel postgres && \
    sed -i 's/.*requiretty$/#Defaults requiretty/' /etc/sudoers && \
    chmod +x /usr/local/bin/postgresql.sh

# Set volume
VOLUME ["/var/lib/pgsql"]

# Set username
USER postgres

# Run PostgreSQL Server
CMD ["/bin/bash", "/usr/local/bin/postgresql.sh"]

# Expose ports.
EXPOSE 5432


# To end Dockerfile executing build tasks use CMD
CMD [""]
