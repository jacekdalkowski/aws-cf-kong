#!/bin/bash

usage()
{
    echo "usage: deploy-eks-min.sh [[[-bn bucket-name] [-bu bucket-url]] | [-h]]"
}

CF_BUCKET_NAME=
CF_BUCKET_URL=
SUBNET_ID=
VPC_ID=
CF_SCRIPT_NAME=kong-cf.yaml

while [ "$1" != "" ]; do
  case $1 in
    -bn | --bucket-name )   shift
                            CF_BUCKET_NAME=$1
                            ;;
    -bu | --bucket-url )    shift
                            CF_BUCKET_URL=$1
                            ;;
    -sn | --subnet )        shift
                            SUBNET_ID=$1
                            ;;
    -vpc )                  shift
                            VPC_ID=$1
                            ;;
    -h | --help )           usage
                            exit
                            ;;
    * )                     usage
                            exit 1
  esac
  shift
done

if aws s3 cp $CF_SCRIPT_NAME s3://$CF_BUCKET_NAME 1> /dev/null; then
  echo "Successfully uploaded kong-cf.yaml file to S3 bucket"
else
  echo "kong-cf.yaml upload to S3 failed!"
  exit
fi

if aws cloudformation create-stack --stack-name kong --template-url $CF_BUCKET_URL/$CF_SCRIPT_NAME --parameters ParameterKey=SubnetId,ParameterValue=$SUBNET_ID ParameterKey=VpcId,ParameterValue=$VPC_ID 1> /dev/null; then
  echo "Successfully initialized kong-cf stack creation"
else
  echo "kong-cf stack creation failed!"
  exit
fi

#aws cloudformation delete-stack --stack-name eks-min
while aws cloudformation describe-stacks --stack-name kong | grep StackStatus.*CREATE_IN_PROGRESS 1> /dev/null;
do
  sleep 1
  echo "Waiting for kong stack creation to complete..."
done

if aws cloudformation describe-stacks --stack-name kong | grep StackStatus.*CREATE_COMPLETE 1> /dev/null; then
  echo "kong stack successfully created"
else
  echo "kong stack failed to create, check AWS console for details!"
  exit
fi


