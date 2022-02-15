#! /usr/bin/bash 

build_image(){
    echo "Start build image"
    opc_iso_base=$1
    ai_version=$2
    echo "ai_version: ${ai_version}"
    echo "opc_iso_base: ${opc_iso_base}"
    podman build -t descon_httpd httpd --build-arg=ocp_long_version=$opc_iso_base &>> "$LOG_FILE"
    podman build -t descon_registry registry --file=Dockerfile  --build-arg=$ai_version= &>> "$LOG_FILE"
    podman build -t descon_combined combined &>> "$LOG_FILE"
    echo "Image built"
}

add_image(){
    echo "Add ${1} -> ${2}"
    skopeo copy  --authfile=$PULL_SECRET_FILE --dest-tls-verify=false "docker://${1}" "docker://localhost:5000/${2}" &>> "$LOG_FILE"
}

commit(){
    combined_id=$(find_container_id 'localhost/descon_combined')
    name=${2:-localhost/artifacts}
    echo "Commiting $combined_id to $name"
    tempfile=$(mktemp)
    podman commit "${combined_id}" --iidfile=${tempfile} &>> "$LOG_FILE"
    commited_id=$(cat $tempfile) 
    podman tag $commited_id $name &>> "$LOG_FILE"
    rm -rf $tempfile
}

populate_images(){
    ocp_long_version=$1
    ai_version=$2

    ocp_short_version=$(echo $ocp_long_version | sed -e 's|\([0-9]*\.[0-9]*\)\..*|\1|g')

    echo "Populating images for ocp_long_version=$1 ai_version=$2 ocp_short_version=$ocp_short_version"
    
    combined_id=$(podman run -d -p 8080:80 -p 5000:5000 -t localhost/descon_combined)
    
    add_image "quay.io/coreos/coreos-installer:v0.7.0" "coreos/coreos-installer:v0.7.0"
    add_image "quay.io/ocpmetal/postgresql-12-centos7" "ocpmetal/postgresql-12-centos7"
    add_image "quay.io/ocpmetal/assisted-service:${ai_version}" "ocpmetal/assisted-service"
    add_image "quay.io/ocpmetal/assisted-installer:${ai_version}" "ocpmetal/assisted-installer"
    add_image "quay.io/ocpmetal/assisted-installer-controller:${ai_version}" "ocpmetal/assisted-installer-controller"
    add_image "quay.io/ocpmetal/assisted-installer-agent:${ai_version}" "ocpmetal/assisted-installer-agent"
    add_image "quay.io/ocpmetal/ocp-metal-ui:${ai_version}" "ocpmetal/ocp-metal-ui"
    add_image "quay.io/redhat-partner-solutions/registry:2" "redhat-partner-solutions/registry:2"

    # Do it both ways so we can use it either to populate the registry or to replace the registry
    add_image "quay.io/openshift-release-dev/ocp-release:${ocp_long_version}-x86_64" "ocp4/openshift4"
    add_image "quay.io/openshift-release-dev/ocp-release:${ocp_long_version}-x86_64" "openshift-release-dev/ocp-release/${ocp_long_version}-x86_64"

    add_image "registry.redhat.io/redhat/redhat-operator-index:v$ocp_short_version" "redhat/redhat-operator-index:v$ocp_short_version"
    
    # TODO prune for offline using OLM
    add_image "registry.redhat.io/redhat/redhat-operator-index:v$ocp_short_version" "olm-index/redhat-operator-index:v$ocp_short_version"

}

run(){
    pull_secret_file=$1
    ocp_long_version=$2
    result_tag=${3:-artifacts}
    opc_iso_base=${4:-$ocp_long_version}
    ai_version=${5:-v1.0.24.2}
    log_file=${6:-artifact_build.log}

    export LOG_FILE=$log_file
    touch $LOG_FILE
    export PULL_SECRET_FILE="$pull_secret_file"
    
    echo "pull_secret_file: $pull_secret_file"
    echo "log_file: $log_file"
    echo "ocp_long_version: ${ocp_long_version}"
    echo "ai_version: ${ai_version}"
    echo "opc_iso_base: ${opc_iso_base}"

    build_image $opc_iso_base $ai_version
    populate_images $ocp_long_version $ai_version
    commit $container_id "localhost/${result_tag}"
    clean_up 
}

find_container_id(){
    podman ps | grep "${1}" | sed -e 's|\([a-z]*\) .*|\1|g'
}

clean_up(){
    container_id=$(find_container_id 'localhost/descon_combined')
    if [[ ! -z "${container_id}" ]]; then
        echo "${container_id}"

        if [[ ! -z "${LOG_FILE}" ]]; then
            podman rm -f $container_id &>> "$LOG_FILE"
        else
            podman rm -f $container_id
        fi
    fi
}   


set -e

clean_up && run $@ 
clean_up
