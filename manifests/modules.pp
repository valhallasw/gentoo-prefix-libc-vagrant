Exec {
	path => ["/usr/bin", "/bin", "/usr/sbin", "/sbin", "/usr/local/bin", "/usr/local/sbin", "/opt/vagrant_ruby/bin/"]
}

class modules {
	file { "/etc/puppet/modules":
		ensure => "directory",
	}

	exec { "puppetlabs-stdlib":
		command => "puppet module install puppetlabs-stdlib",
		require => File["/etc/puppet/modules"],
		creates => "/etc/puppet/modules/stdlib",
	}
}

include modules
