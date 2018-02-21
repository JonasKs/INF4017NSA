#Filepath: /etc/puppet/environments/production/modules/users/manifests/init.pp

class users {
group { "developers":
        ensure =>       'present',
	gid =>		'5000',
	}

user { "bob":
	ensure =>	'present',
	groups => 	[ "sudo" ],
	uid =>	 	'1001',
	home => 	'/home/bob',
	managehome => 	true,
	}

user { "janet":
	ensure => 	'present',
	uid =>	 	'1002',
	groups => 	[ "sudo", "developers" ],
        home =>         '/home/janet',
        managehome =>   true,
	}

user { "alice":
	ensure => 	'present',
	uid =>	 	'1003',
	groups => 	[ "sudo" ],
        home =>         '/home/alice',
        managehome =>   true,
	}

user { "tim":
	ensure => 	'present',
	uid => 		'1004',
	groups => 	[ "sudo" ],
        home =>         '/home/tim',
        managehome =>   true,
	}
}
