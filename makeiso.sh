#!/bin/sh
# Makes an iso suitable for pairing with a Windows installation iso
set -e

thisdir=$(dirname "$0")
output=$1
edition=$2

case $output in
-) output=/dev/stdout ;;
'')
    echo "Usage: $0 output.iso [edition]"
    echo "edition is optional and is passed to from-tpl.sh"
    exit 1
    ;;
esac

[ -z "$edition" ] || "$thisdir/from-tpl.sh" "$edition"

# Make iso, ignoring hidden dotfiles, allow long file names with Joliet
# extensions, using Rock ridge extensions (what for?)
mkisofs -m '.*' -J -r "$thisdir/wsim" > "$output"

# vim: set sw=4 et ts=4:
