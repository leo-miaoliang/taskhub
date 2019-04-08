import sys
import logging

from flask import Flask, request, jsonify

from taskhub.settings import APP_ENV
from taskhub.connectors import spark_cli
from taskhub.excel import export
from taskhub.task.executor import run_task

app = Flask(__name__)

@app.route('/healthcheck')
def healthcheck():
    result = { 'status': 'success',
        'data' : {
            'env': APP_ENV
        }
    }

    return jsonify(result), 200

@app.route('/excel', methods=['POST'])
def export_excel():
    items = request.get_json()
    files = []

    for item in items:
        header = item.get('header', None)
        sql = item['sql']
        filename = item['filename']

        data = spark_cli.fetch(sql)
        file_path = export(header, data, filename)
        files.append(file_path)

    result = { 'status': 'success',
        'data': {
            'files': files
        }
    }
    return jsonify(result), 200

@app.route('/task', methods=['POST'])
def task():
    task = request.get_json()

    task_name = task.get('name', None)
    if not task_name:
        return jsonify({
            'status': 'failed',
            'message': 'missing task name' }
        ), 400

    logging.info(f'task {task_name} received')
    task_params = task.get('params', None)
    files = run_task(task_name, task_params)

    result = { 'status': 'success',
        'data': {
            'files': files
        }
    }
    return jsonify(result), 200


if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    app.run(debug=True)

if __name__ != '__main__':
    #logging.basicConfig(filename="taskhub.log", level=logging.INFO)
    logging.basicConfig(level=logging.INFO)