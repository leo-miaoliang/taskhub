import os
import logging

from taskhub.common.json2obj import file2obj
from taskhub.connectors import presto_cli
from taskhub.exceptions import TaskNotFound
from taskhub.excel import export

current_dir = os.path.dirname(os.path.abspath(__file__))

def _strip_sql(sql):
    return sql.strip().rstrip(';')

def _read_script(filename):
    with open(os.path.join(current_dir, filename) \
        , encoding='utf-8') as f:
        return f.read()

def _run_pre_exec(scripts):
    for script in scripts:
        logging.info(f'exec: {script}')
        statement = _read_script(script)
        sqls = [_strip_sql(item) for item in statement.split(';') if _strip_sql(item)]

        for sql in sqls:
            # print(sql)
            presto_cli.execute(sql)

def _run_exec(exec_items, params):
    files = []
    for item in exec_items:
        sql = '\n'.join(item.sql) if isinstance(item.sql, list) else item.sql
        header = ''.join(item.header) if isinstance(item.header, list) else item.header
        filename = item.filename.format(**params)

        data = presto_cli.fetch(sql)
        file_path = export(header, data, filename)
        files.append(file_path)
    return files

def run_task(task_name, params=None):
    task_conf_file = os.path.join(current_dir, "configs", f'{task_name}.json')
    if not os.path.exists(task_conf_file):
        raise TaskNotFound(f"task {task_name} not found")

    task_conf = file2obj(task_conf_file, 'Task')
    _run_pre_exec(task_conf.pre_exec)
    files = _run_exec(task_conf.exec, params)
    return files



