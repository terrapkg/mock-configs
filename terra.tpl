config_opts['root'] = 'terra-{{ releasever }}-{{ target_arch }}'
config_opts['dist'] = 'fc{{ releasever }}'  # only useful for --resultdir variable subst
config_opts['macros']['%dist'] = '.fc{{ releasever }}'
config_opts['package_manager'] = 'dnf{% if releasever != "rawhide" %}5{% endif %}'
config_opts['extra_chroot_dirs'] = [ '/run/lock', ]
#config_opts['bootstrap_image'] = 'registry.fedoraproject.org/fedora:{{ releasever }}'
#config_opts['bootstrap_image'] = 'docker.io/library/fedora:{{ releasever }}'
config_opts['bootstrap_image'] = 'terrapkg/builder:f{{ releasever }}'
config_opts['mirrored'] = config_opts['target_arch'] != 'i686'
config_opts['chroot_setup_cmd'] = 'install @{% if mirrored %}buildsys-{% endif %}build'
config_opts['plugin_conf']['root_cache_enable'] = True
config_opts['plugin_conf']['yum_cache_enable'] = True
config_opts['plugin_conf']['ccache_enable'] = True
config_opts['plugin_conf']['ccache_opts']['compress'] = 'on'
config_opts['plugin_conf']['ccache_opts']['max_cache_size'] = '10G'
# repos
dnf_conf = """

[main]
keepcache=1
debuglevel=2a
reposdir=/dev/null
logfile=/var/log/yum.log
retries=20
obsoletes=1
gpgcheck=0
assumeyes=1
syslog_ident=mock
syslog_device=
install_weak_deps=0
metadata_expire=0
best=1
module_platform_id=platform:fc{{ releasever }}
protected_packages=
max_parallel_downloads=20

[terra]
name=Terra $releasever
metalink=https://tetsudou.fyralabs.com/metalink?repo=terra$releasever&arch=$basearch
type=rpm
skip_if_unavailable=True
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://repos.fyralabs.com/terra$releasever/key.asc
enabled=1
enabled_metadata=1
metadata_expire=4h

# Only used for multilib builds, pulls straight from fedora koji
# Use /rawhide/latest instead of /f{{ releasever }}-build/latest for rawhide
[local-f{{ releasever }}-build]
name=local
baseurl=https://kojipkgs.fedoraproject.org/repos/f{{ releasever }}-build/latest/$basearch/
cost=2000
# enabled only if not mirrored, and not rawhide
enabled={% if not mirrored and releasever != 'rawhide' %}1{% else %}0{% endif %}
skip_if_unavailable=False

[local-rawhide-build]
name=local-rawhide
baseurl=https://kojipkgs.fedoraproject.org/repos/rawhide/latest/$basearch/
cost=2000
# enabled only if not mirrored, and rawhide
enabled={% if not mirrored and releasever == 'rawhide' %}1{% else %}0{% endif %}
skip_if_unavailable=False




{% if mirrored %}
[fedora]
name=fedora
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
gpgkey=file:///usr/share/distribution-gpg-keys/fedora/RPM-GPG-KEY-fedora-{{ releasever }}-primary
gpgcheck=1
skip_if_unavailable=False
exclude=fedora-release*

[updates]
name=updates
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
gpgkey=file:///usr/share/distribution-gpg-keys/fedora/RPM-GPG-KEY-fedora-{{ releasever }}-primary
gpgcheck=1
skip_if_unavailable=False
{% endif %}
"""


config_opts['dnf.conf'] = dnf_conf
config_opts['dnf5.conf'] = dnf_conf
