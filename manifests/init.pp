# Setup and initialize puppet-dashboard
#
# Phusion Passenger settings (http://www.modrails.com/documentation/Users%20guide%20Apache.html#_configuring_phusion_passenger)
#
# [passengerhighperformance]
# Default: on
# Valid values are "on" or "off". If set to undef, this will default to "off".
#
# [passengermaxpoolsize]
# Default: undef
# The maximum number of application processes that may simultaneously exist. A
# larger number results in higher memory usage, but improves the ability to
# handle concurrent HTTP requests. If set to undef, will default to 6.
#
# [passengerpoolidletime]
# Default: undef
# The maximum number of seconds that an application process may be idle. That
# is, if an application process hasn’t received any traffic after the given
# number of seconds, then it will be shutdown in order to conserve memory. If
# set to undef, will default to 300.
#
# [passengermaxrequests]
# Default: undef
# The maximum number of requests an application process will process. After
# serving that many requests, the application process will be shut down and
# Phusion Passenger will restart it. A value of 0 means that there is no
# maximum: an application process will thus be shut down when its idle timeout
# has been reached. If set to undef, will default to 0 (no maximum).
#
# [passengerstatthrottlerate]
# Default: undef
# If set to undef, will default to 0.
#
class puppet_dashboard (
    $database_host                    = 'localhost',
    $database_username                = 'dashboard',
    $database_password                = 'my_password',
    $database_encoding                = 'utf8',
    $database_adapter                 = 'mysql',
    $ca_server                        = 'puppet',
    $cn_name                          = 'dashboard',
    $ca_crl_path                      = 'certs/dashboard.ca_crl.pem',
    $ca_certificate_path              = 'certs/dashboard.ca_cert.pem',
    $certificate_path                 = 'certs/dashboard.cert.pem',
    $private_key_path                 = 'certs/dashboard.private_key.pem',
    $public_key_path                  = 'certs/dashboard.public_key.pem',
    $ca_port                          = 8140,
    $ssl_key_length                   = 1024,
    $enable_inventory_service         = false,
    $inventory_server                 = 'puppet',
    $inventory_port                   = 8140,
    $use_file_bucket_diffs            = true,
    $file_bucket_server               = 'puppet',
    $file_bucket_port                 = 8140,
    $no_longer_reporting_cutoff       = 7200,
    $daily_run_history_length         = 7,
    $use_external_node_classification = true,
    $time_zone                        = 'Pacific Time (US & Canada)',
    $datetime_format                  = '%Y-%m-%d %H:%M %Z',
    $date_format                      = '%Y-%m-%d',
    $custom_logo_url                  = 'http://www.puppetlabs.com/images/puppet-short.png',
    $disable_legacy_report_upload_url = false,
    $enable_read_only_mode            = true,
    $passengerhighperformance         = 'on',
    $passengermaxpoolsize             = 20,
    $passengerpoolidletime            = 0,
    $passengermaxrequests             = undef,
    $passengerstatthrottlerate        = undef
){

    include apache::mod_passenger

    package { 'puppet-dashboard':
        ensure => present
    }

    service { 'puppet-dashboard':
        ensure     => true,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        subscribe  => [
            File['/etc/puppet-dashboard/settings.yml'],
            File['/etc/puppet-dashboard/database.yml']
        ],
        require    => Exec['rake_db']
    }

    service { 'puppet-dashboard-workers':
        ensure     => true,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        subscribe  => Service['puppet-dashboard']
    }

    file { '/etc/puppet-dashboard':
        ensure  => directory,
        mode    => '0755',
        owner   => 'puppet-dashboard',
        group   => 'puppet-dashboard',
        require => Package['puppet-dashboard']
    }

    file { '/var/log/puppet-dashboard':
        ensure  => directory,
        owner   => 'puppet-dashboard',
        group   => 'apache',
        mode    => '0775',
        require => Package['puppet-dashboard']
    }

    # your configs shouldn't be in /usr/share, you retarded Rails app.
    file { '/usr/share/puppet-dashboard/config/settings.yml':
        ensure  => link,
        target  => '/etc/puppet-dashboard/settings.yml',
        require => File['/etc/puppet-dashboard/settings.yml']
    }

    file { '/usr/share/puppet-dashboard/config/database.yml':
        ensure  => link,
        target  => '/etc/puppet-dashboard/database.yml',
        require => File['/etc/puppet-dashboard/database.yml']
    }

    file { '/etc/puppet-dashboard/settings.yml':
        ensure  => present,
        content => template('puppet_dashboard/settings.yml.erb'),
        mode    => '0644',
        owner   => 'puppet-dashboard',
        group   => 'puppet-dashboard',
        require => [
            File['/etc/puppet-dashboard'],
            Package['puppet-dashboard']
        ]
    }

    file { '/etc/puppet-dashboard/database.yml':
        ensure  => present,
        content => template('puppet_dashboard/database.yml.erb'),
        mode    => '0640',
        owner   => 'puppet-dashboard',
        group   => 'puppet-dashboard',
        require => [
            File['/etc/puppet-dashboard'],
            Package['puppet-dashboard']
        ]
    }

    # don't write logs into /usr/share, you retarded Rails app.
    file { '/usr/share/puppet-dashboard/log':
        ensure  => link,
        force   => true,
        target  => '/var/log/puppet-dashboard',
        require => File['/var/log/puppet-dashboard']
    }

    file { '/etc/httpd/conf.d/puppet-dashboard.conf':
        ensure  => present,
        content => template('puppet_dashboard/puppet-dashboard.conf.erb'),
        notify  => Service['httpd']
    }

    file { '/usr/local/bin/bad_module_count.py':
        ensure => present,
        source => "puppet://${::puppet_server}/modules/puppet_dashboard/bad_module_count.py",
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/usr/share/puppet-dashboard/bin/populate-dashboard-groups.py':
        ensure  => present,
        source  => "puppet://${::puppet_server}/modules/puppet_dashboard/populate-dashboard-groups.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['puppet-dashboard']
    }

    cron { 'populate-dashboard-groups':
        ensure  => present,
        user    => 'root',
        command => '/usr/share/puppet-dashboard/bin/populate-dashboard-groups.py',
        minute  => '0',
        hour    => '1',
    }

    file { '/usr/local/bin/puppetFailures.py':
        ensure  => present,
        content => template('puppet_dashboard/puppetFailures.py.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
        require => Package['zabbix-agent']
    }

    cron { 'puppetFailureCheck':
        ensure  => present,
        user    => 'root',
        command => '/usr/local/bin/puppetFailures.py > /dev/null',
        minute  => '7',
    }

    file { '/usr/local/bin/delete_old_dashboard_data.py':
        ensure  => present,
        source  => "puppet://${::puppet_server}/modules/puppet_dashboard/delete_old_dashboard_data.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    cron { 'deleteOldDashboardData':
        ensure  => present,
        user    => 'root',
        command => '/usr/local/bin/delete_old_dashboard_data.py',
        minute  => '0',
        hour    => '0',
        require => File['/usr/local/bin/delete_old_dashboard_data.py']
    }

    cron { 'optimizeDashboardDatabase':
        ensure   => present,
        user     => 'root',
        command  => 'rake RAILS_ENV=production -f /usr/share/puppet-dashboard/Rakefile db:raw:optimize',
        hour     => '0',
        minute   => '0',
        monthday => '1',
        require  => Package['puppet-dashboard']
    }

    exec { 'create_dashboard_user':
        command => "mysql -h ${database_host} -u root -e \"CREATE USER '${database_username}'@'%' IDENTIFIED BY '${database_password}'\"",
        unless  => "mysql -h ${database_host} -u ${database_username} -p'${database_password}' -e'exit'",
        path    => ['/bin', '/usr/bin'],
        before  => Exec['grant_dashboard_privs'],
        require => Package['puppet-dashboard']
    }

    exec { 'create_dashboard_database':
        command => "mysql -h ${database_host} -u root -e 'CREATE DATABASE IF NOT EXISTS dashboard'",
        unless  => "mysql -h ${database_host} -u root -e 'SHOW TABLES IN dashboard'",
        path    => ['/bin', '/usr/bin'],
        require => Package['puppet-dashboard']
    }

    # using "localhost" for mysql database atm, 'cause i'm running into grant
    # issues when $database_host is the same as $::fqdn

    exec { 'grant_dashboard_privs':
        command => "mysql -h ${database_host} -u root -e \"GRANT ALL PRIVILEGES ON dashboard.* TO '${database_username}'@'%' IDENTIFIED BY '${database_password}'\"",
        unless  => "mysql -h ${database_host} -u dashboard -p\'${database_password}\' -e \"SHOW GRANTS FOR '${database_username}'@'%'\" | grep -q 'ALL PRIVILEGES ON `dashboard`.*'",
        path    => ['/bin', '/usr/bin'],
        require => Package['puppet-dashboard']
    }

    exec { 'rake_db':
        command => 'rake RAILS_ENV=production -f /usr/share/puppet-dashboard/Rakefile db:migrate',
        path    => ['/bin', '/usr/bin'],
        cwd     => '/usr/share/puppet-dashboard/',
        require => Package['puppet-dashboard']
    }

}
