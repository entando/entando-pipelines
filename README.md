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
 - Support for 3 publication levels: Snapshot, Release and GA
 - Can create and publish gpg-signed artifacts and docker images
 - Pull Requests formats validity controls (title, version etc..)
 - FeatureFlags and skip-labels to control pipeline features

 
# How to use it

## Install

```
bash <(curl -qsL "https://raw.githubusercontent.com/entando/entando-pipelines/{tag}/macro/install.sh")
```
**NOTE:** Remember to replace the {tag} placeholder

## Run a macro

A macro is a high level function that implements a full pipeline job or step.

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

_Note:_

- _the symbol "@" before a macro name prevents the macro from interrupting the execution in case of errors_

# Options defined via environment variables:

| name | description | values |
| - | - | - |
| `ENTANDO_OPT_LOG_LEVEL`  | The minimal log printing level | `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR` |
| `ENTANDO_OPT_PR_TITLE_FORMAT` | the PR title format to enforce | **[M]** `SINGLE`,`HIERARCHICAL`,`ANY` |
| `ENTANDO_OPT_REPO_BOM_URL`  | the URL of the entando core bom | |
| `ENTANDO_OPT_SUDO` | sudo command to use | |
| `ENTANDO_OPT_NO_COL` | toggles the color ascii codes | `true`,`false` |
| `ENTANDO_OPT_STEP_DEBUG` | toggle the step debug in macros | `true`,`false` |
| `ENTANDO_OPT_MAINLINE` | **`[1]`** defines the current mainline version | `major.minor` |
| `ENTANDO_OPT_FEATURES` | the list of features enabled | (see below) |

Notes:

 - **`[M]`**: _Multiple values can be combined with the symbol_ `","`
 - **`[1]`**: _The "mainline version" is a constraint that prevents the merge of any PR that comes with a different **major** or **minor** version._
 - _The sequence `###`, if found at the start of a value, is skipped and only the rest is considered. This is a trick that should be used to evade the CI/CD obfuscation for perfectly safe values (for instance "TRACE", should be written as "###TRACE")_

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

# FEATURES FLAGS

## Sources

| name | description |
| - | - |
| `ENTANDO_OPT_FEATURES`        | environment var usually defined on the repo's secrets |
| `ENTANDO_OPT_GLOBAL_FEATURES` | environment var usually defined on the organization's secrets |
| `LABELS`                      | labels defined on the PR |

## Syntax

### Directives

 - Enable a feature: `+{FEATURE}`
 - Disable a feature: `-{FEATURE}`
 - Disable a feature once: `SKIP-{FEATURE}`
 
### General

 - Environment variables contains lists of directives separed by "," or "/" or "|" or a line-feed 
 - Note that SKIP directives are only allowed in labels, which in fact are automatically removed from the PR, after evaluation.

## Priorities rules

 1. `LABEL` wins over `ENTANDO_OPT_FEATURES` which wins over `ENTANDO_OPT_GLOBAL_FEATURES`
 2. the last directive of a given feature overrides the previous directives of the same feature
 3. Above rule #1 wins over rule #2

# FURTHER INFO

Check the subdir docs for testing and methods reference documentation.
