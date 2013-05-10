#!/usr/bin/env python

import _mysql
import sys
import operator

con = None

try:

    #initiate connection to mysqldb
    con = _mysql.connect('localhost', 'root', '', 'dashboard')
    #conduct our query
    con.query("SELECT * FROM resource_statuses WHERE time >= SYSDATE() - INTERVAL 1 DAY AND failed > 0")
    result = con.store_result()
    #store our results locally
    raw_result = result.fetch_row(maxrows=0)
    #prepare a list to store just the files/modules we want to tally
    result_list = []
    for i in raw_result:
        #populate our list
        result_list.append(i[5])

    #prepare a dict to store the count of each occurance of a file/module
    modules = {}
    for module in result_list:
        modules[module] = result_list.count(module)

    #sort our dict with the lowest hit count on top
    sorted_modules = sorted(modules.iteritems(), key=operator.itemgetter(1))

    #print our sorted results
    for i in sorted_modules:
        print i[1], i[0]

except _mysql.Error, e:

    print "Error %d: %s" % (e.args[0], e.args[1])
    sys.exit(1)

finally:
    if con:
        con.close()
