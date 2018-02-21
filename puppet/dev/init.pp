#Filepath: /etc/puppet/environments/production/modules/dev/manifests/init.pp
class dev {
        #install emacs
        package { 'emacs':
        ensure => installed,
        }

	#install jed
        package { 'jed':
        ensure => installed,
        }

	#install git
        package { 'git':
        ensure => installed,
        }

	#install subversion
        package { 'subversion':
        ensure => installed,
        }
}
