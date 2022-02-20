#!/usr/bin/env bash

if [ ! -d ~/.asdf ]; then
    echo 'Cloning asdf sources'
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.9.0
fi

. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash

grep 'ASDF commands' ~/.bashrc > /dev/null

if [ $? -gt 0 ]
then
    echo "Adding asdf environment setup to ~/.bashrc"
    echo >> ~/.bashrc
    echo >> ~/.bashrc
    echo "#-----------------" >> ~/.bashrc
    echo "# ASDF commands" >> ~/.bashrc
    echo "#-----------------" >> ~/.bashrc
    echo '. $HOME/.asdf/asdf.sh' >> ~/.bashrc
    echo '. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
fi

sudo apt-get -y install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev\
 libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev

asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf install erlang 24.2.1 && asdf global erlang 24.2.1
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
asdf install elixir 1.13.3-otp-24 && asdf global elixir 1.13.3-otp-24
