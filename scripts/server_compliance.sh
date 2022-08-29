#!/bin/bash

function look_for_app_status () {
    var_app=$1
    echo "** $var_app **"
    var_t=$(dpkg -s $var_app 2>&1)
    var_err="$?"
    # echo $var_err
    if [ $var_err -eq 0 ]
    then
        dpkg -s $var_app | grep -i 'status\|version'
    else
        echo "Not found"
    fi
}


function look_for_app () {
    var_app=$1
    var_look_for=$(apt -qq list $var_app --installed 2>&1 | grep -q installed; echo $?)
    echo $?
    if [ $var_look_for -eq 0 ]
    then
        echo "   OK = $var_app"
    else
        echo "   Not found = $var_app"
    fi
}

echo "**** Testing server compliance ****"

arr=( "apt-transport-https" "ca-certificates" "curl" "docker-ce" "docker-ce-cli" "containerd.io" "kubeadm" "kubectl" "kubelet" )

for item in "${arr[@]}"
do
    look_for_app_status $item
done

echo "GPG AND REPO TESTS NOT IMPLEMENTETED. THE SAME APPLIES FOR CONFIGURATIONS OF CONTAINERD, BRIDGE, UFW, SWAP ETC."