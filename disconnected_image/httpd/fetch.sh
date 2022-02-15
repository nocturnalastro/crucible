#! /usr/bin/bash

ocp_long_version=$1
ocp_short_version=$(echo $ocp_long_version | sed -e "s|\([0-9]\.[0-9]\).*|\1|g")
base_url="https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos"

if [[ "-" == *"${ocp_long_version}"* ]]; then 
    middle_bit="pre-release/${ocp_long_version}"
else
    middle_bit="${ocp_short_version}/${ocp_long_version}"
fi

artifact_base_url="${base_url}/${middle_bit}"

iso_name="rhcos-${ocp_long_version}-x86_64-live.x86_64.iso"
iso_url="${artifact_base_url}/${iso_name}" 
echo $iso_url

rootfs_name="rhcos-live-rootfs.x86_64.img"
rootfs_url="${artifact_base_url}/${rootfs_name}" 
echo $rootfs_url

curl -f "${iso_url}" --output "${2}/${iso_name}"
cp  "${2}${iso_name}" "${2}/live.iso"


curl -f "${rootfs_url}" --output "${2}/${rootfs_name}"
cp  "${2}${rootfs_name}" "${2}/rootfs.iso"