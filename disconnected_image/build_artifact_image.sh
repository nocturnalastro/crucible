#! /usr/bin/bash 

build_image(){
    set -e
    echo "---------------"
    echo "Building images"
    podman build -t descon_httpd httpd --build-arg=ocp_long_version=$ocp_iso_base &>> "$LOG_FILE" && \
    podman build -t descon_registry registry --file=Dockerfile  --build-arg=$ai_version= &>> "$LOG_FILE" && \
    podman build -t descon_combined combined &>> "$LOG_FILE"
}

add_image(){
    echo "Add ${1} -> ${2}"
        if [[ ! -z "${PULL_SECRET_FILE}" ]]; then
            skopeo copy \
                --dest-precompute-digests \
                --authfile=$PULL_SECRET_FILE \
                --dest-tls-verify=false \
                "docker://${1}" \
                "docker://localhost:5000/${2}" &>> "$LOG_FILE"
        else
            skopeo copy \
                --dest-precompute-digests \
                --dest-tls-verify=false \
                "docker://${1}" \
                "docker://localhost:5000/${2}" &>> "$LOG_FILE"
        fi

}

commit(){
    name=${1:-'localhost/artifacts'}
    combined_id=$(find_container_id 'localhost/descon_combined')
    echo "----------------"
    echo "Commiting $combined_id to $name"
    tempfile=$(mktemp)
    podman commit "${combined_id}" --iidfile=${tempfile} &>> "$LOG_FILE"
    commited_id=$(cat $tempfile) 
    podman tag $commited_id $name &>> "$LOG_FILE"
    rm -rf $tempfile &>> "$LOG_FILE"
}

build_index(){
    echo "Building Pruned index"
    mkdir -p /tmp/tmp_auth/containers &>> "$LOG_FILE"
    cp $PULL_SECRET_FILE /tmp/tmp_auth/containers/auth.json &>> "$LOG_FILE"

    mirror_package=$(cat $index_packages_file | tr '\n' ',')
    echo $mirror_package

    XDG_RUNTIME_DIR=/tmp/tmp_auth/ \
    opm index prune --from-index "$1" \
        --packages $mirror_package \
        --tag "localhost:5000/$2" &>> "$LOG_FILE"
    podman push --tls-verify=false "localhost:5000/$2" &>> "$LOG_FILE"
    operator_index="localhost:5000/$2"
}

mirror_index(){
    echo "Mirroring index"
    echo "PULL_SECRET_FILE: $PULL_SECRET_FILE"
    echo "index_packages_file: $index_packages_file"
    echo "src: $1"
    echo "dest: $2"
    oc adm catalog mirror  \
        --insecure=true    \
        --registry-config=$PULL_SECRET_FILE \
        "$1" \
        "localhost:5000/$2" &>> "$LOG_FILE"
}

populate_images(){
    ocp_long_version=$1
    ai_version=$2

    ocp_short_version=$(echo $ocp_long_version | sed -e 's|\([0-9]*\.[0-9]*\)\..*|\1|g')

    echo "----------------"
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

    if [ "$mirror_catalog" = true ]; then
        echo "----------------"
        operator_index="registry.redhat.io/redhat/redhat-operator-index:v$ocp_short_version"
        if [[ ! -z "$index_packages_file" ]]; then
            build_index "registry.redhat.io/redhat/redhat-operator-index:v$ocp_short_version" "olm-index/redhat-operator-index:v$ocp_short_version"
        fi
        mirror_index \
            $operator_index \
            "olm"
    fi
}


run(){  
    echo "OCP version: ${ocp_long_version}"
    echo "Assisted Installer version: ${ai_version}"
    echo "OCP iso version: ${ocp_iso_base}"
    echo "log_file: $LOG_FILE"
    echo "mirroring: ${mirror_catalog}"
    echo "pull secret file: ${PULL_SECRET_FILE:-Not provided}"
    build_image
    populate_images $ocp_long_version $ai_version
    commit "localhost/${result_tag}"
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

export LOG_FILE='artifact_build.log'

show_help(){
    echo "Required:"
    echo "  --ocp-version: Target OCP version in X.Y.Z format"
    echo "Optional:"
    echo "  --pull-secret-file: Path to pull secret. Required if mirroring catalog"
    echo "  --ai-version: Assisted installer version (Default: 'v1.0.24.2')"
    echo "  --iso-version: The OCP version used to retreve the RHCOS images (Default: \$ocp-version)"
    echo "  --result-tag: The tag of the resulting container image (Default: 'artifacts')"
    echo "  --log-file: Name of the log file which contains command output (Default: 'artifact_build.log')"
    echo "  --index-packages-file: If provided will be used to prune the operator index"
    echo "  --no-index-filter: Flag which allows you to not provide a package index"
    echo "       Note: the operator catalog is very large and not every operator will work offline. This is not recomended."
    echo "  --help: Show this message"
    exit
}

parse_args(){
    result_tag=artifacts
    ai_version=v1.0.24.2
    mirror_catalog=false
    no_index_filter=false

    if [ $# = 0 ]; then 
        show_help
    fi

    while (( $# > 0 )); do 
        case $1 in
            --pull-secret-file) 
                export PULL_SECRET_FILE=$2 
                shift 2
            ;;
            --ocp-version) 
                ocp_long_version=$2
                shift 2
            ;;
            --ai-version) 
                ai_version=$2
                shift 2
            ;;
            --iso-version) 
                ocp_iso_base=$2
                shift 2
            ;;
            --result-tag) 
                result_tag=$2
                shift 2
            ;;
            --log-file) 
                export LOG_FILE=$2 
                shift 2
            ;;
            --mirror-catalog) 
                mirror_catalog=true
                shift 1
            ;;
            --index-packages-file)
                index_packages_file=$2
                shift 2
            ;;
            --no-index-filter)
                no_index_filter=true
                shift 1
            ;;
            --help) 
                show_help
            ;;
            *) break;
        esac; 
    done

    ocp_iso_base=${ocp_iso_base:-$ocp_long_version}
    touch $LOG_FILE

    if [ "$mirror_catalog" = true ] && [[ -z "${PULL_SECRET_FILE}" ]]; then
        echo "Error: pull-secret-file is required for mirroring the operator catalog"
        exit 1
    fi

    if [ "$mirror_catalog" = true ] && [ "$no_index_filter" = false ] && [[ -z "${index_packages_file}" ]]; then
        echo "Error: unless you add the --no-index-filter you must provide a packages file using --index-packages-file"
        exit 1
    fi
   
}

set -e
parse_args $@
clean_up && run || clean_up
