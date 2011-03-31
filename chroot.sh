#!/bin/sh

# This script will help you to chroot somewhere with kernel
# and device filesystems mounted and nameservers set up

#     This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

die() {
	echo "$@"
	exit 1
}

USAGE="Usage: $(basename $0) <device> [program]
You can specity \$MOUNTOPTIONS to add some mount options, e.g:
MOUNTOPTIONS=loop,offset=32256  $(basename $0) ./disk.hda /bin/sh"

LINE="--------------------------------------------------------------------------------"

test $# -eq 1 -o $# -eq 2  || die "$USAGE"

if test "$MOUNTOPTIONS"
then
	MOUNTOPTIONS="-o $MOUNTOPTIONS"
fi

PROGRAM="$2"
test "$PROGRAM" || PROGRAM="/bin/bash"

echo -n "Mounting $1 to /mnt... "
mount $MOUNTOPTIONS "$1" /mnt || die "failed"
echo "OK"

echo -n "Mounting kernel and device filesystems:"
for fs in proc sys dev
do
	echo -n " $fs"
	mount -o bind /$fs /mnt/$fs || die "failed"
done
echo .

echo -n "Copying /etc/resolv.conf"
cp -L /etc/resolv.conf /mnt/etc/resolv.conf || die "failed"
echo .

echo "Entering chroot."
echo $LINE
chroot /mnt "$PROGRAM"
EXITCODE=$?
echo $LINE
echo "Exiting chroot."

echo -n "Unmounting kernel and device filesystems:"
for fs in dev sys proc
do
	echo -n " $fs"
	umount /mnt/$fs || die "failed"
done
echo .

echo -n "Unmounting $1 from /mnt... "
umount /mnt || die "failed"
echo "OK"

echo "Exiting with exit code $EXITCODE."
exit $EXITCODE
