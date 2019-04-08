#!/bin/bash

sudo docker build . -t taskhub --build-arg ENV_NAME=uat
