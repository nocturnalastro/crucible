# Failed To Upload Boot Files

If you are seeing errors in the container logs like the one below from the `installer` container:

> level=fatal msg="Failed to upload boot files" func=main.main.func1 file="/go/src/github.com/openshift/origin/cmd/main.go:191" error="Failed uploading boot files for OCP version 4.8: Failed fetching from URL https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.8/4.8.14/rhcos-4.8.14-x86_64-live.x86_64.iso: Get \"https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.8/4.8.14/rhcos-4.8.14-x86_64-live.x86_64.iso\": dial tcp: i/o timeout"


To check if the DNS for your container is configured and can resolve `mirror.openshift.com`.
Try the following:
  1. Connect to the containers shell.
      > $ podman run -it ${container_id} /bin/bash
  2. Install bind-utils if they aren't installed already.
      > $ dnf -y install bind-utils
  3. check if you can resolve mirror.openshift.com from dns server 8.8.8.8 or 8.8.4.4 
      >  $ host mirror.openshift.com 8.8.8.8
      >  OR
      >  $ host mirror.openshift.com 8.8.4.4

`8.8.8.8` and `8.8.4.4` is the fallback in the case that they are also unavailable. 
Then you will need to either add a valid dns server to the host config or add a `dns` entry with a valid server to the `assisted_installer` host.
