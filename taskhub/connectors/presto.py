import time
from pyhive import presto
from taskhub.settings import PRESTO_HOST

class PrestoClient(object):

    def __init__(self):
        self.cursor = presto.connect(PRESTO_HOST, catalog='memory').cursor()

    def execute(self, sql):
        self.cursor.execute(sql)
        result = self.cursor.poll()
        # print(result["stats"]["state"])
        while result["stats"]["state"] != 'FINISHED':
                time.sleep(2)   # wait 2 seconds
                result = self.cursor.poll()
                # print(result["stats"]["state"])

    def fetch(self, sql):
        self.cursor.execute(sql)
        results = self.cursor.fetchall()
        return results


