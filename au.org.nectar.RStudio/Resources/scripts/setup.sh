#!/bin/bash -xe

# Vars from Murano
USERNAME="$1"

ORIGUSER="ubuntu"
MOUNT="/mnt/home"

# Assume last disk is our attached storage
DISK=$(ls -1 /dev/vd? | tail -n1)

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

if ! id $USERNAME >/dev/null 2>&1; then 
  useradd -d $MOUNT/$USERNAME -s /bin/bash -M -g users -G adm,dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,netdev $USERNAME
fi

if [ ! -d $MOUNT/$USERNAME ]; then
  cp -r /home/$ORIGUSER $MOUNT/$USERNAME
  chown -R $USERNAME:users $MOUNT/$USERNAME
  userdel -rf $ORIGUSER || true
fi

# Replace cloud user 
sed -i -e "s/name: $ORIGUSER/name: $USERNAME/g" -e "s/gecos: .*/gecos: $USERNAME/g" /etc/cloud/cloud.cfg
sed -i "s/$ORIGUSER/$USERNAME/g" /etc/sudoers.d/90-cloud-init-users

# Set password for user
set +x
PASSWORD="$2"
echo "${USERNAME}:${PASSWORD}" | chpasswd
