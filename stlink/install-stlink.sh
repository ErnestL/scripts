#!/bin/bash

##########################################
# ernest.lotter@gmail.com
# 03 Feb 2017
# 
# Script to install specific version of 
# stlink tools tested in Ubuntu 16.04 LTS
##########################################

INSTALL_FOLDER="stlink-install-temp"
STLINK_GIT_REPOSITORY="https://github.com/texane/stlink"
STLINK_GIT_BRANCH="88c6162e457568225b2ea9be4c034b7f0e4b566a"
STLINK_GIT_FOLDER="stlink.git"
STLINK_GIT_INSTALL_FOLDER="build/Release"
UDEV_RULES=etc/udev/rules.d
STLINK_GUI="stlink-gui"

# ---------- Request sudo if required
sudo ls ./

# ---------- Check if install is required

echo "Checking if specific stlink package is already installed..."

# Check is application can be found
flag_gui_exist="NO"
var_application=$(command -v $STLINK_GUI)
if [ $var_application ]; then
	flag_gui_exist="YES"
	echo "Found application: $var_application"
fi

# Check the version of git branch used to build the application
cd ~/
flag_hash_match="NO"
if [ -d "$INSTALL_FOLDER/$STLINK_GIT_FOLDER" ]; then
	cd $INSTALL_FOLDER/$STLINK_GIT_FOLDER
	var_git_branch=$(git rev-list --max-count=1 HEAD)
	echo "Found branch: $var_git_branch"
	if [ "$var_git_branch" == "$STLINK_GIT_BRANCH" ]; then
		flag_hash_match="YES"
	fi
fi

# If the package is up to date give the user option to force re-install, run or exit
flag_install="YES"
if [ "$flag_gui_exist" == "YES" ] && [ "$flag_hash_match" == "YES" ]; then
	echo "Package is already installed"

	while true; do
    	read -p "Select option: 1. Force re-install, 2. Run stlink-gui, 3. Exit >> " option
    	case $option in
        	[1]* ) break;;
        	[2]* ) flag_install="NO"; break;;
		[3]* ) exit;;
        	   * ) echo "Please select 1, 2 or 3";;
    	esac
	done
fi

# Check if install is required
if [ "$flag_install" == "YES" ]; then

	# ---------- Prepare install folder
	echo "---"
	echo ""
	echo "Check if temp install folder ~/$INSTALL_FOLDER exist"
	cd ~/
	if [ -d "$INSTALL_FOLDER" ]; then
		echo "Install folder exist - clearing contents..."
		cd $INSTALL_FOLDER
		rm -Rf *.*
	else
		echo "Install folder does not exist - creating..."
		mkdir $INSTALL_FOLDER
		cd $INSTALL_FOLDER
	fi

	# ---------- Clone git repository and checkout branch

	echo "---"
	echo ""
	echo "Cloning git repository $STLINK_GIT_REPOSITORY into ~/$INSTALL_FOLDER/$STLINK_GIT_FOLDER..."
	git clone $STLINK_GIT_REPOSITORY $STLINK_GIT_FOLDER
	echo "Checking out branch with hash $STLINK_GIT_BRANCH"
	cd $STLINK_GIT_FOLDER
	git checkout $STLINK_GIT_BRANCH

	# ---------- Install dependencies required for building

	echo "---"
	echo ""
	echo "Packages required: build-essential, cmake, libusb-1.0, libusb-1.0.0-dev and libgtk-3-dev (for gui)"
	echo "Installing dependencies required for building stlink drivers..."
	sudo apt-get install -y build-essential cmake libusb-1.0 libusb-1.0.0-dev libgtk-3-dev

	# ---------- Build stlink

	echo "---"
	echo ""
	echo "Cleaning project..."
	make release
	echo "Making release build..."
	make release
	echo "Installing release build..."
	cd $STLINK_GIT_INSTALL_FOLDER
	sudo make install 
	echo "Updating dynamic link library..."
	sudo ldconfig

	# ---------- Update udev (USB) permissions

	echo "---"
	echo ""
	echo "Updating udev rules..."
	sudo udevadm control --reload-rules
	sudo udevadm trigger
	sudo restart udev           > /dev/null 2>&1  # Pre-16.04
	sudo systemctl restart udev > /dev/null 2>&1  # 16.04 on
fi

# ---------- Run the stlink GUI

echo "---"
echo ""
echo "Note: The power micro flash may contain old update image which is not erased when programming the run image. In this case the bootloader will override a newly flash run image with the old update image. To avoid such unwanted override select option to completely erase flash, before flashing new run image."
echo ""
while true; do
    	read -p "Ensure STLink is connected to powered target and select option: 1. Completely erase flash, 2. Skip, 3. Exit >> " option
    	case $option in
        	[1]* ) st-flash --reset erase; break;;
        	[2]* ) break;;
		[3]* ) exit;;
        	   * ) echo "Please select 1, 2 or 3";;
    	esac
	done
echo "Starting the stlink GUI..."
stlink-gui






