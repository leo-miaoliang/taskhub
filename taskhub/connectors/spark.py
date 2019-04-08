from pyhive import hive

from taskhub.settings import SPARK_HOST

class SparkClient(object):

    def __init__(self):
        self.cursor = hive.connect(SPARK_HOST).cursor()

    def fetch(self, sql):
        self.cursor.execute(sql)
        results = self.cursor.fetchall()
        return results
