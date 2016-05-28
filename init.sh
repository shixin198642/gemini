#!/bin/bash
SELF=`dirname $0`
CWD=`cd $SELF;pwd`

PROJECTS_DIR=${CWD}/projects

if [ $# -lt 2 ]; then
    echo "$0 not running!"
    echo "Needs parameters: ProjectName and SourceDirectory!"
    exit
fi

PROJECT=$1 #project name
DIR=$2 #source code directory

if [ ! -e $DIR -o ! -d $DIR ]; then
    echo "Source code directory is not exists."
    exit
fi

if [ ! -e ${PROJECTS_DIR} ]; then
    mkdir -p $PROJECTS_DIR
fi

rm -fr ${PROJECTS_DIR}/${PROJECT}
ln -s ${DIR} ${PROJECTS_DIR}/${PROJECT}

echo "init ${PROJECT} successfuly!"
