#!/bin/bash

vg='cinder-volumes'
vgs |grep $vg 2>&1 >/dev/null

if [ $? -gt 0 ]; then
  echo "Cinder volumes VG not found. Please verify \$vg inside script"
  exit 1
fi

cd /var/lib/cinder/volumes
mysql -BNe "select id,provider_auth from cinder.volumes where deleted = 0 and host = \"`hostname`@lvm#LVM_iSCSI\"" > creds

for v in $(awk '/CHAP/ {print $1}' creds); do
  usr=$( awk "/$v/ {print \$3}" creds)
  pass=$( awk "/$v/ {print \$4}" creds)
  echo "<target iqn.2010-10.org.openstack:volume-$v>
      backing-store /dev/cinder-volumes/volume-$v
      driver iscsi
      incominguser $usr $pass
      write-cache on
  </target>" > volume-${v}
done

chown cinder:cinder volume-*
rm -f creds
service tgt restart
