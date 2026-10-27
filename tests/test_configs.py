"""Validate all configs with Mock"""

import configparser
import os
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from mockbuild.config import setup_default_config_opts, update_config_from_file

REPO = Path(__file__).resolve().parents[1]
CONFIGS = sorted(REPO.glob("*.cfg"))


class ConfigTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workspace = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls.workspace.cleanup)
        cls.config_dir = Path(cls.workspace.name)
        templates = cls.config_dir / "templates"
        templates.mkdir()
        for template in REPO.glob("*.tpl"):
            shutil.copyfile(template, templates / template.name)

    def load_config(self, path):
        # Do not load host/user overrides: test the shipped templates in isolation.
        opts = setup_default_config_opts()
        opts["config_path"] = str(self.config_dir)
        update_config_from_file(opts, str(path))
        opts["__jinja_expand"] = True
        return opts

    def test_all_configs(self):
        self.assertTrue(CONFIGS)
        for path in CONFIGS:
            with self.subTest(config=path.name):
                opts = self.load_config(path)
                plugins = opts["plugin_conf"]
                dnf = configparser.ConfigParser(interpolation=None)
                dnf.read_string(opts["dnf.conf"])
                self.assertEqual(dnf["main"].getint("debuglevel"), 2)
                self.assertEqual(dnf["main"].getint("max_parallel_downloads"), 20)
                self.assertEqual(dnf["main"].getint("metadata_expire"), 60)
                for section in dnf.sections():
                    self.assertEqual(
                        dnf[section].getint(
                            "metadata_expire", fallback=dnf["main"].getint("metadata_expire")
                        ),
                        60,
                        section,
                    )
                arch = opts["target_arch"]
                release = opts["releasever"]
                is_el = path.name.startswith("terra-el")
                expected_ccache = is_el or arch != "i686" or (
                    release != "rawhide" and int(release) < 44
                )
                self.assertEqual(plugins["ccache_enable"], expected_ccache)
                self.assertTrue(opts["nosync"])
                defaults = setup_default_config_opts()["plugin_conf"]
                for key in ("dir", "age_check", "max_age_days", "exclude_dirs"):
                    self.assertIn(key, plugins["root_cache_opts"])
                self.assertEqual(
                    plugins["root_cache_opts"]["exclude_dirs"],
                    defaults["root_cache_opts"]["exclude_dirs"],
                )
                for section in dnf.sections():
                    if section == "main" or section.startswith("local-"):
                        continue
                    self.assertEqual(dnf[section].getint("gpgcheck"), 1, section)
                    self.assertTrue(dnf[section].get("gpgkey"), section)
                    if section.startswith("terra"):
                        self.assertEqual(dnf[section].getint("repo_gpgcheck"), 1, section)
                self.assertTrue(plugins["root_cache_enable"])
                self.assertTrue(plugins["yum_cache_enable"])
                self.assertTrue(plugins["tmpfs_enable"])
                self.assertEqual(plugins["tmpfs_opts"]["max_fs_size"], "50%")
                self.assertEqual(plugins["tmpfs_opts"]["required_ram_mb"], 8192)
                self.assertFalse(plugins["tmpfs_opts"]["keep_mounted"])
                self.assertEqual(
                    "ccache" in opts["chroot_additional_packages"],
                    plugins["ccache_enable"],
                )
                for program in ("pigz", "lbzip2"):
                    self.assertIn("/usr/bin/" + program, opts["chroot_setup_cmd"])
                self.assertEqual(opts["macros"]["%__gzip"], "/usr/bin/pigz")
                self.assertEqual(opts["macros"]["%__bzip2"], "/usr/bin/lbzip2")
                self.assertEqual(
                    opts["macros"]["%_binary_payload"],
                    "w19T%{_smp_build_nthreads}.zstdio",
                )
                if opts["package_manager"] == "dnf5":
                    self.assertEqual(
                        opts["macros"]["%_man_info_compress"],
                        "pigz -9 -n -p %{_smp_build_nthreads}",
                    )
                    self.assertEqual(opts["dnf.conf"], opts["dnf5.conf"])
                    self.assertEqual(dnf["main"]["system_cachedir"], "/var/cache/dnf")
                    group = (
                        "@build" if opts["target_arch"] == "i686" else "@buildsys-build"
                    )
                    self.assertEqual(opts["chroot_setup_cmd"].split()[1], group)

    def test_root_cache_compressor(self):
        real_exists = os.path.exists
        for pzstd_available, zstd_available in (
            (False, False), (False, True), (True, False), (True, True)
        ):
            available = {
                "/usr/bin/pzstd": pzstd_available,
                "/usr/bin/zstd": zstd_available,
            }
            for path in CONFIGS:
                with self.subTest(config=path.name, available=available):
                    defaults = setup_default_config_opts()["plugin_conf"][
                        "root_cache_opts"
                    ]
                    with patch(
                        "os.path.exists",
                        side_effect=lambda path: (
                            available[path] if path in available else real_exists(path)
                        ),
                    ):
                        opts = self.load_config(path)["plugin_conf"]["root_cache_opts"]
                    if pzstd_available:
                        self.assertEqual(opts["compress_program"], "/usr/bin/pzstd -1")
                        self.assertEqual(opts["decompress_program"], "/usr/bin/pzstd -d")
                        self.assertEqual(opts["extension"], ".pzst")
                    elif zstd_available:
                        self.assertEqual(
                            opts["compress_program"], "/usr/bin/zstd -T0 -1"
                        )
                        self.assertEqual(opts["decompress_program"], "/usr/bin/zstd -d")
                        self.assertEqual(opts["extension"], ".zst")
                    else:
                        for key in (
                            "compress_program",
                            "decompress_program",
                            "extension",
                        ):
                            self.assertEqual(opts[key], defaults[key])


if __name__ == "__main__":
    unittest.main()
