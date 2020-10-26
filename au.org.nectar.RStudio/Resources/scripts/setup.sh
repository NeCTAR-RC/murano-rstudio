#!/bin/bash -xe

USERNAME="$1"
ORIGUSER="ubuntu"

# Assume last disk is our attached storage,
# except /dev/vda which is our root disk
DISK=$(ls /dev/vd[b-z] | tail -n1)

# Check if the disk is mounted (e.g. if ephemeral)
MOUNTPOINT=$(lsblk -n $DISK -o MOUNTPOINT)

# If we have a disk, but it's not mounted, then it's probably
# our external volume for home
if [ ! -z $DISK ] && [ -z $MOUNTPOINT ]; then

	# Have external mount for /home
	MOUNT="/homevol"

	# Partition label
	if [ "$(lsblk -n -o PARTTYPE $DISK)" == "" ]; then
		parted $DISK mklabel msdos
	fi

	# Partition
	if ! lsblk -n $DISK | grep -q " part "; then
		parted -a opt $DISK mkpart primary ext4 0% 100%
	fi

	# Filesystem
	if [ "$(lsblk -n -o FSTYPE ${DISK}1)" == "" ]; then
		mkfs.ext4 ${DISK}1
	fi

	# Mount volume
	if ! mount | grep -q $MOUNT; then
		mkdir -p $MOUNT
		echo "${DISK}1 $MOUNT ext4 defaults 0 2" >> /etc/fstab
		mount $MOUNT
	fi
else
	# Use regular /home if no volume is found
	MOUNT="/home"
fi

if [ "$USERNAME" != "$ORIGUSER" ]; then

  ORIGHOME=$(eval echo "~$ORIGUSER" )
  # Only if the user still exists and has their home directory, do the move
  # otherwise assume we've done it already
  if id $ORIGUSER && [ -d $ORIGHOME ]; then
		# Rename the user
		usermod --login $USERNAME $ORIGUSER

		if [ -d $MOUNT/$USERNAME ]; then
			# Set home dir to existing volume, and make 'users' the primary group
			usermod --home $MOUNT/$USERNAME --gid users --comment $USERNAME $USERNAME
			# Append cloud-init ssh key to authorized_keys file in existing home
			cat $ORIGHOME/.ssh/authorized_keys >> $MOUNT/$USERNAME/.ssh/authorized_keys
			# cloud-init home dir not needed so remove it
			rm -rf $ORIGHOME
		else
			# Set and move home dir to new location, and make 'users' the primary group
			usermod --home $MOUNT/$USERNAME --move-home --gid users --comment $USERNAME $USERNAME
		fi

		# Replace cloud user in cloud-init
		sed -i -e "s/name: $ORIGUSER/name: $USERNAME/g" -e "s/gecos: .*/gecos: $USERNAME/g" /etc/cloud/cloud.cfg
		sed -i "s/$ORIGUSER/$USERNAME/g" /etc/sudoers.d/90-cloud-init-users
	fi
fi

set +x
# Set password for user (and don't log it)
PASSWORD="$2"
echo "${USERNAME}:${PASSWORD}" | chpasswd

# Nuke the password from the murano log file
# NOTE: We need to escape regex chars here or this statement will fail
ESCAPED_PASSWORD=$(printf '%s\n' "$PASSWORD" | sed -e 's/[]\/$*.^[]/\\&/g')
sed -i "s/${ESCAPED_PASSWORD}/******/g" /var/log/murano-agent.log

# vim: ts=2 sw=2 :
