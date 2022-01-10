# `v1.2.1`

## Relevant additions

- Support for "ENP" projects (see repo docs)
- Support for a second docker login via "ALT" docker vars (see repo docs)
- Support for docker images scans by using snyk container test and monitor (see snyk-container on the code)

# `v1.2.0`

## Relevant additions

- Support for epic branches
- Overwrite protection of docker images on the target registry, for image tags of type release \[*1\]
- Overwrite protection of git version tags of type release \[*1\]
- Version tags now include branch info in semver metadata (encoded, see `_ppl_encode-branch-for-tagging`)
- Activated SNYK scans for NPM projects
- Support for docker-compose execution before the maven tests

_*1: semver with no labels, except for the special 4-digits fix-release format (X.Y.Z-fix.W)_


## Breaking changes

- Renamed `tag-snaphot-*` codes to `tag-git-*` as they also tag releases now
- Renamed `ppl--release` to `ppl--publication`
- Potential: Version tagging format slightly changed (but not the artifact and image names)
- `ppl--docker` doesn't accept anymore the build instructions as parameter, use `ENTANDO_OPT_DOCKER_BUILDS`

## Notes

This version contains significant improvements in the code that interprets the available
context information in order to derive the general state of the event's commit. For example
the tagging events, that in github comes with very little context, are now better contextualized.

---

# `v1.1.2`

## Relevant additions

- Improved support for release branches

---

# `v1.1.1`

## Relevant additions

- Allows connecting to OKD/OCP (openshift) environments via "oc" cli
- Support for post-deployment test in helm based k8s preview environments

## Breaking changes

- Renamed all mvn matrix to `MTX-MVN-SCAN-*`
- Renamed all npm matrix tasks to `MTX-NPM-SCAN-*`
- Renamed snyk scan to to `MTX-SNYK-SCAN`
- Snapshot tagging integrated into the FULL-BUILD (it was explicitly called from the provider workflow scripts)

---
