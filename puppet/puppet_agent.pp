$master = "master.openstacklocal"
$master_ip = "10.1.0.171"
$interval = "600"
host { 'master.openstacklocal' :
	name => $master,
	ensure => present,
	host_aliases => "master",
	ip => $master_ip
}
augeas { "puppet_default" :
	context => "/files/etc/default/puppet",
	changes => ["set START yes"],
	notify => Service['puppet'],
}
augeas { "puppet.conf" :
	context => "/files/etc/puppet/puppet.conf",
	changes => [
		"set agent/server $master",
		"set agent/runinterval $interval",
	],
	notify => Service['puppet'],
}
service { "puppet" :
	ensure => running,
	hasrestart => true,
	hasstatus => true,
	require => Augeas['puppet.conf','puppet_default'],
}
