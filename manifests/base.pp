Exec {
	path => ["/usr/bin", "/bin", "/usr/sbin", "/sbin", "/usr/local/bin", "/usr/local/sbin"]
}


File { owner => vagrant, group => vagrant, mode => 0644 }

class generic { 
	group { 'puppet':
		ensure => 'present'
	}

	file { "/etc/puppet/modules":
		ensure => 'directory',
	}

	# Replace geo-specific URLs with generic ones.
	exec { 'fix-sources':
		command => "sed -i'' -e 's/us\\.archive/archive/g' /etc/apt/sources.list"
	}

	exec { 'apt-update':
		require => Exec['fix-sources'],
		command => '/usr/bin/apt-get update';
	}

	file_line { "vagrant-mount":
		ensure => present,
		line => "v-root	/vagrant	vboxsf	defaults	0	0",
		path => "/etc/fstab",
	}	
	
	file { "/etc/motd":
		content => "Welcome to the Gentoo Prefix Ubuntu 12.04 LTS development environment! To start, run\n\n    cd gentoo-prefix-libc && ./bootstrap-prefix.sh\n\n",
	}
}

class vim {
	package {"vim" :
		require => Exec["apt-update"],
		ensure => present;
	}
	
	file { "/home/vagrant/.vimrc":
		source => "/vagrant/manifests/vim/.vimrc",
		ensure => "present",
	}

	file { "/home/vagrant/.vim":
		source => "/vagrant/manifests/vim/.vim",
		ensure => "directory",
		recurse => "true",
	}

	file { "/home/vagrant/tmp":
		ensure => "directory",
	}

	file_line { ".bashrc-vim":
		ensure => present,
		line => "export EDITOR=vim",
		path => "/home/vagrant/.bashrc",
	}

}

class git {
	package {"git":
		require => Exec["apt-update"],
		ensure => present,
	}

	file { "/home/vagrant/gitsetup":
		content => "if [ `git config user.name | wc -l` -eq 0 ]\nthen\n    echo\n    echo Git has not been configured yet!\n    echo\n    git config --global user.name \"`read -p 'Full name (git): '; echo \$REPLY`\"\n    git config --global user.email \"`read -p 'Email address (git): '; echo \$REPLY`\"\nfi"
	}

}

class dependencies {
	package {"mc":
		require => Exec["apt-update"],
		ensure => present;
	}

	package {"screen":
		require => Exec["apt-update"],
		ensure => present;
	}

	include vim
	include git
}

class devenv {
	exec { "gitclone":
		creates => "/home/vagrant/gentoo-prefix-libc",
                cwd => "/home/vagrant",
		command => "git clone https://github.com/redlizard/gentoo-prefix-libc.git",
		user => "vagrant",
		require => [Package["git"]],
	}

	package {"g++":
		require => Exec["apt-update"],
		ensure => present;
	}
	
	file_line { "/.profile":
		require => Class["git"],
		ensure => present,
		line => "if [ -n \"\$PS1\" ]; then sudo puppet apply /vagrant/manifests/base.pp; bash /home/vagrant/gitsetup; fi",
		path => "/home/vagrant/.profile",
	}
}

include generic
include dependencies
include devenv

notify{"done":
	message => "\n\n=========================\n\nRunning! SSH to 192.168.33.11 with username/password vagrant\n\n========================\n\n",
}
