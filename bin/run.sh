#!/bin/bash

# docker run --name taskhub -it --rm --env-file .env.uat -p 30888:30888 -v /nfs:/nfs taskhub
docker run --name taskhub -it --rm -p 30888:30888 -v /nfs:/nfs:shared taskhub
