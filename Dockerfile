FROM alpine:latest
LABEL author="HongWang" email="xunhong.wang@uuabc.com"
ARG ENV_NAME=uat

RUN apk add --no-cache bash g++ cyrus-sasl-dev cyrus-sasl-plain python3 python3-dev \
    && python3 -m ensurepip \
    && rm -r /usr/lib/python*/ensurepip \
    && pip3 install --upgrade pip setuptools \
    && pip3 install gunicorn gevent \
    && rm -rf /var/cache/apk/* \
    && rm -rf ~/.cache/pip

COPY requirements.txt gunicorn.conf.py launch.sh /
RUN pip3 install --no-cache-dir -r requirements.txt

# WORKDIR /taskhub
COPY ./taskhub /taskhub
COPY ./.env.${ENV_NAME} /.env

EXPOSE 30888

# CMD ["gunicorn", "taskhub.app:app", "-c", "./gunicorn.conf.py"]
ENTRYPOINT [ "./launch.sh" ]
