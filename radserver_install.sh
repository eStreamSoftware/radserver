#! /bin/sh
if [ `whoami` != root ]; then
	echo "Root permissions required. Please re-run the installer with the \"sudo\" command."
	exit
fi

[ -f "/etc/os-release" ] && . /etc/os-release && [ "$ID" = "debian" ] && isDebian=true

#------SILENT INSTALL---------
if [ "$#" -gt 0 ]; then
	if [ "$1" = "-silent" ]; then
		if [  -n "$(uname -a | grep Ubuntu)" ] || [ $isDebian ]; then
			apt-get -qq update
			ctl=`which apachectl`
			if [ "$ctl" = "" ]; then
				apt-get -qq install apache2
			fi
			apt-get -qq install curl
		else
			# check for centos/redhat release 7
			if rpm -qf /etc/redhat-release | grep -q release-7; then
				# install EPEL
				[ -f /etc/yum.repos.d/epel.repo ] || yum -y install epel-release

				# install city-fan.org-release if not yet on system
				[ -f /etc/yum.repos.d/city-fan.org.repo ] || yum -y install http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-2-1.rhel7.noarch.rpm

				# enable repos and limit packages
				yum-config-manager --enable epel >/dev/null
				yum-config-manager --enable city-fan.org >/dev/null
				yum-config-manager --save --setopt="city-fan.org.includepkgs=curl* libcurl* libssh2* libmetalink* libpsl* libnghttp2*" >/dev/null

				yum -q -y update curl
				yum -q -y install curl
			fi

			sed -i 's/enforcing/permissive/g' /etc/selinux/config /etc/selinux/config
			setenforce permissive

			conf=`find / -name httpd.conf`
			if [ "$conf" = "" ]; then
				yum -q -y update httpd
				yum -q -y install httpd
			fi
		fi
		if [ -e RSValues.txt ]; then
			rm RSValues.txt
		fi
		echo "INSTALLER_UI=silent" >> RSValues.txt
		echo "CHOSEN_FEATURE_LIST=IB,RS,RC,SUI" >> RSValues.txt
		echo "CHOSEN_INSTALL_FEATURE_LIST=IB,RS,RC,SUI" >> RSValues.txt
		echo "Root_Server_Path=radserver" >> RSValues.txt
		echo "Root_Console_Path=radconsole" >> RSValues.txt
		echo "You selected silent mode";
		if [ -e ./radserverlicense.slip ]; then 
			chmod +x ./RADServer.bin
			./RADServer.bin -f RSValues.txt 
			rm RSValues.txt
			exit
		else
			echo "radserverlicense.slip file not found. Make sure it is in the same directory as the installer"
			exit
		fi
	else
		echo "Usage: sh radserver_install.sh [-silent]";
		exit
	fi
	chmod +x /tmp/linux_cleanup.sh
	sh /tmp/linux_cleanup.sh
else
#------END SILENT INSTALL---------

export NEWT_COLORS='
root=white,blue
roottext=white,blue
border=gray,lightgray
window=gray,lightgray
title=black,lightgray
button=black,gray
checkbox=black,lightgray
actcheckbox=white,black
textbox=black,lightgray
compactbutton=black,lightgray
'

#-------INSTALL REQUIREMENTS--------
if [  -n "$(uname -a | grep Ubuntu)" ] || [ $isDebian ]; then
	apt-get -qq update
	if [ ! -e "/usr/bin/unzip" ]; then
		apt-get -qq install unzip
	fi
	#ubuntu check if apachectl exists ask if user wants to install
	ctl=`which apachectl`
	if [ "$ctl" = "" ]; then
		installApache=$(whiptail --title "RAD Server Production Installation" \
						--backtitle "Copyright 2019 Embarcadero Technologies" \
						--yesno "This software requires Apache. Would you like to install it?" 15 55 \
						3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			apt-get -qq install apache2
		fi
	fi
	apt-get -qq install curl
else
	# check for centos/redhat release 7
	if rpm -qf /etc/redhat-release | grep -q release-7; then
		installLibraries=$(whiptail --title "RAD Server Production Installation" \
						--backtitle "Copyright 2019 Embarcadero Technologies" \
						--yesno "This software requires updated libraries (curl*, libcurl*, libssh2*, libmetalink*, libpsl*, libnghttp2*) for your version of Linux which are available from the city-fan.org repo. Would you like to install them?" 15 55 \
						3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			# install EPEL
			[ -f /etc/yum.repos.d/epel.repo ] || yum -y install epel-release

			# install city-fan.org-release if not yet on system
			[ -f /etc/yum.repos.d/city-fan.org.repo ] || yum -y install http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-2-1.rhel7.noarch.rpm

			# enable repos and limit packages
			yum-config-manager --enable epel >/dev/null
			yum-config-manager --enable city-fan.org >/dev/null
			yum-config-manager --save --setopt="city-fan.org.includepkgs=curl* libcurl* libssh2* libmetalink* libpsl* libnghttp2*" >/dev/null

			yum -q -y update curl
			yum -q -y install curl
		fi
	fi

	openSELinux=$(whiptail --title "RAD Server Production Installation" \
						--backtitle "Copyright 2019 Embarcadero Technologies" \
						--yesno "This software requires SELinux to be switched to permissive mode. Would you like to do that now?" 15 55 \
						3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i 's/enforcing/permissive/g' /etc/selinux/config /etc/selinux/config
		setenforce permissive
	fi

	if [ ! -e "/usr/bin/unzip" ]; then
		yum -q -y install unzip
	fi
	#check if apachectl exists ask if user wants to install
	conf=`find / -name httpd.conf`
	if [ "$conf" = "" ]; then
		installApache=$(whiptail --title "RAD Server Production Installation" \
						--backtitle "Copyright 2019 Embarcadero Technologies" \
						--yesno "This software requires Apache. Would you like to install it?" 15 55 \
						3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus = 0 ]; then
			yum -q -y update httpd
			yum -q -y install httpd
		fi
	fi
fi
#-------END INSTALL REQUIREMENTS--------

#-------INSTALL PROCESS-----------------
#Multiselect prompt put results into CHOICE
CHOICE=$(whiptail --notags --title "RAD Server Production Installation" \
	--backtitle "Copyright 2019 Embarcadero Technologies" \
	--checklist "\nSelect items to install" 15 55 5 \
	InterBase "RAD Server DB (InterBase 2020)" on \
	RADServer "RAD Server" on \
	RADConsole "RAD Server Console" on \
	SwaggerUI "Swagger UI" on \
	3>&1 1>&2 2>&3)
exitstatus=$?
	if [ $exitstatus = 0 ]; then
		if [ -e RSValues.txt ]; then
			rm RSValues.txt
		fi
		echo "INSTALLER_UI=silent" >> RSValues.txt
		featureList="CHOSEN_FEATURE_LIST="
		installFeatureList="CHOSEN_INSTALL_FEATURE_LIST="
		rootServerPath=""
		rootConsolePath=""
		port=""
		IBInstall=false
		case "$CHOICE" in
			*InterBase*)
				if [ -e ./radserverlicense.slip ]; then
					IB="IB,"
					featureList="$featureList$IB"
					installFeatureList="$installFeatureList$IB"
				else
					IBInstall=true
				fi
				echo "You selected InterBase to be installed";
				;;
		esac
		case "$CHOICE" in
			*RADServer*) 
				RS="RS,"
				featureList="$featureList$RS"
				installFeatureList="$installFeatureList$RS"
				if [ -z "$rootServerPath" ]; then
					#if rootpath variable is empty prompt for root path
					rootServerPath=$(whiptail --title "RAD Server Production Installation" \
						--backtitle "Copyright 2019 Embarcadero Technologies" \
						--inputbox "Enter root server path. \n(example: http://yoursite.com/{root_path}/)" 15 50 radserver \
						3>&1 1>&2 2>&3)
					if [ "$rootServerPath" = "" ]; then rootServerPath="radserver"; fi
					echo "You entered: $rootServerPath"
				fi
				echo "You selected RADServer to be installed";
				;;
		esac
		case "$CHOICE" in
			*RADConsole*) 
				RSC="RC,"
				featureList="$featureList$RSC"
				installFeatureList="$installFeatureList$RSC"
				if [ -z "$rootConsolePath" ]; then
					#if rootpath variable is empty prompt for root path
					rootConsolePath=$(whiptail --title "RAD Server Production Installation" \
						--backtitle "Copyright 2019 Embarcadero Technologies" \
						--inputbox "Enter root console path. \n(example: http://yoursite.com/{root_path}/)" 15 50 radconsole \
						3>&1 1>&2 2>&3)
					if [ "$rootConsolePath" = "" ]; then rootConsolePath="radconsole"; fi
					echo "You entered: $rootConsolePath"
				fi
				echo "You selected RADConsole to be installed";
				;;
		esac
		case "$CHOICE" in
			*SwaggerUI*) 
				SUI="SUI,"
				featureList="$featureList$SUI"
				installFeatureList="$installFeatureList$SUI"
				echo "You selected Swagger UI to be installed";
				;;
		esac
		#-----INTERBASE SELECTED AND SLIP FILE DOES NOT EXIST----
		#we need to run interbase on the outside because we need
		#to run the license manager before rad server installs
		if [ "$IBInstall" = true ]; then 
			#Extract InterBase to the temp directory
			if [ -e ./InterBase_2020_Linux.zip ]; then
				unzip -q -o InterBase_2020_Linux.zip -d /tmp/
				chmod +x /tmp/ib_install_linux_x86_64.bin
				echo "INSTALLER_UI=silent" > /tmp/IBValues.txt
				echo "CHOSEN_INSTALL_SET=Server" >> /tmp/IBValues.txt
				echo "REG=FALSE" >> /tmp/IBValues.txt
				/tmp/ib_install_linux_x86_64.bin -f  /tmp/IBValues.txt
				echo "Use the Licence Manager to register your RADServer License. Once you have done so, continue."
				/opt/interbase/bin/LicenseManagerLauncher -i console
			else
				echo "InterBase_2020_Linux.zip not found. Make sure it is in the same directory as the installer."
				exit
			fi
		fi
		#---END INTERBASE SELECTED AND SLIP FILE DOES NOT EXIST--
		echo "$featureList" >> RSValues.txt
		echo "$installFeatureList" >> RSValues.txt
		echo "Root_Server_Path=$rootServerPath" >> RSValues.txt
		echo "Root_Console_Path=$rootConsolePath" >> RSValues.txt
		chmod +x ./RADServer.bin
		./RADServer.bin -f RSValues.txt 
		rm -f RSValues.txt
		echo "Install complete!"
	else
		echo "You chose Cancel."
	fi
fi
#-------END INSTALL PROCESS-----------------