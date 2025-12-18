#!/bin/sh

# param $1: Your UGent password
function configureEduroam() {
    echo "Configuring netctl eduroam"
    sed "s/\(password=\)\"[^\"]*\"/\1\"$1\"/" ugent/wlp2s0-eduroam-no-password
    sudo mv ugent/wlp2s0-eduroam /etc/netctl/
    echo "Done! Use \'netctl start wlp2s0-eduroam\' to connect."
}

function configureVpnc() {
    echo "Configuring vpnc ..."
    sudo cp ugent/vpnc.conf /etc/vpnc/ugent.conf
    echo "Done! Use 'sudo vpnc ugent.conf' to use UGent VPN"
}

