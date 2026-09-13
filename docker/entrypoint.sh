#!/bin/sh
#
# Image entrypoint (run under tini, which forwards signals such as Ctrl-C).
#
# Commands run as root, and on Linux hosts files created in a bind mount keep
# that ownership, leaving root-owned target/, gdnative/, .godot/ and export/
# directories the host user cannot delete. After the command, hand anything
# owned by root under /build back to the owner of /build. No-op on macOS/Windows
# Docker Desktop (ownership is already mapped) and when /build is root-owned
# (e.g. CI checkouts).

"$@"
rc=$?

if [ "$(id -u)" = 0 ] && [ -d /build ]; then
    owner=$(stat -c %u:%g /build)
    if [ "$owner" != "0:0" ]; then
        find /build -xdev -user 0 -exec chown -h "$owner" {} + 2>/dev/null || true
    fi
fi

exit $rc
