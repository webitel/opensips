#!/usr/bin/env bash
# Drive upstream OpenSIPS debhelper-based packaging, then stage each
# selected package into a stable layout for nfpm to repackage.
#
# After a successful run, $SRC/stage/ contains:
#   matrix.json                    — JSON array of {pkgname, description, depends, scripts}
#   <pkgname>/files/               — root-anchored filesystem tree to ship
#   <pkgname>/scripts/<maintainer> — postinst/preinst/postrm/prerm if present
#   <pkgname>/.meta/control        — generated DEBIAN/control (audit reference)
#
# Usage: build.sh <opensips-src-dir> <space-separated-uppercase-tag-list>
set -euo pipefail

SRC="${1:?opensips src dir required}"
TAGS="${2:?target tag list required}"

cd "$SRC"

# Upstream keeps packaging at packaging/debian/, dpkg tools want debian/
[ -e debian ] || ln -s packaging/debian debian

# Restrict upstream rules to the module packages we actually ship.
# Core 'opensips' is always staged regardless.
export BUILD_MODPKG_LIST="$TAGS"
export DEB_BUILD_OPTIONS="parallel=$(nproc)"

echo "::group::dpkg-buildpackage"
# We don't ship the .deb files this produces — we only consume the staged
# debian/<pkg>/ trees and the DEBIAN/control files dh_gencontrol leaves there.
dpkg-buildpackage -b -us -uc
echo "::endgroup::"

STAGE="$PWD/stage"
mkdir -p "$STAGE"
matrix='[]'

extract_field() {
    awk -v f="$1:" '
        $1==f { sub(/^[^:]+:[[:space:]]*/,""); print; exit }
    ' "$2"
}

for d in debian/opensips debian/opensips-*; do
    [ -d "$d/DEBIAN" ] || continue
    pkg=$(basename "$d")
    case "$pkg" in *-dbg) continue;; esac

    pkg_stage="$STAGE/$pkg"
    mkdir -p "$pkg_stage/files" "$pkg_stage/scripts" "$pkg_stage/.meta"

    rsync -a --exclude='/DEBIAN' "$d/" "$pkg_stage/files/"
    cp "$d/DEBIAN/control" "$pkg_stage/.meta/control"

    desc=$(extract_field Description "$d/DEBIAN/control")
    deps=$(extract_field Depends      "$d/DEBIAN/control")

    scripts_yaml=""
    for pair in preinstall:preinst postinstall:postinst preremove:prerm postremove:postrm; do
        nfpm_name="${pair%:*}"
        deb_name="${pair#*:}"
        [ -f "$d/DEBIAN/$deb_name" ] || continue
        install -m 0755 "$d/DEBIAN/$deb_name" "$pkg_stage/scripts/$deb_name"
        scripts_yaml="${scripts_yaml}${nfpm_name}: stage/${pkg}/scripts/${deb_name}"$'\n'
    done

    matrix=$(echo "$matrix" | jq \
        --arg n "$pkg" \
        --arg d "$desc" \
        --arg dep "$deps" \
        --arg s "$scripts_yaml" \
        '. + [{pkgname:$n, description:$d, depends:$dep, scripts:$s}]')
    echo "staged $pkg [depends: $deps]"
done

echo "$matrix" > "$STAGE/matrix.json"
echo "::group::matrix.json"
jq . "$STAGE/matrix.json"
echo "::endgroup::"
