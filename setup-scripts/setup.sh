#!/bin/bash

echo "###########################################"
echo "#   Welcome to the music-man installer!   #"
echo "#    We are going to setup this pi now    #"
echo "###########################################"
echo "#          Any issues? Contact:           #"
echo "#     helpdesk@racetrackpitstop.co.uk     #"
echo "###########################################"

sleep 10s

while getopts s option
    do
    case "${option}"
        in
            s) SITENAME=${OPTARG,,};;
    esac
done

if [ -z "$SITENAME" ]; then
    echo " "
    echo "###########################################"
    echo "# Pass a command flag with the site name  #"
    echo "#        Eg. setup.sh -s Braeside         #"
    echo "#   Exiting now... please try again!      #"
    echo "###########################################"
    exit
fi

if [ "$EUID" -ne 0 ]; then
    echo " "
    echo "###########################################"
    echo "#          Please run with sudo           #"
    echo "#   Exiting now... please try again!      #"
    echo "###########################################"
    exit
fi


echo "###########################################"
echo "#        Changing default password        #"
echo "###########################################"

sleep 3s
PASSWORD=$(date +%s | sha256sum | base64 | head -c 32)
echo "pi:$PASSWORD" | chpasswd


echo "###########################################"
echo "#       Making sure we are up-to-date     #"
echo "###########################################"

sleep 3s
apt-get update
apt-get upgrade -y

echo "###########################################"
echo "#      Installing vlc, pulse & samba      #"
echo "###########################################"

sleep 3s
apt-get install -y vlc
apt-get install -y samba samba-common-bin
apt-get --purge --reinstall install -y pulseaudio
echo "###########################################"
echo "#             Set up Samba                #"
echo "###########################################"

sleep 3s
sudo mkdir -m 1777 /home/pi/Music
echo "[share]" >> /etc/samba/smb.conf
echo "Comment = Music-Man shared folder" >> /etc/samba/smb.conf
echo "Path = /home/pi/Music" >> /etc/samba/smb.conf
echo "Browseable = yes" >> /etc/samba/smb.conf
echo "Writeable = yes" >> /etc/samba/smb.conf
echo "only guest = no" >> /etc/samba/smb.conf
echo "create mask = 0777" >> /etc/samba/smb.conf
echo "directory mask = 0777" >> /etc/samba/smb.conf
echo "Public = no" >> /etc/samba/smb.conf
echo "Guest ok = no" >> /etc/samba/smb.conf
(echo $PASSWORD; echo $PASSWORD) | smbpasswd -a pi

echo "###########################################"
echo "# Make sure we grab fresh scripts at boot #"
echo "###########################################"

sleep 3s
mkdir /home/pi/music-man/
chmod 777 /home/pi/music-man
echo "wget https://raw.githubusercontent.com/RT-IT/music-man/master/localMusic.sh -O /home/pi/music-man/localMusic.sh" >> /home/pi/.bashrc
echo "chmod 777 /home/pi/music-man/localMusic.sh" >> /home/pi/.bashrc
echo "chmod +x /home/pi/music-man/localMusic.sh" >> /home/pi/.bashrc
echo "wget https://raw.githubusercontent.com/RT-IT/music-man/master//remoteMusic.sh -O /home/pi/music-man/remoteMusic.sh" >> /home/pi/.bashrc
echo "chmod 777 /home/pi/music-man/remoteMusic.sh" >> /home/pi/.bashrc
echo "chmod +x /home/pi/music-man/remoteMusic.sh" >> /home/pi/.bashrc
echo "wget https://raw.githubusercontent.com/RT-IT/music-man/master//noMusic.sh -O /home/pi/music-man/noMusic.sh" >> /home/pi/.bashrc
echo "chmod 777 /home/pi/music-man/noMusic.sh" >> /home/pi/.bashrc
echo "chmod +x /home/pi/music-man/noMusic.sh" >> /home/pi/.bashrc
echo "wget https://raw.githubusercontent.com/RT-IT/music-man/master//connectivity.sh -O /home/pi/music-man/connectivity.sh" >> /home/pi/.bashrc
echo "chmod 777 /home/pi/music-man/connectivity.sh" >> /home/pi/.bashrc
echo "chmod +x /home/pi/music-man/connectivity.sh" >> /home/pi/.bashrc
echo "amixer sset 'Master' 65%" >> /home/pi/.bashrc

echo "###########################################"
echo "#          Setting up Music-Man           #"
echo "###########################################"

sleep 3s
touch /home/pi/musicManPlayMode.txt
touch /home/pi/musicManSiteName.txt
echo "siteName=\"$SITENAME\"" > /home/pi/musicManSiteName.txt
echo 'musicManPlayMode="remote"' >> /home/pi/musicManPlayMode.txt
chmod 777 /home/pi/musicManPlayMode.txt
chmod 777 /home/pi/musicManSiteName.txt

chown pi:pi -R /home/pi/musicManPlayMode.txt
chown pi:pi -R /home/pi/musicManSiteName.txt

amixer cset numid=3 1
systemctl enable ssh
systemctl start ssh

echo "###########################################"
echo "#             Setting up Cron             #"
echo "###########################################"

sleep 3s
crontab -l -u pi > mycron
echo "@reboot sleep 30 && /bin/bash /home/pi/music-man/connectivity.sh" >> mycron
echo "*/2 * * * * /bin/bash /home/pi/music-man/connectivity.sh" >> mycron
echo "0 1 * * * /sbin/reboot" >> mycron
#echo "*/5 * * * * /bin/bash /home/pi/music-man/connectivity.sh" >> mycron
#echo "0 8 * * * /bin/bash /home/pi/music-man/remoteMusic.sh" >> mycron
#echo "0 14 * * * /bin/bash /home/pi/music-man/localMusic.sh" >> mycron
#echo "0 22 * * * /bin/bash /home/pi/music-man/noMusic.sh" >> mycron
crontab -u pi mycron
rm mycron

echo "###########################################"
echo "#           Renaming the system           #"
echo "###########################################"
sleep 3s
macAddr=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address)
macAddrBt=${macAddr//:}
sed -i 's/raspberrypi/musicman-'$macAddrBt'/g' /etc/hostname
sed -i 's/raspberrypi/musicman-'$macAddrBt'/g' /etc/hosts


echo "###########################################"
echo "#          You should be good to go       #"
echo "#     Please take note of the following:  #"
echo "#     Username: pi                        #"
echo "#     Password: $PASSWORD"
echo "#     Hostname: musicman-$macAddrBt       #"
echo "###########################################"
echo "#          Any issues? Contact:           #"
echo "#     helpdesk@racetrackpitstop.co.uk     #"
echo "###########################################"

