# entando-pipelines

A GitFlow-like workflow implementation for GitHub, with some spice

# Brief

The Entando Pipelines are a set of (testable) bash scripts that implement a gitflow-like workflow based on these rules:

 - releases are bumped and tagged on release branches
 - the new versions of the mainline release are developed on the "develop" branch, via feature branches
 - the new versions of the old releases are developed directly on the release branches, via "hotfix" branches
 
and these main features:

 - Mainline version management
 - Optional support for the BOM (bill of materials) pattern
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

A macro is a high level function that implementes a full pipeline job or step.

```
~/ppl-run {macro-name} {args}
```

..which has 3 standardized options:

 - `--id {id}` the identifier of the macro execution, for messages and skip labels
 - `--lcd {dir}` the local directly where the project repository was cloned
 - `--token {token}` a token to use insted of the one provided by the context

..plus one more that is only implemented by some macro:
 
 - `--out {file}` file pathname where the full output of the command is written
 
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

# Options defined via environment variables:

| name | description | values |
| - | - | - |
| `ENTANDO_OPT_LOG_LEVEL`  | The log trace level |`TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR` |
| `ENTANDO_OPT_PR_TITLE_FORMAT` | the PR title format to enforce | **[M]** `SINGLE`,`HIERARCHICAL`,`ANY` |
| `ENTANDO_OPT_REPO_BOM_URL`  | the URL of the entando core bom | |
| `ENTANDO_OPT_SUDO` | sudo command to use | |
| `ENTANDO_OPT_NO_COL` | toggles the color ascii codes | `true`,`false` |
| `ENTANDO_OPT_STEP_DEBUG` | toggle the step debug in macros | `true`,`false` |
| `ENTANDO_OPT_MAINLINE` | **`[1]`** defines the current mainline version | `major.minor` |
| `ENTANDO_OPT_FEATURES` | the least of features enabled | (see below) |

Notes:

 - **`[M]`**: _Multiple values can be combined with the symbol_ `","`
 - **`[1]`**: _The "mainline version" is constraint that prevents the merge of any PR that comes with a different **major** or **minor** version._

# Defaults

Defaults are usually provided as environment variables.  
If they are not, the code assumes these ones:  

| name | default value |
| - | - |
| `ENTANDO_OPT_PR_TITLE_FORMAT` | `SINGLE,HIERARCHICAL` |
| `ENTANDO_OPT_REPO_BOM_URL`  | _the URL of the BOM repository_ |
| `ENTANDO_OPT_NO_COL` | `false` |
| `ENTANDO_OPT_SUDO` | `sudo` |
| `ENTANDO_OPT_STEP_DEBUG` | `false` |
| `ENTANDO_OPT_FEATURES` | `*` |


# FEATURES FLAGS

The environment variable

```
ENTANDO_OPT_FEATURES
```

is a list used to enable and disable the pipelines features

## Rules:

1. if a feature name is matched, the feature is enabled
2. if a feature name preceded by `-` is matched, the feature is disabled
3. the char `*` matches any feature name
4. the last matches of the list win over the previous
5. The feature names can be separed by `,`, `|` and the unix line-feed

# Values 

## Implicit

All the instances of macro executions are features whose name is the macro id.  
When the macro is a gate-check (see ppl--gate-check), then the entire workflow is affected.

## Explicit

|name|description|
|-|-|
| `ADD-REVIEW-ON-SECURITY-ERROR` | in case of security error a review of type "change request" is added to the PR |
