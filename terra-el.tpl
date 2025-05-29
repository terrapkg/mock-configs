config_opts['root'] = 'terra-el{{ releasever }}-{{ target_arch }}'
config_opts['package_manager'] = 'dnf'
config_opts['extra_chroot_dirs'] = [ '/run/lock', ]
config_opts['plugin_conf']['root_cache_enable'] = True
config_opts['plugin_conf']['yum_cache_enable'] = True
config_opts['plugin_conf']['ccache_enable'] = True
config_opts['plugin_conf']['ccache_opts']['compress'] = 'on'
config_opts['plugin_conf']['ccache_opts']['max_cache_size'] = '10G'
config_opts['dnf_install_command'] += ' subscription-manager'
config_opts['yum_install_command'] += ' subscription-manager'
#config_opts['chroot_setup_cmd'] = 'install @{% if mirrored %}buildsys-{% endif %}build'
config_opts['chroot_setup_cmd'] = 'install bash bzip2 coreutils cpio diffutils redhat-release findutils gawk glibc-minimal-langpack grep gzip info patch redhat-rpm-config rpm-build sed shadow-utils tar unzip util-linux which xz epel-rpm-macros epel-release'
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
name=Red Hat Enterprise Linux {{ releasever }} for {{ target_arch }} - BaseOS (RPMs)
baseurl=https://cdn-ubi.redhat.com/content/public/ubi/dist/ubi{{ releasever }}/{{ releasever }}/{{ target_arch }}/baseos/os
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
gpcheck=1

[appstream]
name=Red Hat Enterprise Linux {{ releasever }} for {{ target_arch }} - AppStream (RPMs)
baseurl=https://cdn-ubi.redhat.com/content/public/ubi/dist/ubi{{ releasever }}/{{ releasever }}/{{ target_arch }}/appstream/os
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
gpgcheck=1

[crb]
name=Red Hat CodeReady Linux Builder for RHEL {{ releasever }} {{ target_arch }} (RPMs)
baseurl=https://cdn-ubi.redhat.com/content/public/ubi/dist/ubi{{ releasever }}/{{ releasever }}/{{ target_arch }}/codeready-builder/os
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
gpgcheck=1

[terra]
name=Terra EL $releasever
metalink=https://tetsudou.fyralabs.com/metalink?repo=terrael$releasever&arch=$basearch
type=rpm
skip_if_unavailable=True
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://repos.fyralabs.com/terrael$releasever/key.asc
enabled=1
enabled_metadata=1
metadata_expire=4h

[terra-extras]
name=Terra EL $releasever (Extras)
metalink=https://tetsudou.fyralabs.com/metalink?repo=terrael$releasever-extras&arch=$basearch
metadata_expire=6h
type=rpm
gpgcheck=1
gpgkey=https://repos.fyralabs.com/terrael$releasever-extras/key.asc
repo_gpgcheck=1
enabled=0
enabled_metadata=1
priority=150

[epel]
name=Extra Packages for Enterprise Linux $releasever - $basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-$releasever&arch=$basearch
gpgkey=file:///usr/share/distribution-gpg-keys/epel/RPM-GPG-KEY-EPEL-$releasever
gpgcheck=1
countme=1

"""
