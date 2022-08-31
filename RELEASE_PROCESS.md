# Terraform Module Release Process

## Steps

1. Update versions in ./scripts/module_version.sh file for the old version and new version you want to release.

For example to release version `v0.2.0`, the file might look like:

```
#!/bin/bash

old="0\.1\.0"
new=0.2.0

...
```

2. Run `make generate_templates` from root level of repository. This should
   update all examples and templates with the newest version.


3. Submit a PR and get it reviewed and merged.

4. Tag and push the new version to Github.

```bash
git tag v0.2.0 && git push --tags
```

After step 4, the new module version should be synced on the Terraform Registry within a few minutes.
