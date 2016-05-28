#!/bin/bash

### constants ###
DIR_NAME=`dirname $0`
CWD=`cd $DIR_NAME;pwd`
cd $CWD

if [ $# -lt 1 ]; then
    echo "ERROR : Require PROJECT."
    exit
fi

if [ $# -eq 1 ]; then
    PROJECT=$1
    IS_FULL="false"
elif [ $# -eq 2 ]; then
    PROJECT=$2
    if [ "-f" = "$1" ]; then
	IS_FULL="true"
    else
	IS_FULL="false"
    fi	    
fi

if [ "true" = "$IS_FULL" ]; then
    echo "===> Fully deploy project $PROJECT"
fi

PROJECTS_DIR=${CWD}/projects
CONFIG_DIR=${CWD}/config
CONF_FILE=${CONFIG_DIR}/${PROJECT}/conf
### constants ###


### check required files ###
if [ ! -e ${PROJECTS_DIR}/${PROJECT} ]; then
    echo "ERROR : Please first init ${PROJECT}."
    exit
fi
PROJECT_DIR=${PROJECTS_DIR}/${PROJECT}

if [ ! -e ${CONF_FILE} -o ! -f ${CONF_FILE} ]; then
    echo "ERROR : Require ${CONF_FILE}"
    exit
fi

SERVICE_NAME=`cat ${CONF_FILE} | grep SERVICE_NAME | awk '{print $3}'`
if [ -z "$SERVICE_NAME" ]; then
    echo "Must define SERVICE_NAME in ${CONF_FILE}"
    exit
fi

SERVICE_TYPE=`cat ${CONF_FILE} | grep SERVICE_TYPE | awk '{print $3}'`
if [ -z "$SERVICE_TYPE" ]; then
    echo "Must define SERVICE_TYPE in ${CONF_FILE}"
    exit
fi

RELEASE_DIR=`cat ${CONF_FILE} | grep RELEASE_DIR | awk '{print $3}'`
if [ -z "$RELEASE_DIR" ]; then
    echo "Must define RELEASE_DIR in ${CONF_FILE}"
    exit
fi

RELEASE_PROJECT=`cat ${CONF_FILE} | grep RELEASE_PROJECT | awk '{print $3}'`
if [ -z "$RELEASE_PROJECT" ]; then
    echo "Must define RELEASE_PROJECT in ${CONF_FILE}"
    exit
fi

COMPILE_ARG=`cat ${CONF_FILE} | grep COMPILE_ARG | awk '{print $3}'`
### check required files ###


### compile ###
echo "===> Starting compile,  please wait patiently..."
if [ "true" = "$IS_FULL" ]; then
    cd $PROJECT_DIR
    if [ -n "$COMPILE_ARG" ]; then
	echo "===> compile cmd : mvn -pl $RELEASE_PROJECT -am -D${COMPILE_ARG} clean install "
	mvn -pl $RELEASE_PROJECT -am -D${COMPILE_ARG} clean install 
    else
	echo "===> compile cmd : mvn -pl $RELEASE_PROJECT -am clean install "
	mvn -pl $RELEASE_PROJECT -am clean install
    fi
else
    cd $PROJECT_DIR/$RELEASE_PROJECT
    if [ -n "$COMPILE_ARG" ]; then
	echo "===> compile cmd : mvn clean install -D${COMPILE_ARG}"
	mvn  clean install -D${COMPILE_ARG}
    else
	echo "===> compile cmd : mvn clean install "
	mvn clean install
    fi
fi
cd $CWD

#rm -fr ${FILES_DIR}/${PROJECT}
#mkdir -p ${FILES_DIR}/${PROJECT}
#REQUIRED_PROJECTS=`cat ${CONF_FILE} | grep REQUIRED_PROJECTS | awk '{print $3}'`
#if [ -n "$REQUIRED_PROJECTS" ]; then
#    echo "===> Find required projects : $REQUIRED_PROJECTS"
 #   NUM_PROJECTS=$(echo $REQUIRED_PROJECTS | awk -F ',' '{print NF}')
  #  for i in `seq $NUM_PROJECTS`
   # do
#	RP=$(echo $REQUIRED_PROJECTS | awk -v field=$i -F ',' '{print $field}')
#	if [ "true" = "$IS_FULL" ]; then
#	    echo "===> Starting sync project ${RP}..."
#	    cd ${LINKS_DIR}/${PROJECT}
#	    cp -r $RP ${FILES_DIR}/${PROJECT}
#	else
#	    if [ $i -eq $NUM_PROJECTS ]; then
#		echo "===> Starting sync project ${RP}..."
#		cd ${LINKS_DIR}/${PROJECT}
#		cp -r $RP ${FILES_DIR}/${PROJECT}
#	    else
#		echo "===> Ignore project $RP"
#	    fi
#	fi
 #   done
#else
 #   echo "===> Find no required projects, will sync all sub projects."
  #  cd ${LINKS_DIR}/${PROJECT}
   # cp -r * ${FILES_DIR}/${PROJECT}
#fi
#cd $CWD
### compile ###

set -e
### stop the service ###
set +e
if [ "mt" = "${SERVICE_TYPE}" ]; then
    echo "===> Stopping the service $PROJECT on onebox."
    ssh root@oneboxhost "supervisorctl stop $SERVICE_NAME"
elif [ "fe" = "${SERVICE_TYPE}" ]; then
    echo "===> Stopping the service $PROJECT on onebox."
    ssh root@oneboxhost "source /etc/profile;/opt/soft/resin/bin/resin.sh -server ${SERVICE_NAME} kill"
else
    echo "ERROR : Invalid service type : ${S_TYPE}"
    exit
fi
### stop the service ###
set +e

### copy compiled-file to /opt/soft ###
echo "===> Coping the binary files of $PROJECT to onebox."
ssh root@oneboxhost "rm -fr /opt/soft/${PROJECT}"
ssh root@oneboxhost "mkdir /opt/soft/${PROJECT}"
cd ${PROJECT_DIR}/${RELEASE_PROJECT}/${RELEASE_DIR}
echo "==> Compressing the files."
tar -zcf target.tar.gz *
echo "==> Begin to copy."
scp target.tar.gz root@oneboxhost:/opt/soft/${PROJECT}
echo "==> Decompressing."
ssh root@oneboxhost "cd /opt/soft/${PROJECT};tar -zxf target.tar.gz"
cd $CWD
### copy compiled-file to /opt/soft ###


### start the service ###
if [ "mt" = "${SERVICE_TYPE}" ]; then
    echo "===> Starting the service $PROJECT on onebox."
    ssh root@oneboxhost "supervisorctl start $SERVICE_NAME"
elif [ "fe" = "${SERVICE_TYPE}" ]; then
    echo "===> Starting the service $PROJECT on onebox."
    ssh root@oneboxhost "source /etc/profile;/opt/soft/resin/bin/resin.sh -server ${SERVICE_NAME} start"
else
    echo "ERROR : Invalid service type : ${S_TYPE}"
    exit
fi
### start the service ###

echo "===> Done!"
