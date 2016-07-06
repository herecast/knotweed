#!/usr/bin/env bash

eval $(aws ecr get-login --region us-east-1)
docker push 465559955196.dkr.ecr.us-east-1.amazonaws.com/knotweed:$CIRCLE_SHA1
