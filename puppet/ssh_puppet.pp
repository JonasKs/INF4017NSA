ssh_authorized_key { 'public_key_til_root':
	key => "<key>",
	user => root,
	ensure => present,
	type => ssh-rsa,
}
