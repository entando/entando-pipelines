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
