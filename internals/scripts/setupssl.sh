#!/bin/bash

# Defaults
SERVER_SSLPATH=server/certificates
CLIENT_SSLPATH=electron/certificates
BASE_PATH=$PWD

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -s|--serverpath)
    SERVER_SSLPATH="$2"
    shift
    ;;
    -c|--clientpath)
    CLIENT_SSLPATH="$2"
    shift
    ;;
    -b|--basepath)
    BASE_PATH="$2"
    shift
    ;;
    *)
    # unknown option
    ;;
esac
shift # past argument or value
done

mkdir -p "$SERVER_SSLPATH"
mkdir -p "$CLIENT_SSLPATH"

echo $BASE_PATH

# From https://github.com/thojansen/client-certificates/blob/master/ssl/setup.sh
# create rootCA certificate
cd "$SERVER_SSLPATH"
echo "cd ${SERVER_SSLPATH}"
pwd
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -days 1024 -out rootCA.crt -subj "/C=DE/ST=Germany/L=Konstanz/O=SAP SE/OU=Tools/CN=rootCA"

# create server key and certificate
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/C=DE/ST=Germany/L=Konstanz/O=SAP SE/OU=Tools/CN=localhost"
openssl x509 -req -in server.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out server.crt -days 500

# create client key and certificate
cd "$BASE_PATH"
cd "$CLIENT_SSLPATH"
pwd
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -subj "/C=DE/ST=Germany/L=Konstanz/O=SAP SE/OU=Tools/CN=client"
openssl x509 -req -in client.csr -CA "${BASE_PATH}/${SERVER_SSLPATH}/rootCA.crt" -CAkey "${BASE_PATH}/${SERVER_SSLPATH}/rootCA.key" -CAcreateserial -out client.crt -days 500

# generate client.p12 file which can be easily imported to OS.
openssl pkcs12 -export -inkey client.key -in client.crt -name client -out client.p12

# generate a non-encrypt pem file with key and crt files, from p12 files
# openssl pkcs12 -in client.p12 -out client.pem -nodes -clcerts
