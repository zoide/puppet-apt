define apt::preseed (
  $content  = '',
  $ensure   = 'installed',
  $seed     = 'files',
  $provider = 'aptitude') {
  $seeds_dir = '/var/cache/dpkg-seeds'
  $seedfile = "${seeds_dir}/${name}.seeds"
  $debconf = "/usr/bin/debconf-set-selections < ${seedfile}"
  $reconfigure = "/usr/sbin/dpkg-reconfigure -fnoninteractive -pcritical ${name}"

  Exec {
    path        => [
      '/usr/local/sbin',
      '/usr/local/bin',
      '/usr/sbin',
      '/usr/bin',
      '/sbin',
      '/bin'],
    refreshonly => true,
  }

  File {
    mode   => 0600,
    owner  => root,
    group  => root,
    notify => Exec[$debconf],
  }

  if !defined(File[$seeds_dir]) {
    file { $seeds_dir: ensure => 'directory', }
  }

  if $ensure == 'installed' or $ensure == 'present' {
    exec { $debconf:
      subscribe => File[$seedfile],
      require   => File[$seedfile],
      before    => Package[$name],
    }

    # reconfigure the package
    exec { $reconfigure:
      subscribe => [
        File[$seedfile],
        Package[$name],
        Exec[$debconf]]
    }

    Package {
      require => [File[$seedfile], Exec[$debconf]],
      before  => Exec[$reconfigure],
    }
  }

  package { $name:
    ensure   => $ensure,
    provider => $provider,
  }

  case $content {
    ''      : {
      file { $seedfile:
        source => $seed ? {
          'files' => "puppet:///debian/package/${name}.seeds",
          default => $seed,
          require => File[$seeds_dir],
        },
      }
    }
    default : {
      debug("${hostname} ==> ${seedfile} should be: \"${content}\"")

      file { $seedfile: content => $content, }
    }
  }
}
