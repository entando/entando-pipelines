# SECURITY SCANS

Pipelines currently uses snyk for security scans, in two phases:

- Dependencies scan
- Docker Images scans  (aka: container scans)


## FEATURE FLAG

```
MTX-SCAN-SNYK => feature flag that enables the SNYK dependencies scan
```


## Configuration Options:

```
ENTANDO_OPT_SNYK_ORG => the project organization under the snyk cloud service
ENTANDO_OPT_SNYK_PRJ => the project name under the snyk cloud service
ENTANDO_OPT_SNYK_SCAN_BASE_IMAGES => if true activates the scan of the base images in container scans
```


## Suppression files management [v1.4]:

From version **`1.4`** pipelines allows using a global snyk suppression file, while in the past was alway specified in the repository being built. This feature is controlled by this variable:

```
ENTANDO_OPT_SNYK_SCAN_SUPPRESSION_MODE:
 - only-local  => only considers the local file of the repository being built
 - only-global [DEFAULT] => only considers the global snyk file
 - local-fallback-to-global => if present local file otherwise global file
 - gobal-fallback-to-local => if present local file otherwise global file
```

### About the "global" snyk suppression file:

For global file is meant the snyk suppression file stored in the pipelines data-repository. The file is downloaded every time a build is run (given a reference git tag of the data-repository). This means that when the file is updated (alongside the tag) the change is reflected realtime on the subsequent builds.
