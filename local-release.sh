#!/bin/bash

### requirements ###
HAS_SUPERVISORD=`type supervisorctl`
if [ -z "$HAS_SUPERVISORD" ]; then
   echo "ERROR : Please install supervisord."
   exit
fi
### requirements ###


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
LINKS_DIR=${PROJECTS_DIR}/links
FILES_DIR=${PROJECTS_DIR}/files
CONFIG_DIR=${CWD}/config

COMPILE_FILE=${CONFIG_DIR}/${PROJECT}/compile.sh
CONF_FILE=${CONFIG_DIR}/${PROJECT}/conf
### constants ###


### check required files ###
if [ ! -e ${LINKS_DIR}/${PROJECT} ]; then
    echo "ERROR : Please first init ${PROJECT}."
    exit
fi

if [ ! -e /opt/soft ]; then
    echo "ERROR : Please create dir /opt/soft"
    exit
fi

if [ ! -e ${COMPILE_FILE} -o ! -f ${COMPILE_FILE} ]; then
    echo "ERROR : Need ${COMPILE_FILE}."
    exit
fi

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

### check required files ###


### copy source code to projects/files/${PROJECT} ###
echo "===> Loading,  please wait patiently..."
rm -fr ${FILES_DIR}/${PROJECT}
mkdir -p ${FILES_DIR}/${PROJECT}

REQUIRED_PROJECTS=`cat ${CONF_FILE} | grep REQUIRED_PROJECTS | awk '{print $3}'`
if [ -n "$REQUIRED_PROJECTS" ]; then
    echo "===> Find required projects : $REQUIRED_PROJECTS"
    NUM_PROJECTS=$(echo $REQUIRED_PROJECTS | awk -F ',' '{print NF}')
    for i in `seq $NUM_PROJECTS`
    do
	RP=$(echo $REQUIRED_PROJECTS | awk -v field=$i -F ',' '{print $field}')
	if [ "true" = "$IS_FULL" ]; then
	    echo "===> Starting sync project ${RP}..."
	    cd ${LINKS_DIR}/${PROJECT}
	    cp -r $RP ${FILES_DIR}/${PROJECT}
	else
	    if [ $i -eq $NUM_PROJECTS ]; then
		echo "===> Starting sync project ${RP}..."
		cd ${LINKS_DIR}/${PROJECT}
		cp -r $RP ${FILES_DIR}/${PROJECT}
	    else
		echo "===> Ignore project $RP"
	    fi
	fi
    done
else
    echo "===> Find no required projects, will sync all sub projects."
    cd ${LINKS_DIR}/${PROJECT}
    cp -r * ${FILES_DIR}/${PROJECT}
fi
cd $CWD
### copy source code to projects/files/${PROJECT} ###


### compile ###
if [ "true" = "$IS_FULL" ]; then
    sh ${COMPILE_FILE} $PROJECT "fully"
else
    sh ${COMPILE_FILE} $PROJECT
fi
### compile ###


### stop the service ###
if [ "mt" = "${SERVICE_TYPE}" ]; then
    echo "Stopping the service $PROJECT"
    supervisorctl stop $SERVICE_NAME
elif [ "fe" = "${SERVICE_TYPE}" ]; then
    echo "Stopping the service $PROJECT"
    /opt/soft/resin/bin/resin.sh -server ${SERVICE_NAME} kill
else
    echo "ERROR : Invalid service type : ${S_TYPE}"
    exit
fi
### stop the service ###


### copy compiled-file to /opt/soft ###
echo "Coping the service $PROJECT"
rm -fr /opt/soft/${PROJECT}
mkdir /opt/soft/${PROJECT}
cd ${RELEASE_DIR}
cp -r * /opt/soft/${PROJECT}
cd $CWD
### copy compiled-file to /opt/soft ###


### start the service ###
if [ "mt" = "${SERVICE_TYPE}" ]; then
    echo "Starting the service $PROJECT"
    supervisorctl start $SERVICE_NAME
elif [ "fe" = "${SERVICE_TYPE}" ]; then
    echo "Starting the service $PROJECT"
    /opt/soft/resin/bin/resin.sh -server ${SERVICE_NAME} start
else
    echo "ERROR : Invalid service type : ${S_TYPE}"
    exit
fi
### start the service ###


echo "===> Done!"
