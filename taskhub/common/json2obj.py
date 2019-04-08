import json
from collections import namedtuple

def json2obj(data, name=None):
    if not name:
        name = 'X'

    return json.loads(data, object_hook=lambda d: namedtuple(name, d.keys())(*d.values()))

def file2obj(file_path, name=None):
    if not name:
        name = 'X'

    with open(file_path) as f:
        return json.load(f, object_hook=lambda d: namedtuple(name, d.keys())(*d.values()))


