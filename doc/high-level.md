
---

### `_ppl_query_latest_bom_version()`

**Extracts the latest bom version given the bom repository URL**

<details>

```
 Params:
 $1: dest var
 $2: bom repo URL
```

</details>


---

### `_ppl_load_settings()`

**Sets one ore more evironment variables given a semicolon-delimited list of assignments**

<details>

```
 WARNING: the parser interprets the backslash
 WARNING: the parser doesn't support quotes like a CSV, however you can still escape the colon with the backslash ("\;")

 Options:
 --var-sep value    the var separator to assume
 --section          select a specific section of the settings
 --stdin            reads the environment the stdin

 Line level options:

 [p]VAR=VALUE   <= VAR is set only if currently empty

 Paramers:
 $1                unless "--stdin" is provider it's the environment to be loaded

 eg:
 - LEGAL:   _ppl_load_settings 'A=1;B=hey there;C=true'
 - ILLEGAL: _ppl_load_settings 'A=1;B="hey;there";C=true'
 - LEGAL:   _ppl_load_settings 'A=1;B=hey\;there;C=true'

 Multisection example:
 [SECT01]
 A=1
 [SECT02]
 A=2
```

</details>


---

### `_ppl_run_post-deployment-test_setup_script()`

**Runs a the preview environment provisioning script**

<details>

```
 Params:
 $1 the test namespace to use
 $2 the project name
 $3 the project version
```

</details>


---

### `_ppl_provision_helm_preview_environment()`

**Creates a preview environment by using helm charts present in the dir**

<details>

```
 Params:
 $1: project name
 $2: project version
 $3: test namespace
 $4: hostname suffix
```

</details>


---

### `_ppl_set_provisioning_placeholders_in_files()`

**Sets a set of well-known provisioning parameters in a given file**

<details>

```
 Params:
 $1: list of files to set, separed by semicolon
 $2: Project name
 $3: Project version
 $4: Namespace to use for testing
 $5: Hostname suffix
```

</details>


---

### `_ppl_autoset_snapshot_version()`

**Sets the the project snapshot version according with the current pr information**


---

### `_ppl_print_current_branch_of_dir()`

**Reads the current branch from a give dir, or the current one if none is given**


---

### `_ppl_determine_qualifier()`

**Finds the artifact qualifier**


---

### `_ppl-job-update-status()`

**Updates the state of the current pipeline job**

<details>

```
 Params:
 $1: the STATUS ID
 $2: the new status
 $3: the state context
 $4: the state description

 Expected Env:
 - PPL_TOKEN
```

</details>


---

### `_ppl-pr-add-label()`

**Adds a label to a PR**

<details>

```
 Params:
 $1: the PR number
 $2: the label to add
```

</details>


---

### `_ppl-pr-remove-label()`

**Rempves a label frpm a PR**

<details>

```
 Params:
 $1: the PR number
 $2: the label to remove
```

</details>


---

### `_ppl-set-persistent-var()`

**Sets a persistent variable**

<details>

```
 Params:
 $1: var name
 $2: var value
```

</details>


---

### `_ppl-set-return-var()`

**Set the current macro error indicator and the current exit status with the value provided**


---

### `_ppl-pr-has-label()`

**Tells if the PR has a label given its number**


---

### `_ppl-load-context()`

**Parses the pipelines environment and loads accordingly**

<details>

```
 environment variables.

 Params:
 $1: the JSON environment provided by the "github" object
```

</details>


---

### `_ppl-pr-request-change()`

**Submits to the current PR/commit a review with a request for change**

<details>

```
 Params:
 $1  the request message

 ref:
 - https://docs.github.com/en/rest/reference/pulls#create-a-review-comment-for-a-pull-request
 - https://docs.github.com/en/rest/reference/pulls#submit-a-review-for-a-pull-request
```

</details>


---

### `_ppl-pr-submit-comment()`

**Submits to the given PR/commit a comment**

<details>

```
 Params:
 $1  the PR number
 $2  the comment text
```

</details>


---

### `_ppl-stdout-group()`

**Allows grouping togheter a set of lines in a collapsable element**

<details>

```
 Params:
 $1    action: "start" or "stop"
 [$2]  the group title title, only required if action is "start"
```

</details>


---

### `_ppl-print-file-paginated()`

**Prints a file content into a set of groups**

<details>

```
 Params:
 $1    file pathname
 $2    group max size
 $3    file description
```

</details>


---

### `_ppl_create_pr()`

**Create or starts the creation of the PR**

<details>

```
 Params:
 $1: PR title
 $2: base branch
 $3: PR branch
 [$4]  optional comma-delimited reviewers
```

</details>


---

### `_ppl_determine_branch_info()`

**Determine PPL_CURRENT_REPO_BRANCH, PPL_BRANCHING_TYPE and PPL_IN_PR_BRANCH**


---

### `_ppl-pr-remove-label()`

**Rempves a label frpm a PR**

<details>

```
 Params:
 $1: the PR number
 $2: the label to remove
```

</details>


---

### `_ppl_extract_artifact_qualifier_from_pr_title()`

**Gets from a PR title the part of the prefix that should qualify the artifacts**

<details>

```
 Params:
 $1 destination var
 $2 the PR title
```

</details>


---

### `_ppl_determine_release_branch()`

**Determines the name of the release branch for the given reference version**

<details>

```
 Params:
 $1: the receiver var of the designated release branch
 $2: the reference version

 The business rule is simple:
 - Versions X.Y.Z are released under the branch "release/X.Y.0"
```

</details>


---

### `_ppl_get_feature_action()`

**Determines the action related to a feature**

<details>

```
 Params:
 $1 output var for the result
 $2 feature name
 $3 fallback value

 Rules:
 - Features are in the format of labels
 - Features are also read from the ENTANDO_OPT_FEATURES, expect for SKIP directives
 - Features are also read from the ENTANDO_OPT_GLOBAL_FEATURES, expect for SKIP directives
 - Features will be converted into CI vars usable in CI conditions
 - SKIP directive are like DISABLE directives but they are removed once evaluated

 Directives Formats:
 - Enable a feature: +{FEATURE}
 - Disable a feature: -{FEATURE}
 - Disable a feature once: SKIP-{FEATURE}

 Directives Priority crieria:
 1. LABEL then ENTANDO_OPT_FEATURES then ENTANDO_OPT_GLOBAL_FEATURES
 2. LAST directive of a given feature overwrites the previous directives of the same feature
 3. Above crieria #1 wins over crieria #2

 Returns a result of this structure:
 - {main-result}.{detail}

 where {main-result} can be:
 - D => disabled
 - E => enabled
 - I => illegal

 and {detail} can be:
 - var => result source is ENTANDO_OPT_FEATURES or ENTANDO_OPT_GLOBAL_FEATURES
 - label => result source is a label
 - any other arbitrary text => non-functional text providing details
```

</details>


---

### `_ppl_is_feature_enabled()`

**Returns the status of a feature**

<details>

```
 Params:
 $1 feature name
 $2 fallback value

 [$? == 0] => directive is present
 [$? != 0] => directive is not present
```

</details>


---

### `_ppl_is_feature_action()`

**Checks the action status of a feature**

<details>

```
 Params:
 $1 feature name
 $2 action status
    S: skipped
    E: enabled
    D: disabled
    I: illegal feature specification

 [$? == 0] => directive is present
 [$? != 0] => directive is not present
```

</details>


---

### `_ppl_extract_version_part()`

**Extracts a part of the snapshot version number**

<details>

```
 Params:

 $1  output var
 $2  snapshot version number
 $3  part:
     - base-version        the initial 3digit version with or without prefix (eg: v7.0.0 or 7.0.0)
     - qualifier           usually a ticket number (eg: ENT-999)
     - pr-num              pull request number
     - meta:kb             current branch of event that generated the tag
     - meta:bb             bash branch branch of event that generated the tag
     - effective-number    the effective part of the version (all the version but with no metadata)
```

</details>


---

### `_ppl_extract_branch_name_from_ref()`

**Extracts from a full git ref the actual branch name even if it contains slashes**


---

### `_ppl_extract_branch_short_name()`

**Determine the current branch short name (the part after the first /)**

<details>

```
 It's usuful as discriminant for identifiers related to a long running branch.

 Params:
 $1  the result receiver var
 $2  the branch name

 Examples:
 - "develop" => ""
 - "epic/mylongrunningbranch" => "mylongrunningbranch"
 - "epic/my-long-running-branch" => "my-long-running-branch"
```

</details>


---

### `_ppl_is_release_version_number()`

**Tells if a version number is a release**


---

### `_ppl_split_version_tag()`

**Extracts from the version tag the version and the original reference branch**

<details>

```
 Params:
 $1  the version receiver
 $2  the metadata receiver
 $3  the full-version
```

</details>


---

### `_ppl_encode-branch-for-tagging()`

**Encodes a branch name for tagging**

<details>

```
 > adds the segment-tag "KB-"
 > encodes any forward slash to "+2F+"
 > encodes the escape char "+" to "++"
```

</details>


---

### `_ppl_run_custom_script()`

**Executes a custom PR script given:**

<details>

```
 $1  the task name
 $2  the location of the script
```

</details>


---

### `_ppl_clone_and_configure_data_repo()`

**Load the pipeline configuration from the pipelines data repository**


---

### `_ppl_get_current_project_version()`

**Extacts the version of a artifactId from a pom**

<details>

```
 Params:
 $1: dest var
 $3: project file pathname
```

</details>


---

### `_ppl_set_current_project_version()`

**Extacts the version of a artifactId from a pom**

<details>

```
 Params:
 $1:   the value to set
 [$2]: the optional project file pathname
```

</details>


---

### `_ppl_get_current_project_name()`

**Extacts the version of a artifactId from a pom**

<details>

```
 Params:
 $1: dest var
 [$2]: the optional project file pathname
```

</details>

