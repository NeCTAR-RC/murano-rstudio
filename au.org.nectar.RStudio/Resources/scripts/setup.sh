#!/bin/bash -x

# Vars from Murano
USERNAME="$1"

ORIGUSER="ubuntu"

# Assume last disk is our attached storage
DISK=$(ls -1 /dev/vd? | tail -n1)

# Make partition and filesystem if not exists
if ! lsblk -o NAME,FSTYPE,LABEL,MOUNTPOINT | grep -q "$LABEL"; then
  parted $DISK mklabel msdos
  parted -a opt $DISK mkpart primary ext4 0% 100%
  mkfs.ext4 ${DISK}1
fi

# Mount volume to /home
if ! mount | grep -q '/home'; then
  mv /home /home.backup
  mkdir -p /home
  echo "${DISK}1 /home ext4 defaults 0 2" >> /etc/fstab
  mount /home
  mv /home.backup/* /home
  rmdir /home.backup
fi

if ! id $USERNAME >/dev/null 2>&1; then 
  mv /home/$ORIGUSER /home/$USERNAME
  chown -R $USERNAME:users /home/$USERNAME
  useradd -d /home/$USERNAME -s /bin/bash -M -g users -G adm,dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,netdev $USERNAME
  userdel -rf $ORIGUSER
fi

# Replace cloud user 
sed -i -e "s/name: $ORIGUSER/name: $USERNAME/g" -e "s/gecos: .*/gecos: $USERNAME/g" /etc/cloud/cloud.cfg
sed -i "s/$ORIGUSER/$USERNAME/g" /etc/sudoers.d/90-cloud-init-users

# Set password for user
set +x
PASSWORD="$2"
echo "${USERNAME}:${PASSWORD}" | chpasswd
