# Network configuration
Network configuration can currently be used in two places in the inventory to configure the network config of a node and the network config of a vm_host.

The `network_config` entry on a node is a simplified version of the `nmstate`([nmstate.io](http://nmstate.io/)) required by the [assisted installer api](https://github.com/openshift/assisted-service/blob/3bcaca8abef5173b0e2175b5d0b722e851e39cee/docs/user-guide/restful-api-guide.md).

#### Static IPs

To activate static IPs in the discovery iso and resulting cluster there is some configuration required in the inventory.

```yaml
network_config:
  interfaces:
    - name: "{{ interface }}"
      mac: "{{ mac }}"
      addresses:
        ipv4:
          - ip: "{{ ansible_host}}"
            prefix: "{{ mask }}"
  dns_server_ips:
    - "{{ dns }}"
    - "{{ dns2 }}"
  routes: # optional
    - destination: 0.0.0.0/0
      address: "{{ gateway }}"
      interface: "{{ interface }}"
```

where the variables are as follows:

- `ip`: The static IP is set
- `dns` & `dns2`: IPs of the DNS servers
- `gateway`: IP of the gateway
- `mask`: Length of subnet mask (e.g. 24)
- `interface`: The name of the interface you wish to configure
- `mac`: Mac address of the interface you wish to configure

## Examples

### Link Aggregation

```yaml
network_config:
  interfaces:
    - name: bond0
      type: bond
      state: up
      addresses:
        ipv4:
          - ip: 172.17.0.101
            prefix: 24
      link_aggregation:
        mode: active-backup
        options:
          miimon: "1500"
        slaves:
          - ens7f0
          - ens7f1
    - name: ens1f0
      type: ethernet
      mac: "40:A6:B7:3D:B3:70"
      state: up
    - name: ens1f1
      type: ethernet
      mac: "40:A6:B7:3D:B3:71"
      state: up
    dns_server_ips:
        - 10.40.0.100
  routes:
    - destination: 0.0.0.0/0
      address: 172.17.0.1
      interface: bond0
```

### Dual Stack:
``` yaml
network_config:
    interfaces:
    - name: "enp1s0"
      mac: "{{ mac }}"
      addresses:
      ipv4:
        - ip: "{{ ansible_host }}"
          prefix: "{{ ipv4.mask }}"
      ipv6:
        - ip: "{{ ipv6_address }}"
          prefix: "{{ ipv6.mask }}"
    dns_server_ips:
      - "{{ ipv6.dns }}"
      - "{{ ipv4.dns }}"
    routes:
      - destination: "0:0:0:0:0:0:0:0/0"
        address: "{{ ipv6.gateway }}"
        interface: "enp1s0"
      - destination: 0.0.0.0/0
        address: "{{ ipv4.gateway }}"
        interface: "enp1s0"
```

## Advanced

### Raw nmstate

 If you wish to write the `nmstate` by hand you can use the `network_config.raw` entry, however you will also need to add `mac_interface_map`, the following is static ipv4 address

```yaml
mac_interface_map:
  - logical_nic_name: "enp1s0"
    mac_address: "{{ mac }}"
network_config:
  raw:
    dns-resolver:
      config:
        server:
        - "{{ dns }}"
    interfaces:
      - name: enp1s0
        state: up
        type: ethernet
        ipv4:
          address:
            - ip: "{{ ansible_host }}"
              prefix-length: "{{ mask }}"
          dhcp: false
          enabled: true
    routes:
      config:
        - destination: 0.0.0.0/0
          next-hop-address: "{{ gateway }}"
          next-hop-interface: enp1s0
          table-id: 254
```


### Custom template
If you wish to use your own template you can set `network_config.template` with a path to your desired template the default can be found [here](../roles/generate_discovery_iso/templates/nmstate.yml.j2).
