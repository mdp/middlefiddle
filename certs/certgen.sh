#!/bin/sh

openssl genrsa -out ca.key 1024
openssl req -new -x509 -days 36500 -key ca.key -out ca.crt -subj "/C=US/ST=CA/L=SF/O=MiddleFiddle/OU=STFU/CN=middlefiddle.info CA"

# Setup the server key
openssl genrsa -out server.key 1024
openssl req -new -key server.key -out server.csr -subj "/C=US/ST=CA/L=SF/O=MiddleFiddle/OU=STFU/CN=*.middlefiddle.info CA"

# Sign with the CA
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt
