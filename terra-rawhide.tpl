# {% set rawhide = 45 %}
config_opts['rawhide'] = '45'

config_opts['root'] = 'terra-{{ releasever }}-{{ target_arch }}'
config_opts['dist'] = 'fc{{ releasever }}'  # only useful for --resultdir variable subst
config_opts['macros']['%dist'] = '.fc{{ releasever }}'
config_opts['package_manager'] = 'dnf5'
config_opts['nosync'] = True
config_opts['extra_chroot_dirs'] = [ '/run/lock', ]
config_opts['use_bootstrap'] = False
#config_opts['bootstrap_image'] = 'ghcr.io/terrapkg/builder:f{{ releasever }}'
#config_opts['bootstrap_image_ready'] = True
config_opts['mirrored'] = config_opts['target_arch'] != 'i686'
config_opts['chroot_setup_cmd'] = 'install @{% if mirrored %}buildsys-{% endif %}build /usr/bin/pigz /usr/bin/lbzip2'
config_opts['chroot_additional_packages'] = ['anda-srpm-macros', 'terra-appstream-helper', 'mold']
config_opts['plugin_conf']['root_cache_enable'] = True
# Root caches are host-side; use fast, parallel zstd when installed.
# Otherwise retain Mock's default compressor (including its pigz fallback).
import os
if os.path.exists('/usr/bin/zstd'):
    config_opts['plugin_conf']['root_cache_opts'].update({
        'compress_program': '/usr/bin/zstd -T0 -1',
        'decompress_program': '/usr/bin/zstd -d',
        'extension': '.zst',
    })
config_opts['plugin_conf']['yum_cache_enable'] = True
config_opts['plugin_conf']['ccache_enable'] = config_opts['target_arch'] != 'i686'
config_opts['plugin_conf']['ccache_opts']['compress'] = 'on'
config_opts['plugin_conf']['ccache_opts']['max_cache_size'] = '10G'
config_opts['macros']['%__gzip'] = '/usr/bin/pigz'
config_opts['macros']['%__bzip2'] = '/usr/bin/lbzip2'
config_opts['plugin_conf']['tmpfs_enable'] = True
# Leave RAM for compilation: tmpfs is a limit, not a reservation.
# Small builders fall back to disk; tune for large packages/concurrent jobs.
config_opts['plugin_conf']['tmpfs_opts']['required_ram_mb'] = 8192
config_opts['plugin_conf']['tmpfs_opts']['max_fs_size'] = '50%'
config_opts['plugin_conf']['tmpfs_opts']['mode'] = '0755'
config_opts['plugin_conf']['tmpfs_opts']['keep_mounted'] = False
# repos
dnf_conf = """

[main]
# Match the persistent directory mounted by Mock's yum_cache plugin.
keepcache=1
system_cachedir=/var/cache/dnf
debuglevel=2
reposdir=/dev/null
logfile=/var/log/yum.log
retries=20
obsoletes=1
gpgcheck=0
assumeyes=1
syslog_ident=mock
syslog_device=
install_weak_deps=0
metadata_expire=-1
best=1
module_platform_id=platform:fc{{ releasever }}
protected_packages=
max_parallel_downloads=20

{%- macro rawhide_gpg_keys() -%}
file:///usr/share/distribution-gpg-keys/fedora/RPM-GPG-KEY-fedora-$releasever-primary
{%- for version in [rawhide, rawhide|int - 1, rawhide|int + 1]
%} file:///usr/share/distribution-gpg-keys/fedora/RPM-GPG-KEY-fedora-{{ version }}-primary
{%- endfor %}
{%- endmacro %}

[terra]
name=Terra $releasever
metalink=https://tetsudou.fyralabs.com/metalink?repo=terra$releasever&arch=$basearch
type=rpm
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///usr/share/distribution-gpg-keys/terra/RPM-GPG-KEY-terra$releasever
enabled=1
enabled_metadata=1
metadata_expire=0

[terra-extras]
name=Terra $releasever (Extras)
metalink=https://tetsudou.fyralabs.com/metalink?repo=terra$releasever-extras&arch=$basearch
type=rpm
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///usr/share/distribution-gpg-keys/terra/RPM-GPG-KEY-terra$releasever-extras
enabled=1
priority=150
enabled_metadata=1
metadata_expire=0

[terra-nvidia]
name=Terra $releasever (NVIDIA)
metalink=https://tetsudou.fyralabs.com/metalink?repo=terra$releasever-nvidia&arch=$basearch
type=rpm
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///usr/share/distribution-gpg-keys/terra/RPM-GPG-KEY-terra$releasever-nvidia
enabled=0
enabled_metadata=1
metadata_expire=0
excludepkgs=dkms-nvidia*

[terra-mesa]
name=Terra $releasever (Mesa)
metalink=https://tetsudou.fyralabs.com/metalink?repo=terra$releasever-mesa&arch=$basearch
type=rpm
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///usr/share/distribution-gpg-keys/terra/RPM-GPG-KEY-terra$releasever-mesa
enabled=0
enabled_metadata=1
metadata_expire=0

[terra-multimedia]
name=Terra $releasever (Multimedia)
metalink=https://tetsudou.fyralabs.com/metalink?repo=terra$releasever-multimedia&arch=$basearch
type=rpm
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///usr/share/distribution-gpg-keys/terra/RPM-GPG-KEY-terra$releasever-multimedia
enabled=0
enabled_metadata=1
metadata_expire=0

[local-rawhide-build]
name=local-rawhide
baseurl=https://kojipkgs.fedoraproject.org/repos/rawhide/latest/$basearch/
cost=2000
enabled={{ not mirrored }}
skip_if_unavailable=False

{% if mirrored %}
[fedora]
name=fedora
metalink=https://mirrors.fedoraproject.org/metalink?repo=rawhide&arch=$basearch
gpgkey={{ rawhide_gpg_keys() }}
gpgcheck=1
skip_if_unavailable=False
{% endif %}
"""


config_opts['dnf.conf'] = dnf_conf
config_opts['dnf5.conf'] = dnf_conf
