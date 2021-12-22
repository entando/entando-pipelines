# MAIN ENVIRONMENT VARIABLES

| name | description | values |
| - | - | - |
| `ENTANDO_OPT_LOG_LEVEL`  | The minimal log printing level | `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR` |
| `ENTANDO_OPT_PR_TITLE_FORMAT` | the PR title format to enforce | **[M]** `SINGLE`,`HIERARCHICAL`,`ANY` |
| `ENTANDO_OPT_REPO_BOM_URL`  | the URL of the entando core bom | |
| `ENTANDO_OPT_SUDO` | sudo command to use | |
| `ENTANDO_OPT_NO_COL` | toggles the color ascii codes | `true`,`false` |
| `ENTANDO_OPT_STEP_DEBUG` | toggle the step debug in macros | `true`,`false` |
| `ENTANDO_OPT_MAINLINE` | defines the current mainline version **[1]** | `major.minor` |
| `ENTANDO_OPT_CUSTOM_ENV` | a list of semicolon-delimited variables assignments **[2]** | `A=1;B=2` |
| `GIT_USER_NAME` | the username to use to perform git commits |
| `GIT_USER_EMAIL` | the user emale to use to perform git commits |

Notes:

 - **`[M]`**: _Multiple values can be combined with the symbol_ `","`
 - **`[1]`**: _The "mainline version" is a constraint that prevents the merge of any PR that comes with a different **major** or **minor** version._

# AVOID REDACTION OF SIMPLE VALUES

In order to avoid the redaction of simple configuration values like for instance "`TRACE`", prepend the value with the 3 chars prefix "`###`", like this: "`###TRACE`". In fact, if found at the start of a value this sequence is stripped on evaluation for all `ENTANDO_OPT_XXX` vars. Note that this is only valid for the entando-pipelines and that anyway the original value `###TRACE` would still be redacted.

# CUSTOM ENVIRONMENT

It's possible to define custom environment variables to export into the environment of the pipelines by defining the:

- Environment Variable `ENTANDO_OPT_CUSTOM_ENV`

This variable is a semicolon-delimited list of assignments

Check the help of `_ppl_setup_custom_environment` for details

# FEATURES FLAGS

## Main feature-flags:

### Generic

- `INHERIT-GLOBAL-FEATURES` => if disabled suppresses `ENTANDO_OPT_GLOBAL_FEATURES`
- `TAG-SNAPSHOT-AFTER-BUILD` => if disabled the current commit will not be snapshot-tagged after the build, however a pseudo snapshot tag will still be used to preserve relevant build information (`pXXX` instead of `vXXX`)

### Maven Full build

- `MVN-QUARKUS-NATIVE` => after the full-build a quarkus native package is created
- `MVN-VERIFY` => the full-build only executes a simple mvn verify
- `MVN-INSTALL` => the full-build only executes a simple mvn install

See also [About Feature Flags](about-feature-flags.md)

# SCANNERS CONFIGURATIONS

## Snyk

- `MTX-SCAN-SNYK` => feature flag that enables the skyk scan
- `SNYK_ORG` => the identifier of the organization recognised by the snyk cloud service
- `SNYK_TOKEN` => the token to use to run the snyk scan on the snyk cloud service

## Maven specific 

### Sonar

- `MTX-MVN-SCAN-SONAR` => feature flag that enables the sonar scan
- `SONAR_TOKEN` => the token to use to run the sonarcloud scans

### Owasp

- `MTX-MVN-SCAN-OWASP` => feature flag that enables the sonar scan
- All the other configurations are contained on the pom files

_note that the owasp scan is not based on a cloud service (although it downloads the vulnerability database upadates from Internet)_

## NPM Specific

- `MTX-NPM-SCAN-LINT`       enables the execution of npm lint
- `MTX-NPM-SCAN-SASS-LINT`  enables the execution of npm sass-lint
- `MTX-NPM-SCAN-COVERAGE`   enables the execution of npm coverage


# SPECIAL:

- [OKD config](about-okd-config.md) => configuration to connect to a OKD environment for the tests
- [DOCKER config](about-docker-config.md) => configurations to connect to a docker registry for the publication
- [POST-DEPLOYMENT config](about-post-deployment-tests.md) => configurations related to the post-deployment tests
