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

export DEBIAN_FRONTEND=noninteractive;
export DEBCONF_NONINTERACTIVE_SEEN=true;
echo 'tzdata tzdata/Areas select America' > /tmp/preseed.cfg;
echo 'tzdata tzdata/Zones/America select Denver' >> /tmp/preseed.cfg;
debconf-set-selections /tmp/preseed.cfg
rm -f /etc/timezone /etc/localtime
apt-get update -qqy
apt-get install -qqy --no-install-recommends tzdata

if [ -z "$DEST" ]; then
    echo "Cannot find DEST:$DEST"
    sleep infinity
fi

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
    echo "ERROR: Pip 3.9 not found. So installing it."
    apt-get install wget -y
    GETPIP=$ROOT/get-pip.py
    wget https://bootstrap.pypa.io/get-pip.py -O $GETPIP
    if [[ -f $GETPIP ]]
    then
        echo "10.2 Fetching pip3 from bootstrap."
        $PY $GETPIP
        export PATH=$LOCAL_BIN:$PATH
        PIP3=$(which pip3.9)
        if [[ -f $PIP3 ]]
        then
            echo "11. Upgrading setuptools"
            setuptools="1"
            $PIP3 install --upgrade setuptools > /dev/null 2>&1
        fi
    fi
fi

PIP3=$(which pip3.9)

if [ ! -f "$PIP3" ]; then
    echo "ERROR: Pip 3.9 not found. Please install it."
    sleep infinity
fi

echo "PIP3:$PIP3"

VIRTUALENV=$(which virtualenv)

if [[ ! -f $virtualenv ]]
then
    echo "15.1 virtualenv is missing. pip3:$pip3"
    $PIP3 install virtualenv > /dev/null 2>&1
    $PIP3 install --upgrade virtualenv > /dev/null 2>&1
fi

VIRTUALENV=$(which virtualenv)

if [ ! -f "$VIRTUALENV" ]; then
    echo "ERROR: virtualenv not found. Please install it."
    sleep infinity
fi

echo "VIRTUALENV:$VIRTUALENV"

VENV=$ROOT/venv

$VIRTUALENV --python $PY -v $VENV

if [ ! -f "$VENV/bin/activate" ]; then
    echo "ERROR: virtualenv not found. Please install it."
    sleep infinity
fi

. $VENV/bin/activate

wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list
apt-get update -y
apt-get install -y mongodb-mongosh

DIRNAME=$(date +%m-%d-%y-%H-%M-%S)
DESTDIR=$DEST/$DIRNAME
mkdir -p $DESTDIR

if [ -z "$MONGO_INITDB_ROOT_USERNAME" ]; then
    echo "Cannot find MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_USERNAME."
    sleep infinity
fi

echo "MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_USERNAME"

if [ -z "$MONGO_INITDB_ROOT_PASSWORD" ]; then
    echo "Cannot find MONGO_INITDB_ROOT_PASSWORD:$MONGO_INITDB_ROOT_PASSWORD."
    sleep infinity
fi

echo "MONGO_INITDB_ROOT_PASSWORD:$MONGO_INITDB_ROOT_PASSWORD"

if [ -z "$MONGO_INITDB_ROOT_PASSWORD2" ]; then
    echo "Cannot find MONGO_INITDB_ROOT_PASSWORD2:$MONGO_INITDB_ROOT_PASSWORD2."
    sleep infinity
fi

echo "MONGO_INITDB_ROOT_PASSWORD2:$MONGO_INITDB_ROOT_PASSWORD2"

if [ -z "$MONGO_INITDB_DATABASE" ]; then
    echo "Cannot find MONGO_INITDB_DATABASE:$MONGO_INITDB_DATABASE."
    sleep infinity
fi

echo "MONGO_INITDB_DATABASE:$MONGO_INITDB_DATABASE"

pip install -r $ROOT/requirements.txt

PYFILE=$ROOT/mongo-list-databases.py

if [ ! -f "$PYFILE" ]; then
    echo "ERROR: $PYFILE not found."
    sleep infinity
fi

databases=$(python $PYFILE)

echo "databases:$databases"

#MONGOSH --uri "mongodb://mongodb1-10.web-service.org:27017,mongodb2-10.web-service.org:27017,mongodb3-10.web-service.org:27017/?replicaSet=rs0" \
#    --authenticationDatabase admin \
#    --username $USERNAME \
#    --password $PASSWORD1 \
#    --quiet --eval  "printjson(db.adminCommand('listDatabases'))"

#mongodump --uri "mongodb://mongodb1-10.web-service.org:27017,mongodb2-10.web-service.org:27017,mongodb3-10.web-service.org:27017/?replicaSet=rs0" \
#  --authenticationDatabase admin --username $USERNAME \
#  --db=<database> \
#  --password $PASSWORD1 --oplog --archive=/mongodumps/$DIRNAME/.gz