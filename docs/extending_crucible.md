# Extending crucible 

We (the crucible team) suggest that where possible you conribute directly to crucible as this will grant you the most stablity. 
We will not priorites problems caused by custom roles.
However, there will be cases where we do not have the resources to maintain a certian senario at which point a custom extention maybe required.

The prefered method for extending crucible is for people to override the modules using the roles search path.
By inserting a custom roles directory into the `roles_path` in the `ansible.cfg` it is possible to make crucible execute custom roles. 
This is a powerful method but requires that your module performs the intent of the origional role. 
For instance a custom role for `boot_iso` must cause the target host to boot into the discovery iso such that it registers with a waiting `infra-env` inside of assisted installer.

## Excuting crucible roles from custom roles

To allow to call into crucible's roles you can simply create a symlink to the origional role with a different name. 
For instance if you create a custom `boot_iso` role to add another vendor, we suggested you call into crucible `boot_iso` role for the vendors your customr role does not support.

This simple python snippet (ran in your custom roles directory) will create the symlinks for all roles:

```python
from pathlib import Path

roles_dir = Path('../crucible/roles/') # Replace with path to crucibles role dir

for role_path in roles_dir.glob('*'):
    Path(f"crucible_{role_path.name}").symlink_to(role_path)
```

## Example

### Add custom path to `roles_path` in `ansible.cfg`

In this example `../my_custom_roles` will be the relitive path from crucible to the directory containing the custom directory.

```bash
$ ls
crucible  my_custom_roles
```
Then prefixing the roles_path with `../my_custom_roles` will cause ansible to find your custom roles before the crucible roles. The resulting change should looke something like: 

```
[defaults]
...
roles_path = ../my_custom_roles:./roles
...
```

### Writing a custom role

Although not required we suggest that you create two custom roles:
- one which has the same name as the origional module to intercept the search for the crucible role (e.g. `boot_iso`)
- another which contains the custom tasks (e.g. `custom_boot_iso`)

As well as a symlink to the origional role (e.g. `crucible_boot_iso`)

This `boot_iso` should call into `custom_boot_iso` and `crucible_boot_iso` so that is is clear from the ansible logs which role is being executed.

---

Note there may be times when the replacement `boot_iso` role needs to do more than just call into the other two roles for instance controling the execution flow an selectively not calling into one of the other roles given a condition. 

---

