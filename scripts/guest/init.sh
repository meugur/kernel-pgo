#!/bin/bash

passwd -d root

echo "myhost" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "127.0.0.1 myhost" >> /etc/hosts

# Setup networking
touch /etc/rc.local
echo "#!/bin/bash" >> /etc/rc.local
echo "dhclient" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local
chmod 755 /etc/rc.local
systemctl enable rc-local
