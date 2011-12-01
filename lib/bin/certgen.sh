#!/bin/sh

dir=$3
serial=$2
cert_dir="$dir/certs"
ca_key_file="$dir/ca.key"
ca_crt_file="$dir/ca.crt"
cert_key_file="$cert_dir/$1.key"
cert_csr_file="$cert_dir/$1.csr"
cert_crt_file="$cert_dir/$1.crt"

if [ ! -e $ca_key_file ]; then
  mkdir -p $dotfile_dir
  openssl genrsa -out $ca_key_file 1024
  openssl req -new -x509 -days 36500 -key $ca_key_file -out $ca_crt_file -subj "/C=US/ST=CA/L=SF/O=MiddleFiddle/OU=STFU/CN=middlefiddle.info CA"
fi

# Setup the server key
if [ ! -e $cert_key_file ]; then
  mkdir -p $cert_dir
  openssl genrsa -out $cert_key_file 1024
  openssl req -new -key $cert_key_file -out $cert_csr_file -subj "/C=US/ST=CA/L=SF/O=MiddleFiddle/OU=STFU/CN=$1"
  # Sign with the CA
  openssl x509 -req -days 365 -in $cert_csr_file -CA $ca_crt_file -CAkey $ca_key_file -set_serial $serial -out $cert_crt_file
fi

