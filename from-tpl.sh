#!/bin/sh
# Generates an AutoUnattend.xml file from AutoUnattend-tpl.xml
# Supported markers (anchored at the begin of a line) in the file are:
# - <!-- Edition: HomeBasic|HomePremium|Professional|Ultimate ...
#   The following lines are only applicable to the mentioned edition.
# - <!-- End ...
#   From now on, show all lines.

edition=$(echo "$1" | tr '[:upper:]' '[:lower:]')
thisdir=$(dirname "$0")
output=${2:-$thisdir/AutoUnattend.xml}

# Select edition with some aliases.
case ${edition} in
homebasic|basic)
    edition=HomeBasic ;;
homepremium|premium)
    edition=HomePremium ;;
professional|pro)
    edition=Professional ;;
ultimate)
    edition=Ultimate ;;
*)
    cat <USAGE
Usage: $0 {HomeBasic | HomePremium | Professional | Ultimate} [AutoUnattend.xml]

The default output file is AutoUnattend.xml, use '-' to write to stdout.
USAGE
    exit 1
    ;;
esac

# Write to stdout when requested
case $output in
-)
    output=/dev/stdout ;;
*)
    echo "Writing edition $edition to $output" ;;
esac

awk -vedition=$edition '
BEGIN {
    show_line = 1;
}
/^<!-- Edition: / {
    show_line = 0;
    n = split($3, applicable_editions, "|");
    for (i = 1; i <= n; i++) {
        if (applicable_editions[i] == edition) {
            show_line = 1;
        }
    }
}
/^<!-- End / {
    show_line = 1;
}
# Show lines other than the marker when requested
show_line && ! /<!-- (Edition:|End) /;
' "$thisdir/AutoUnattend-tpl.xml" > "$output"
# vim: set sw=4 et ts=4:
