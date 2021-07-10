# entando-pipelines

A GitFlow-like workflow implementation for GitHub, with some spice

# Brief

The Entando Pipelines are a set of (testable) bash scripts that implement a gitflow-like workflow based on these rules:

 - releases are bumped and tagged on release branches
 - the new versions of the mainline release are developed on the "develop" branch, via feature branches
 - the new versions of the old releases are developed directly on the release branches, via "hotfix" branches
 
and these main features:

 - Mainline version management
 - Optional support for a the BOM (bill of materials) pattern
 - Support for 3 repositories level: Snapshot, Release and GA 
 - In-pr preview artifacts
 - Docker images creation and publication
 - Pull Requests formats validity controls (title, version etc..)
 - Support for skip-labels

 
# How to use it

## Install

```
bash <(curl -qsL "https://raw.githubusercontent.com/entando/entando-pipelines/{tag}/macro/install.sh")
```

## Run a macro

A macro is an high level function that implementes a full pipeline job or step.

```
~/ppl-run {macro-name} {args}
```

..which has 3 standardized options:

 - `--id`    the identifier of the macro execution, for messages and skip labels
 - `--lcd`   the local directly the remote project repository is or was cloned
 - `--token` a token to use insted of the one provided by the context
 
## Run a sequence of macros

```
~/ppl-run {macro-name} {args} .. {macro-name} {args} [etc..]
```

# Execution Environment:

Part of the Execution Environment is generated automatically after the context provided by the underlying pipeline engine. All the related vars follow the form:

 - `EE_...`
 
for example:
  
 - `EE_PR_TITLE`
 - `EE_PR_NUM`

# Options defined via enviroment variables:

| name | description | values |
| - | - | - |
| `ENTANDO_OPT_LOG_LEVEL`  | The log trace level |`TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR` |
| `ENTANDO_OPT_PR_TITLE_FORMAT` | the PR title format to enforce | **[M]** `SINGLE`,`HIERARCHICAL`,`ANY` |
| `ENTANDO_OPT_REPO_BOM_URL`  | the URL of the entando core bom | |
| `ENTANDO_OPT_SUDO` | sudo command to use | |
| `ENTANDO_OPT_NO_COL` | toggles the color ascii codes | `true`,`false` |
| `ENTANDO_OPT_STEP_DEBUG` | toggle the step debug in macros | `true`,`false` |
| `ENTANDO_OPT_MAINLINE` | **`[1]`** defines the current mainline version | `major.minor` |

Notes:

 - **`[M]`**: _Multiple values can be combined with the symbol_ `"|"`
 - **`[1]`**: _The "mainline version" is constraint that prevents the merge of any PR that comes with a different **major** or **minor** version._

# Defaults

Defaults are usually provided as environment variables.  
If they are not, the code assumes these ones:  

| name | default value |
| - | - |
| `ENTANDO_OPT_PR_TITLE_FORMAT` | `SINGLE\|HIERARCHICAL` |
| `ENTANDO_OPT_REPO_BOM_URL`  | _the URL of the BOM repository_ |
| `ENTANDO_OPT_NO_COL` | `false` |
| `ENTANDO_OPT_SUDO` | `sudo` |
| `ENTANDO_OPT_STEP_DEBUG` | `false` |
