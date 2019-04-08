#!/bin/bash

set -a

source .env
gunicorn taskhub.app:app -c gunicorn.conf.py --access-logfile - --error-logfile -