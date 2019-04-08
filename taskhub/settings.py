import os
from datetime import datetime

APP_ENV = os.environ.get('APP_ENV', 'uat')
SPARK_HOST = os.environ.get('SPARK_HOST', '10.68.100.69')
PRESTO_HOST = os.environ.get('PRESTO_HOST', '10.68.100.148')
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
STORAGE = "/nfs/bigdata/attachment/{ds}"

def get_storage():
    ds = datetime.now().strftime("%Y-%m-%d")
    path = STORAGE.format(ds=ds)

    if not os.path.exists(path):
        os.makedirs(path)

    return path
