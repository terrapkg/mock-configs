config_opts['root'] = 'terra-{{ releasever }}-{{ target_arch }}'
config_opts['dist'] = 'fc{{ releasever }}'  # only useful for --resultdir variable subst
config_opts['macros']['%dist'] = '.fc{{ releasever }}'
config_opts['package_manager'] = 'dnf5'
config_opts['extra_chroot_dirs'] = [ '/run/lock', ]
config_opts['use_bootstrap'] = False
#config_opts['bootstrap_image'] = 'ghcr.io/terrapkg/builder:f{{ releasever }}'
#config_opts['bootstrap_image_ready'] = True
config_opts['mirrored'] = config_opts['target_arch'] != 'i686'
config_opts['chroot_setup_cmd'] = 'install @{% if mirrored %}buildsys-{% endif %}build'
config_opts['chroot_additional_packages'] = ['anda-srpm-macros', 'terra-appstream-helper', 'mold']
config_opts['plugin_conf']['root_cache_enable'] = True
config_opts['plugin_conf']['yum_cache_enable'] = True
config_opts['plugin_conf']['ccache_enable'] = int(config_opts['releasever']) < 44 or int(config_opts['releasever']) >= 44 and config_opts['target_arch'] != 'i686'
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

{% if releasever == "rawhide" or (releasever | int) >= 41 %}

[terra-extras]
name=Terra $releasever (Extras)
metalink=https://tetsudou.fyralabs.com/metalink?repo=terra$releasever-extras&arch=$basearch
metadata_expire=6h
type=rpm
gpgcheck=1
gpgkey=https://repos.fyralabs.com/terra$releasever-extras/key.asc
repo_gpgcheck=1
enabled=1
enabled_metadata=1
priority=150

[terra-nvidia]
name=Terra $releasever (NVIDIA)
metalink=https://tetsudou.fyralabs.com/metalink?repo=terra$releasever-nvidia&arch=$basearch
metadata_expire=6h
type=rpm
gpgcheck=1
gpgkey=https://repos.fyralabs.com/terra$releasever-nvidia/key.asc
repo_gpgcheck=1
enabled=0
enabled_metadata=1
excludepkgs=dkms-nvidia*

[terra-mesa]
name=Terra $releasever (Mesa)
metalink=https://tetsudou.fyralabs.com/metalink?repo=terra$releasever-mesa&arch=$basearch
metadata_expire=6h
type=rpm
gpgcheck=1
gpgkey=https://repos.fyralabs.com/terra$releasever-mesa/key.asc
repo_gpgcheck=1
enabled=0
enabled_metadata=1

[terra-multimedia]
name=Terra $releasever (Multimedia)
metalink=https://tetsudou.fyralabs.com/metalink?repo=terra$releasever-multimedia&arch=$basearch
metadata_expire=6h
type=rpm
gpgcheck=1
gpgkey=https://repos.fyralabs.com/terra$releasever-multimedia/key.asc
repo_gpgcheck=1
enabled=0
enabled_metadata=1

{% endif %}

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

[adoptium-temurin-java-repository]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/fedora/$releasever/$basearch
enabled=0
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
enabled_metadata=1

"""


config_opts['dnf.conf'] = dnf_conf
config_opts['dnf5.conf'] = dnf_conf
