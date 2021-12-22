
---

### `ppl--pr-labels()`

**HELPS DEALING WITH THE PR LABELS**

<details>

```
 Params:
 $1: the action to perform (add,remove)
 $2: the label to add or delete

 Actions:
 - add {label}
 - remove {label}
```

</details>


---

### `ppl--check-pr-bom-state()`

**EXECUTES THE BOM ALIGNMENT CHECK ABOUT THE CURRENT PR**

<details>

```
 Business Rules:
 - The PR bom should be aligned with the latest published BOM
```

</details>


---

### `ppl--checkout-branch()`

**EXECUTES THE CLONE AND CHECKOUT OF THE CURRENT DEFAULT REPO AND REF**

<details>

```
 Special Options:
 --token:  Overrides the default CI token. Can be useful to be able to push from the cloned repo.
```

</details>


---

### `ppl--status-report()`

**PRINTS A GENERIC STATUS REPORT ABOUT CURRENT RUN**


---

### `ppl--npm()`

**MACRO OPERATIONS RELATED TO NPM**

<details>

```
 Params:
 $1: action to apply

 Actions:
 - FULL-BUILD           Executes a full and clean npm build in full respect of the lock file (which in fact is required)
                        Options for FULL-BUILD:
                          -public-url                    the path on which app-builder is exposed (default: /app-builder)
                          --domain                        the path of the main application (default: /entando-de-app)
                          --admin-console-integration     flag for the admin console integration enabling (default: false)
 - PUBLISH              Prepares the repo for publication by setting on it the proper version name
 - MTX-NPM-SCAN-{type}  Runs a type of npm scan (LINT, SASS-LINT, COVERAGE)
```

</details>


---

### `ppl--bom()`

**MACRO OPERATIONS RELATED TO THE BOM**

<details>

```
 Params:
 $1: action to apply

 Actions:
 - update-bom    if the projects belong to a bom automatically updates the bom when a new project version is generated

 Requires:
 - maven projects
 - ENTANDO_OPT_REPO_BOM_URL
 - ENTANDO_OPT_REPO_BOM_MAIN_BRANCH
```

</details>


---

### `ppl--scan()`

**MACRO OPERATIONS RELATED TO CODE AND DEPENDECIES SCANS**

<details>

```
 Params:
 $1: action to apply

 Actions:
 - snyk:   runs a snyk based scan of the current project
```

</details>


---

### `ppl--release()`

**STARTS THE CREATION OF A VERSION**

<details>

```
 Params:
 $1: the release action to apply

 Actions:
 - tag-snapshot-version:         applies the snapshot tag to the current commit
 - tag-pseudo-snapshot-version:  applies a tag similar to the snapshot tag but that doesn't triggers workflows
 - tag-release-version           applies the final release tag to the current commit
```

</details>


---

### `ppl--release._determine_snapshot_version_name()`

**Determine the current snapshot version names**

<details>

```
 Supported Conditions:
 - On a PR creation/update commit
 - On a PR merge commit
```

</details>


---

### `ppl--pr-preflight-checks()`

**EXECUTES PRELIMINAR CHECKS ABOUT THE CURRENT PR**

<details>

```
 > Checks the format of the PR title:
 > Checks the format of the project version name on PR
 > Checks that the development PR is compatible with the current mainline version (optional via ENTANDO_OPT_MAINLINE)
 > Runs optional custom check (user provided script "custom-pr-check.sh")
```

</details>


---

### `ppl--mvn()`

**MACRO OPERATIONS RELATED TO MAVEN**

<details>

```
 Params:
 $1: action to apply

 Actions:
 - FULL-BUILD        executes a full and clean npm build+test
 - PUBLISH           publishes the maven artifact for development
                     in the process, sets on it the proper version name and rebuilds the artifact
 - GA-PUBLICATION    publishes the maven artifact for general availability
                     doesn't alter the sources like PUBLISH
 - MTX-MVN-SCAN-SONAR          Executes a full sonar scan, including the coverage report
 - MTX-MVN-SCAN-OWASP          Executes a full owasp scan
 - MTX-MVN-POST-DEPLOYMENT-TESTS  Executes the tests designed to run on a preview environment
```

</details>


---

### `ppl--docker()`

**MACRO OPERATIONS RELATED TO DOCKER**

<details>

```
 Params:
 $1: action to apply

 Actions
 - publish:  Builds one or more artifacts, image and pushes it to the image regitry.
             Params:
              - $2: the list of builds directives
             Mandatory Vars:
              - ENTANDO_OPT_DOCKER_ORG
              - ENTANDO_OPT_DOCKER_USERNAME
              - ENTANDO_OPT_DOCKER_PASSWORD
```

</details>


---

### `ppl--setup-feature-flags()`

**SETUP IN THE CI A SET OF FEATURE-FLAGS ACCORDING WITH USER DIRECTIVES**

<details>

```
 The funtion takes the features to check as parametes and the directives from the environment

 Params:
 $*: a list of features to check

 @see _ppl_get_feature_action for details
```

</details>


---

### `ppl--setup-features-list()`

**SETUP IN THE CI A LIST OF ENABLED FEATURES ACCORDING WITH USER PROVIDED FEATURES DIRECTIVES**

<details>

```
 @see _ppl_get_feature_action for details

 Options
 -p prefix mode

 Normal Params:
 $1: a list of features to check

 Prefix mode params:
 $1: prefix used to filter ENTANDO_OPT_GLOBAL_FEATURES and ENTANDO_OPT_FEATURES
```

</details>


---

### `ppl--generic()`

**PROXY FUNCTION FOR MULTI-BUILD-SYSTEM MACRO OPERATIONS**

<details>

```
 Params:
 $1: action to apply

 Actions:
  - FULL-BUILD   see equivalent on ppl--mvn|ppl--npm
  - PUBLISH      see equivalent on ppl--mvn|ppl--npm
  - MTX-MVN-SCAN-*   see equivalent on ppl--npm
  - MTX-NPM-SCAN-*   see equivalent on ppl--npm
  - MTX-SCAN-SNYK    runs a snyk scan (see ppl--scan)
```

</details>

