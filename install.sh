#!/bin/bash

# Check if Script is Run as Root
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user to run this script, please run sudo ./install.sh" 2>&1
  exit 1
fi

username=$(id -u -n 1000)
builddir=$(pwd)

echo "Which browser would you like to install? Please select 1, 2, 3, or 4"
echo "Options: firefox (1), chromium (2), brave browser (3), google chrome (4)"
echo "Please note that if you choose 1, 2, or 4, the Super+B shortcut for the browser will not work, so after install you'll have to edit the sxhkdrc file to change to your preferred browser."
read -rp "Enter browser number: " browser
browser_choice=$(echo "$browser" | tr '[:upper:]' '[:lower:]')

# Function to install Brave (requires special steps)
install_brave() {
    echo "Installing Brave..."
    sudo nala install curl -y
    sudo curl -fsSL https://brave.com/signing-key.asc | gpg --dearmor -o /usr/share/keyrings/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
        | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo nala update
    sudo nala install brave-browser -y
}

# Update packages list and update system
apt update
apt upgrade -y


# Install nala
apt install nala -y

# Making .config and Moving config files and background to Pictures
cd $builddir
mkdir -p /home/$username/.config
mkdir -p /home/$username/.fonts
mkdir -p /home/$username/Pictures
cp .Xresources /home/$username
cp .Xnord /home/$username
cp -R dotconfig/* /home/$username/.config
cp background.jpg /home/$username/Pictures/background.jpg
mv user-dirs.dirs /home/$username/.config
chown -R $username:$username /home/$username

# Installing Essential Programs 
nala install feh bspwm sxhkd kitty arandr rofi polybar picom thunar lxpolkit x11-xserver-utils unzip yad wget pulseaudio pavucontrol -y
# Installing Other less important Programs
nala install neofetch flameshot psmisc vim lxappearance papirus-icon-theme fonts-noto-color-emoji lightdm zoxide -y

# Download Nordic Theme
cd /usr/share/themes/
git clone https://github.com/EliverLara/Nordic.git

# Installing fonts
cd $builddir 
nala install fonts-font-awesome -y
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip
unzip FiraCode.zip -d /home/$username/.fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Meslo.zip
unzip Meslo.zip -d /home/$username/.fonts
mv dotfonts/fontawesome/otfs/*.otf /home/$username/.fonts/
chown $username:$username /home/$username/.fonts/*

# Reloading Font
fc-cache -vf
# Removing zip Files
rm ./FiraCode.zip ./Meslo.zip

# Install Simp1e cursors (dwm-titus)
cd $builddir
tar -xvf Simp1e.tar.xz
mv Simp1e /usr/share/icons/

# Install browser of choice
case "$browser_choice" in
    1|"firefox")
        echo "Installing Firefox..."
        sudo nala install -y firefox
        ;;
    2|"chromium")
        echo "Installing Chromium..."
        sudo nala install -y chromium
        ;;
    3|"brave")
        install_brave
        ;;
    4|"google chrome"|"chrome")
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo nala install ./google-chrome-stable_current_amd64.deb -y
        rm -f ./google-chrome-stable_current_amd64.deb
        ;;
    *)
        echo "Unsupported browser: $browser_choice"
        exit 1
        ;;
esac

# Enable graphical login and change target from CLI to GUI
systemctl enable lightdm
systemctl set-default graphical.target

# Polybar configuration
bash scripts/changeinterface

# Use nala
bash scripts/usenala
