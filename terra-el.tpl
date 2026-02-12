config_opts['root'] = 'terra-el{{ releasever }}-{{ target_arch }}'
config_opts['package_manager'] = 'dnf'
config_opts['extra_chroot_dirs'] = [ '/run/lock', ]
config_opts['plugin_conf']['root_cache_enable'] = True
config_opts['plugin_conf']['yum_cache_enable'] = True
config_opts['plugin_conf']['ccache_enable'] = True
config_opts['plugin_conf']['ccache_opts']['compress'] = 'on'
config_opts['plugin_conf']['ccache_opts']['max_cache_size'] = '10G'
#config_opts['chroot_setup_cmd'] = 'install @{% if mirrored %}buildsys-{% endif %}build'
config_opts['chroot_setup_cmd'] = 'install bash bzip2 coreutils cpio diffutils redhat-release findutils gawk glibc-minimal-langpack grep gzip info patch redhat-rpm-config rpm-build sed tar unzip util-linux which xz epel-rpm-macros epel-release'
config_opts['chroot_additional_packages'] = ['anda-srpm-macros', 'terra-appstream-helper']
config_opts['dist'] = 'el{{ releasever }}'  # only useful for --resultdir variable subst
config_opts['bootstrap_image'] = 'ghcr.io/terrapkg/builder:el{{ releasever }}'


config_opts['dnf.conf'] = """
[main]
keepcache=1
debuglevel=2
reposdir=/dev/null
logfile=/var/log/yum.log
retries=20
obsoletes=1
gpgcheck=0
assumeyes=1
syslog_ident=mock
syslog_device=
metadata_expire=0
best=1
install_weak_deps=0
protected_packages=
skip_if_unavailable=False
module_platform_id=platform:el10
user_agent={{ user_agent }}

[baseos]
name=AlmaLinux {{ releasever }} - BaseOS
mirrorlist=https://mirrors.almalinux.org/mirrorlist/{{ releasever }}/baseos
# baseurl=https://repo.almalinux.org/almalinux/{{ releasever }}/BaseOS/{{ target_arch }}/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///usr/share/distribution-gpg-keys/alma/RPM-GPG-KEY-AlmaLinux-10

[appstream]
name=AlmaLinux {{ releasever }} - AppStream
mirrorlist=https://mirrors.almalinux.org/mirrorlist/{{ releasever }}/appstream
# baseurl=https://repo.almalinux.org/almalinux/{{ releasever }}/AppStream/{{ target_arch }}/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///usr/share/distribution-gpg-keys/alma/RPM-GPG-KEY-AlmaLinux-10

[crb]
name=AlmaLinux {{ releasever }} - CRB
mirrorlist=https://mirrors.almalinux.org/mirrorlist/{{ releasever }}/crb
# baseurl=https://repo.almalinux.org/almalinux/{{ releasever }}/CRB/{{ target_arch }}/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///usr/share/distribution-gpg-keys/alma/RPM-GPG-KEY-AlmaLinux-10

[extras]
name=AlmaLinux {{ releasever }} - Extras
mirrorlist=https://mirrors.almalinux.org/mirrorlist/{{ releasever }}/extras
# baseurl=https://repo.almalinux.org/almalinux/{{ releasever }}/extras/{{ target_arch }}/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///usr/share/distribution-gpg-keys/alma/RPM-GPG-KEY-AlmaLinux-10

[terra]
name=Terra EL {{ releasever }}
metalink=https://tetsudou.fyralabs.com/metalink?repo=terrael{{ releasever }}&arch={{ target_arch }}
type=rpm
skip_if_unavailable=True
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://repos.fyralabs.com/terrael{{ releasever }}/key.asc
enabled=1
enabled_metadata=1
metadata_expire=4h

[terra-extras]
name=Terra EL {{ releasever }} (Extras)
metalink=https://tetsudou.fyralabs.com/metalink?repo=terrael{{ releasever }}-extras&arch={{ target_arch }}
metadata_expire=6h
type=rpm
gpgcheck=1
gpgkey=https://repos.fyralabs.com/terrael{{ releasever }}-extras/key.asc
repo_gpgcheck=1
enabled=0
enabled_metadata=1
priority=150

[epel]
name=Extra Packages for Enterprise Linux {{ releasever }} - {{ target_arch }}
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-{{ releasever }}&arch={{ target_arch }}
gpgkey=file:///usr/share/distribution-gpg-keys/epel/RPM-GPG-KEY-EPEL-{{ releasever }}
gpgcheck=1
countme=1
 
[adoptium-temurin-java-repository]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/centos/$releasever/$basearch
enabled=0
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
enabled_metadata=1

"""
