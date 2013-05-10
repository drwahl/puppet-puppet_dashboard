#!/usr/bin/env python

import _mysql
import sys

con = None

def deleteme(table, column):
    con.query("DELETE FROM %s WHERE %s < SYSDATE() - INTERVAL 1 WEEK" % (table, column))
    result = con.store_result()

try:

    #initiate connection to mysqldb
    con = _mysql.connect('localhost', 'root', '', 'dashboard')
    #delete anything old from each of our tables
    tables_and_time_keys = [
        {'delayed_job_failures': 'updated_at'},
        {'delayed_jobs': 'updated_at'},
#        {'metrics': ''},
        {'node_class_memberships': 'updated_at'},
        {'node_classes': 'updated_at'},
        {'node_group_class_memberships': 'updated_at'},
        {'node_group_edges': 'updated_at'},
        {'node_group_memberships': 'updated_at'},
        {'node_groups': 'updated_at'},
        {'nodes': 'updated_at'},
        {'old_reports': 'updated_at'},
        {'parameters': 'updated_at'},
        {'report_logs': 'time'},
        {'reports': 'time'},
        {'resource_events': 'time'},
        {'resource_statuses': 'time'},
#        {'schema_migrations': ''},
        {'timeline_events': 'updated_at'},
    ]

    for cleanup_job in tables_and_time_keys:
        table = cleanup_job.keys()[0]
        key   = cleanup_job[table]
        deleteme(table, key)

except _mysql.Error, e:

    print "Error %d: %s" % (e.args[0], e.args[1])
    sys.exit(1)

finally:
    if con:
        con.close()
