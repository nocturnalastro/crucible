# Crucible Features

This is a comparison of the features available through crucible depending on which installer is used

| Feature                                            | Assisted installer (on-prem)  | Agent based installer  |
| -------------------------------------------------- | ----------------------------- | ---------------------- |
| Compact cluster                                    | Y                             | Y                      |
| Workers                                            | Y                             | Y                      |
| SNO                                                | Y                             | -                      |
| 2 day workers                                      | Y                             | N                      |
| Set Network type                                   | Y                             | N                      |
| Patitions                                          | Y                             | N                      |
| IPV6                                               | Y                             | N*                     |
| Dual Stack                                         | Y                             | Y^                     |
| NMState network config                             | Y                             | Y                      |
| Mirror Registry support                            | Y                             | Y                      |
| Set hostname                                       | Y                             | Y                      |
| Set role                                           | Y                             | Y                      |
| Proxy                                              | Y                             | N                      |
| Discovery iso password                             | Y                             | N                      |
| DHCP                                               | Y                             | Y**                    |
| -                                                  | -                             | -                      |

Footnotes:
^ Worked when tested but not supported, support aimed for 4.12
* Not working yet support aimed for 4.12
** A `network_config` is still required however you could provide a raw nmstate, which configures the interfaces for dhcp and the corisponding `mac_interface_map`. If you are not using the DHCP provided by crucible you would need to provide the correct IP for the bootstrap node (by default the first node in the masters group) as the `host_ip_keyword` (default: `ansible_host`).
