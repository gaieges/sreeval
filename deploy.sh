#!/bin/bash

aws cloudformation deploy \
    --stack-name 'tenfold-ec-sreeval2' \
    --template-file "$(dirname $0)/cfn/fargate-cluster.yml" \
    --capabilities CAPABILITY_IAM

aws cloudformation deploy \
    --stack-name 'tenfold-ec-sreeval-task2' \
    --template-file "$(dirname $0)/cfn/task.yml" \
    --capabilities CAPABILITY_IAM
