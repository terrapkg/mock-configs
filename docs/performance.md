- Root and package-manager caches are enabled, along with compiler caching where
  supported. Keep `/var/cache/mock` on persistent storage (or mount it into ephemeral
  builders) to benefit across builds. Fedora's DNF5 cache is explicitly directed to
  `/var/cache/dnf`, which Mock's package-manager cache plugin persists.
- Install `zstd` on the **host/builder container** for fast, parallel level-1
  root-cache compression and fast decompression. Without it, Mock's default
  compressor is retained. Switching compressors creates a new cache on the next
  initialization; old `.gz` caches are not reused or automatically deleted.
- The buildroot uses tmpfs on hosts with more than 8 GiB RAM, capped at 50% of
  physical RAM. This is a size limit, not a reservation; buildroot files and
  compiler processes compete for RAM, and tmpfs can swap. For large packages,
  low-memory/container-limited builders, or concurrent jobs, tune the plugin in
  a local override or use `mock --disable-plugin=tmpfs ...`.
- `nosync` needs the host's nosync libraries, including both architectures on
  multilib hosts. Merely installing `nosync` inside the buildroot does not enable
  Mock's host-side preload setup; check the Mock logs for warnings.
