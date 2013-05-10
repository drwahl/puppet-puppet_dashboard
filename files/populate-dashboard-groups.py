#!/usr/bin/env python

import subprocess

def runme(cmd):
    """ run commands in a subprocess and wait for the return code. """
    proc = subprocess.Popen(cmd, \
            shell=True, \
            stdin=subprocess.PIPE, \
            stdout=subprocess.PIPE, \
            stderr=subprocess.PIPE)
    output = proc.communicate()

    return proc.returncode, output

def getNodes():
    """ run rake task to get a list of nodes. """
    hosts = []
    getNodescmd = "rake -sf /usr/share/puppet-dashboard/Rakefile node:list"
    ret, tmphostlist = runme(getNodescmd)
    for host in tmphostlist[0].split():
        hosts.append(host)

    return hosts

def getHostGroups(hostname):
    """ return a list of groups this host would belong to """
    hostgroups = []

    qagroups = ['qa00', 'qa01', 'qa02', 'qa03', 'qa04', 'qa05', 'qa06', 'qa07', 'qa08', 'qa09', 'qa10', 'qa11', 'qs01', 'qs02', 'ci01', 'ci02', 'ci03', 'ci04', 'de01', 'de02']
    stagegroups = ['stg0', 'stg1', 'stg2']
    corpgroups = ['corp']
    prodgroups = ['prod']
    sea1groups = ['sea1']
    iad1groups = ['iad1']
    las1groups = ['las1']
    hyd1groups = ['hyd1']
    #qa env check
    for group in qagroups:
        if group in hostname:
            hostgroups.append('qa')
 
    #stg env check
    for group in stagegroups:
        if group in hostname:
            hostgroups.append('stg2')

    #corp env check
    for group in corpgroups:
        if group in hostname:
            hostgroups.append('corp')
    
    #prod env check
    for group in prodgroups:
        if group in hostname:
            hostgroups.append('prod')

    #sea1 env check
    for group in sea1groups:
        if group in hostname:
            hostgroups.append('sea1')

    #iad1 env check
    for group in iad1groups:
        if group in hostname:
            hostgroups.append('iad1')

    #las1 env check
    for group in las1groups:
        if group in hostname:
            hostgroups.append('las1')

    #hyd1 env check
    for group in hyd1groups:
        if group in hostname:
            hostgroups.append('hyd1')

    #make a string of the groups so we can pass it cleanly to the rake task
    hostgroupsstr = ','.join(hostgroups)

    return hostgroupsstr
    
if __name__ == "__main__":
    hostlist = getNodes()
    allgroups = ['qa', 'stg2', 'corp', 'prod', 'sea1', 'iad1', 'las1', 'hyd1']
    for group in allgroups:
        groupaddcmd = "rake -sf /usr/share/puppet-dashboard/Rakefile nodegroup:add name=%s" % group
        runme(groupaddcmd)
    for host in hostlist:
        applygroups = getHostGroups(host)
        groupaddcmd = "rake -sf /usr/share/puppet-dashboard/Rakefile node:groups name=%s groups=%s" % (host, applygroups)
        runme(groupaddcmd)
