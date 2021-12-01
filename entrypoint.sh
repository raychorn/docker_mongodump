#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

ENVPATH=$ROOT/.env
echo "Environment file: $ENVPATH"

if [ -f "$ENVPATH" ]; then
    echo "Importing environment variables."
    export $(cat $ENVPATH | sed 's/#.*//g' | xargs)
    echo "Done importing environment variables."
else
    echo "ERROR: Environment variables not found. So using env from the docker-compose."
fi

timedatectl set-timezone America/Denver

dpkg-reconfigure --frontend noninteractive tzdata

if [ ! -d "$DEST" ]; then
    mkdir -p $DEST
fi

PY=$(which python3.9)

if [ ! -f "$PY" ]; then
    echo "Python 3.9 not found. Trying to install it."
    apt-get install software-properties-common -y
    echo -ne '\n' | add-apt-repository ppa:deadsnakes/ppa
    apt-get update -y
    apt-get install python3.9 python3.9-dev python3.9-venv python3.9-distutils -y
fi

PY=$(which python3.9)

if [ ! -f "$PY" ]; then
    echo "ERROR: Python 3.9 not found. Please install it."
    sleep infinity
fi

echo "PY:$PY"

PIP3=$(which pip3.9)

if [ ! -f "$PIP3" ]; then
    echo "ERROR: Pip 3.9 not found. Please install it."
    sleep infinity
fi

echo "PIP3:$PIP3"

VIRTUALENV=$(which virtualenv)

if [ ! -f "$VIRTUALENV" ]; then
    echo "ERROR: virtualenv not found. Please install it."
    sleep infinity
fi

echo "VIRTUALENV:$VIRTUALENV"

DIRNAME=$(date +%m-%d-%y-%H-%M-%S)
DESTDIR=$DEST/$DIRNAME
mkdir -p $DESTDIR
# mongodb://root:sisko%407660%24boo@mongodb1-10.web-service.org:27017,mongodb2-10.web-service.org:27017,mongodb3-10.web-service.org:27017/?replicaSet=rs0&authSource=admin
#mongodump -h <your_database_host> -d <your_database_name> -u $USERNAME -p $PASSWORD -o $DEST