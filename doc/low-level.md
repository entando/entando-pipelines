
---

### `_npm_get()`

**Sets an npm package.json property**

<details>

```
 Params:
 $1 the receiver var
 $2 the project file
 $3 the property name
```

</details>


---

### `_npm_set()`

**Sets an npm package.json property**

<details>

```
 Params:
 $1 the project file
 $2 the property name
 $3 the property value
```

</details>


---

### `_semver_parse()`

**Parses a semver into its complonent digits**

<details>

```
 - "v" prefix is suppored and stripped
 - all params are optional and accept ""

 Params:
 $1  major version receiver var
 $2  minor version receiver var
 $3  patch version receiver var
 $4  tag version receiver var
 $5  semver to parse
```

</details>


---

### `_semver_ex_parse()`

**Extended version of _semver_parse that also supports 4 digit versions**


---

### `_semver_add()`

**Increments a semver**

<details>

```
 Also supports:
  - version prefix (v1.2.3)
  - version tags  (1.2.3-SNAPSHOT)

 Params:
 $1  receiver var
 $2  base semver
 $3  major increment
 $4  minor increment
 $5  patch increment
```

</details>


---

### `_semver_set_tag()`

**Updates or add a tag to a version string**

<details>

```
 Params:
 $1 the destination var
 $2 the source version
 $3 the new tag to set
```

</details>


---

### `_semver_cmp()`

**Compares 2 sem version and return**

<details>

```
 - 1 if the first is > than the second
 - 0 if they are equals
 - -1 if the first is < than the second

 Params:
 $1 destination var
 $2 the first var
 $3 the second version
```

</details>


---

### `_print_callstack()`

**Prints the current callstack**

<details>

```
 Options
 [-d] to debug tty
 [-n] doesn't print the decoration frame

 Params:
 $1  start from this element of the start
 $2  number of start
 $3  title
 $4  print command to use
```

</details>


---

### `print_current_function_name()`

**Prints the current function name with decorations**

<details>

```
 Params:
 $1  prefix decoration
 $2  suffix decoration
```

</details>


---

### `_pp()`

**Pretty debug prints of variables**

<details>

```
 Params:
 [-d]       prints to the debug tty
 [-t title] also print a title
 - all params are optional and accept ""

 Params:
 $@  a list of variable names to pretty print (so without dereference operator "$")
```

</details>


---

### `_pp_adjust_var()`

**Adjust a variable for pretty printing**

<details>

```
 Params:
 $1: the variable to cut
 $2: the max len
```

</details>


---

### `_NONNULL()`

**Validates for non-null a list of mandatory variables**

<details>

```
 Fatals if a violation is found
```

</details>


---

### `__VERIFY_EXPRESSION()`

**Verifies a condition**

<details>

```
 Expects a value to match an expected value according with an operator.
 If the verification fails an error and a callstack are printed.
 The function assumes to be wrapped so it skips 2 levels of the callstack.

 Syntax1 - Params:
 $1: The error messages prefix
 $2: Name of the variable containing the value to test
 $3: Operator
 $4: expected value

 Syntax2 - Params:
 $1: The error messages prefix
 $2: -v
 $3: A description of value
 $4: A value to test
 $5: Operator
 $6: expected value
```

</details>


---

### `__VERIFY()`

**See __VERIFY_EXPRESSION**


---

### `DBGSHELL()`

**Drops a shell that inherits the caller environment**


---

### `_url_add_token()`

**Adds a token or replaces a tocken to/in a URL**

<details>

```
 Params:
 $1  destination var
 $2  url
 $3  token
```

</details>


---

### `_extract_pr_title_prefix()`

**Gets the prefix of the PR title**

<details>

```
 Params:
 $1 destination var
 $2 the PR title
```

</details>


---

### `BASE.init_default_vars()`

**shellcheck disable=SC2034**


---

### `START_MACRO()`

**Setups the enviroment for a macro execution**

<details>

```
 Params:
 $1   macro name
 $..  macro-specific parameters

 shellcheck disable=SC2034
```

</details>


---

### `_EXIT()`

**Stops the execution with a success result and an info message**

<details>

```
 Params:
 $1  message

 Options:
 -d logs using _log_d instead of _log_i
```

</details>


---

### `_SOE()`

**STOP ON ERROR**

<details>

```
 Options:
 --pipe N  checks the result of the part #N of a pipe expression, can be specified up to 3 times
```

</details>


---

### `_set_var()`

**Sets a variable given the name and the value**

<details>

```
 WARNING:
 This function can be used to set a variable of the caller's scope and this tecnique
 is commonly used to return values to the caller.
 But note that if there is a variable with same name in the local scope, the local one
 is preferred leaving the caller's variable untouched.
 That's why functions that returns values uses a special naming convention for their
 internal variables (_tmp_...).

 Params:
 - $1: variable to set
 - $2: value
```

</details>


---

### `kube.oc.wait_for_resource()`

**Waits for a condition on given resource**

<details>

```
 $1: max wait
 $2: condition (until-present, until-not-present)
 $3: resource type
 $4: resource name
```

</details>


---

### `kube.oc-login()`

**Logins to an OKD instance given the related OKD variables**

<details>

```
 Required environment variables:
  ENTANDO_OPT_OKD_LOGIN_URL        the url of the OKD instance
  ENTANDO_OPT_OKD_LOGIN_TOKEN      the tocken to use for the login operation
  ENTANDO_OPT_OKD_LOGIN_NAMESPACE  the namespace to use

 Optional environment variables:
   ENTANDO_OPT_OKD_LOGIN_INSECURE  forces a TLS-insecure login (default: false)
   ENTANDO_OPT_OKD_CLI_URL         the URL from which the download tool should be downloaded
                                   Note that this is a semicolon-delimited list, where the first element
                                   is the url and the others are the optional curl options
```

</details>


---

### `kube.oc.namespace.reset()`

**Deletes and recreates a namespace**


---

### `kube.manifest.filter-document-by-kind()`

**Filters out from the standard-input the triple-dash (---) separed documents that matches the given kind**

<details>

```
 Params:
 $1 document kind
```

</details>


---

### `_pkg_get()`

**Installs a command given its package name**

<details>

```
 Params:
 $1: name of the package

 Options:
 -c command          command to check if != package name
 --tar-install url   installation based on the url of the executable archive
```

</details>


---

### `_pkg_apt_install()`

**Installs a package given its apt package name**


---

### `_pkg_tar_install()`

**Installs a package given a link to a tarball**

<details>

```
 $1: semicolon-delimited list containing:
     position #1     the url
     position #2..4  3 additional args for the curl command

 this limited syntax was implemented mostly to allow specifying "--insecure"
 note that all the args are individually quoted
```

</details>


---

### `require_mandatory_command()`

**Ensures that a mandatory command is avaliable**

<details>

```
 Params:
 $1:   command
 [$2]: optional description of the command
```

</details>


---

### `_pkg_is_command_available()`

**Checks for the presence of a command**

<details>

```
 Params:
 $1: the command

 Options:
 [-m] if provided failing finding the command is fatal
```

</details>


---

### `__mvn_exec()`

**Successfully runs a maven command or fatals.**

<details>

```
 Unless otherise specified it summarize the output.

 Special Options:
 --ppl-simple:     doesn't summarize the output
 --ppl-timestamp:  adds a timestamp to every output line
```

</details>


---

### `__mvn_deploy()`

**Runs a maven deploy over the received environment params**

<details>

```
 Params:
 $1: repository id
 $2: repository url
```

</details>


---

### `__git()`

**Runs an arbitrary git command and FATALS if it fails**


---

### `__git_set_repo_defaults()`

**Sets the repository defaults**


---

### `__git_init()`

**Runs a git init and sets the repository defaults**


---

### `_git_full_clone()`

**Clones a repository and the tags**

<details>

```
 Params:
 $1: repository url
 $2: optional dest dir or ""
 $3: optional branch to checkout or ""
 $4: optional token
```

</details>


---

### `_git_set_commit_config()`

**Sets the git commit config**

<details>

```
 Options:
 --global: sets the info globally

 Params:
 $1: user name
 $2: user email
```

</details>


---

### `_git_auto_setup_commit_config()`

**Sets the git commit config of the local repo**

<details>

```
 according with the information on the environment

 Expected Vars:
 GIT_USER_NAME: user name
 GIT_USER_EMAIL: user email
```

</details>


---

### `_git_ref_to_version()`

**Extract the tag(s) on the given gitref string**

<details>

```
 Params:
 $1: dest var
 $2: git-ref
```

</details>


---

### `_git_get_current_commit_id()`

**Returns the commit id of the current local repo**


---

### `_git_determine_highest_version()`

**Returns the tag with the highest value**

<details>

```
 Note that the command by default filters out the preview versions

 Options:
 --for: specifies the base version for the search (eg: 6.3 only looks for 6.3.* tags)

 Params:
 $1: the output var
```

</details>


---

### `__git_ACTP()`

**Add-Commit-Tag-Push**

<details>

```
 Params:
 $1 the commit message
 $2 the tag id  (if not provided tagging is not executed)
 $3 the remote branch (if not provided push is not executed, if "-" a push with no params is executed)
```

</details>


---

### `__git_auto_checkout()`

**Checkouts a branch**

<details>

```
 Params:
 $1: the branch to checkout
```

</details>


---

### `_git_get_current_branch()`

**Sets the receiver var with the the current git branch**


---

### `__git_force_merge_branch()`

**Merges current branch into the target one, by overriding the target.**

<details>

```
 At the end of the operation the current branch and the target branch will be identical

 Params:
 $1: the target branch
```

</details>


---

### `__git_add_tag()`

**tag generation**

<details>

```
 always generate an heavy tag

 Params:
 $1: the tag name
 $2: the optional message (autogenerated if not provided)
 $3: the optional commit id (HEAD if not provided)
```

</details>


---

### `__git_get_commit_tag()`

**Extract the given commit tag**

<details>

```
 Options:
 --snapshot-tag filters for snapshot tags
 --pseudo-snapshot-tag filters for pseudo snapshot tags

 Params:
 $1  the output var
 $2  the commit reference
```

</details>


---

### `__git_get_parent_pr()`

**Extract the parent PR of the given commit**

<details>

```
 Options:
 --tolerant  disables the "MUST-WORK" contraint of the double-underscore functions

 Params:
 $1  the output var
 $2  the commit reference
```

</details>


---

### `_git_commit_exists()`

**Tells if a given commit reference exists on the repo**


---

### `_git_is_dirty()`

**Fails if the worktre has uncommitted or untracked files**


---

### `__docker_exec()`

**Runs a docker operation and summarise the output**

<details>

```
 Params:
 $@: all params are forwarded to the docker command and params of _summarize_stream
```

</details>


---

### `__docker()`

**Runs a docker operation**

<details>

```
 Params:
 $@: all params are forwarded to the docker command
```

</details>


---

### `_docker_is_image_on_registry()`

**Tells if a image is present on the registry**

<details>

```
 registry is taken from the given address or falls back as for docker standard policies

 Params:
 $1: the image address
```

</details>


---

### `_pom_get_project_artifact_id()`

**Extacts the artifactId from a pom**

<details>

```
 Params:
 $1: dest var
 $2: pom file pathname
```

</details>


---

### `_pom_get_project_version()`

**Extacts the version of a artifactId from a pom**

<details>

```
 Params:
 $1: dest var
 $2: pom file pathname
```

</details>


---

### `_pom_set_project_version()`

**Sets the version of a artifactId from a pom**

<details>

```
 Params:
 $1: new version
 $2: pom file pathname
```

</details>


---

### `_pom_get_project_property()`

**Extacts a property from a pom**

<details>

```
 Params:
 $1: dest var
 $2: pom file pathname
 $3: property name
```

</details>


---

### `_pom_set_project_property()`

**Sets a property from a pom**

<details>

```
 Params:
 $1: new value
 $2: pom file pathname
 $3: property name
```

</details>


---

### `_pom_get_depman_artifact_version()`

**Extacts the version of an artifact dependency of the dependency management section**

<details>

```
 Params:
 $1: dest var
 $2: pom file pathname
 $3: the artifact id
```

</details>


---

### `_pom_get()`

**Gets a pom property**

<details>

```
 Params:
 $1 the receiver var
 $2 the pom file
 $3 the XML path of the property to set
 $4 the property name
```

</details>


---

### `_pom_set()`

**Sets a pom property**

<details>

```
 Params:
 $1 the value to set
 $2 the pom file
 $3 the XML path of the property to set
 $4 the property name
```

</details>


---

### `_npm_get()`

**Sets an npm package.json property**

<details>

```
 Params:
 $1 the receiver var
 $2 the project file
 $3 the property name
```

</details>


---

### `_npm_set()`

**Sets an npm package.json property**

<details>

```
 Params:
 $1 the project file
 $2 the property name
 $3 the property value
```

</details>


---

### `_semver_parse()`

**Parses a semver into its complonent digits**

<details>

```
 - "v" prefix is suppored and stripped
 - all params are optional and accept ""

 Params:
 $1  major version receiver var
 $2  minor version receiver var
 $3  patch version receiver var
 $4  tag version receiver var
 $5  semver to parse
```

</details>


---

### `_semver_ex_parse()`

**Extended version of _semver_parse that also supports 4 digit versions**


---

### `_semver_add()`

**Increments a semver**

<details>

```
 Also supports:
  - version prefix (v1.2.3)
  - version tags  (1.2.3-SNAPSHOT)

 Params:
 $1  receiver var
 $2  base semver
 $3  major increment
 $4  minor increment
 $5  patch increment
```

</details>


---

### `_semver_set_tag()`

**Updates or add a tag to a version string**

<details>

```
 Params:
 $1 the destination var
 $2 the source version
 $3 the new tag to set
```

</details>


---

### `_semver_cmp()`

**Compares 2 sem version and return**

<details>

```
 - 1 if the first is > than the second
 - 0 if they are equals
 - -1 if the first is < than the second

 Params:
 $1 destination var
 $2 the first var
 $3 the second version
```

</details>


---

### `_print_callstack()`

**Prints the current callstack**

<details>

```
 Options
 [-d] to debug tty
 [-n] doesn't print the decoration frame

 Params:
 $1  start from this element of the start
 $2  number of start
 $3  title
 $4  print command to use
```

</details>


---

### `print_current_function_name()`

**Prints the current function name with decorations**

<details>

```
 Params:
 $1  prefix decoration
 $2  suffix decoration
```

</details>


---

### `_pp()`

**Pretty debug prints of variables**

<details>

```
 Params:
 [-d]       prints to the debug tty
 [-t title] also print a title
 - all params are optional and accept ""

 Params:
 $@  a list of variable names to pretty print (so without dereference operator "$")
```

</details>


---

### `_pp_adjust_var()`

**Adjust a variable for pretty printing**

<details>

```
 Params:
 $1: the variable to cut
 $2: the max len
```

</details>


---

### `_NONNULL()`

**Validates for non-null a list of mandatory variables**

<details>

```
 Fatals if a violation is found
```

</details>


---

### `__VERIFY_EXPRESSION()`

**Verifies a condition**

<details>

```
 Expects a value to match an expected value according with an operator.
 If the verification fails an error and a callstack are printed.
 The function assumes to be wrapped so it skips 2 levels of the callstack.

 Syntax1 - Params:
 $1: The error messages prefix
 $2: Name of the variable containing the value to test
 $3: Operator
 $4: expected value

 Syntax2 - Params:
 $1: The error messages prefix
 $2: -v
 $3: A description of value
 $4: A value to test
 $5: Operator
 $6: expected value
```

</details>


---

### `__VERIFY()`

**See __VERIFY_EXPRESSION**


---

### `DBGSHELL()`

**Drops a shell that inherits the caller environment**


---

### `_url_add_token()`

**Adds a token or replaces a tocken to/in a URL**

<details>

```
 Params:
 $1  destination var
 $2  url
 $3  token
```

</details>


---

### `_extract_pr_title_prefix()`

**Gets the prefix of the PR title**

<details>

```
 Params:
 $1 destination var
 $2 the PR title
```

</details>


---

### `BASE.init_default_vars()`

**shellcheck disable=SC2034**


---

### `START_MACRO()`

**Setups the enviroment for a macro execution**

<details>

```
 Params:
 $1   macro name
 $..  macro-specific parameters

 shellcheck disable=SC2034
```

</details>


---

### `_EXIT()`

**Stops the execution with a success result and an info message**

<details>

```
 Params:
 $1  message

 Options:
 -d logs using _log_d instead of _log_i
```

</details>


---

### `_SOE()`

**STOP ON ERROR**

<details>

```
 Options:
 --pipe N  checks the result of the part #N of a pipe expression, can be specified up to 3 times
```

</details>


---

### `_set_var()`

**Sets a variable given the name and the value**

<details>

```
 WARNING:
 This function can be used to set a variable of the caller's scope and this tecnique
 is commonly used to return values to the caller.
 But note that if there is a variable with same name in the local scope, the local one
 is preferred leaving the caller's variable untouched.
 That's why functions that returns values uses a special naming convention for their
 internal variables (_tmp_...).

 Params:
 - $1: variable to set
 - $2: value
```

</details>


---

### `kube.oc.wait_for_resource()`

**Waits for a condition on given resource**

<details>

```
 $1: max wait
 $2: condition (until-present, until-not-present)
 $3: resource type
 $4: resource name
```

</details>


---

### `kube.oc-login()`

**Logins to an OKD instance given the related OKD variables**

<details>

```
 Required environment variables:
  ENTANDO_OPT_OKD_LOGIN_URL        the url of the OKD instance
  ENTANDO_OPT_OKD_LOGIN_TOKEN      the tocken to use for the login operation
  ENTANDO_OPT_OKD_LOGIN_NAMESPACE  the namespace to use

 Optional environment variables:
   ENTANDO_OPT_OKD_LOGIN_INSECURE  forces a TLS-insecure login (default: false)
   ENTANDO_OPT_OKD_CLI_URL         the URL from which the download tool should be downloaded
                                   Note that this is a semicolon-delimited list, where the first element
                                   is the url and the others are the optional curl options
```

</details>


---

### `kube.oc.namespace.reset()`

**Deletes and recreates a namespace**


---

### `kube.manifest.filter-document-by-kind()`

**Filters out from the standard-input the triple-dash (---) separed documents that matches the given kind**

<details>

```
 Params:
 $1 document kind
```

</details>


---

### `_pkg_get()`

**Installs a command given its package name**

<details>

```
 Params:
 $1: name of the package

 Options:
 -c command          command to check if != package name
 --tar-install url   installation based on the url of the executable archive
```

</details>


---

### `_pkg_apt_install()`

**Installs a package given its apt package name**


---

### `_pkg_tar_install()`

**Installs a package given a link to a tarball**

<details>

```
 $1: semicolon-delimited list containing:
     position #1     the url
     position #2..4  3 additional args for the curl command

 this limited syntax was implemented mostly to allow specifying "--insecure"
 note that all the args are individually quoted
```

</details>


---

### `require_mandatory_command()`

**Ensures that a mandatory command is avaliable**

<details>

```
 Params:
 $1:   command
 [$2]: optional description of the command
```

</details>


---

### `_pkg_is_command_available()`

**Checks for the presence of a command**

<details>

```
 Params:
 $1: the command

 Options:
 [-m] if provided failing finding the command is fatal
```

</details>


---

### `__mvn_exec()`

**Successfully runs a maven command or fatals.**

<details>

```
 Unless otherise specified it summarize the output.

 Special Options:
 --ppl-simple:     doesn't summarize the output
 --ppl-timestamp:  adds a timestamp to every output line
```

</details>


---

### `__mvn_deploy()`

**Runs a maven deploy over the received environment params**

<details>

```
 Params:
 $1: repository id
 $2: repository url
```

</details>


---

### `__git()`

**Runs an arbitrary git command and FATALS if it fails**


---

### `__git_set_repo_defaults()`

**Sets the repository defaults**


---

### `__git_init()`

**Runs a git init and sets the repository defaults**


---

### `_git_full_clone()`

**Clones a repository and the tags**

<details>

```
 Params:
 $1: repository url
 $2: optional dest dir or ""
 $3: optional branch to checkout or ""
 $4: optional token
```

</details>


---

### `_git_set_commit_config()`

**Sets the git commit config**

<details>

```
 Options:
 --global: sets the info globally

 Params:
 $1: user name
 $2: user email
```

</details>


---

### `_git_auto_setup_commit_config()`

**Sets the git commit config of the local repo**

<details>

```
 according with the information on the environment

 Expected Vars:
 GIT_USER_NAME: user name
 GIT_USER_EMAIL: user email
```

</details>


---

### `_git_ref_to_version()`

**Extract the tag(s) on the given gitref string**

<details>

```
 Params:
 $1: dest var
 $2: git-ref
```

</details>


---

### `_git_get_current_commit_id()`

**Returns the commit id of the current local repo**


---

### `_git_determine_highest_version()`

**Returns the tag with the highest value**

<details>

```
 Note that the command by default filters out the preview versions

 Options:
 --for: specifies the base version for the search (eg: 6.3 only looks for 6.3.* tags)

 Params:
 $1: the output var
```

</details>


---

### `__git_ACTP()`

**Add-Commit-Tag-Push**

<details>

```
 Params:
 $1 the commit message
 $2 the tag id  (if not provided tagging is not executed)
 $3 the remote branch (if not provided push is not executed, if "-" a push with no params is executed)
```

</details>


---

### `__git_auto_checkout()`

**Checkouts a branch**

<details>

```
 Params:
 $1: the branch to checkout
```

</details>


---

### `_git_get_current_branch()`

**Sets the receiver var with the the current git branch**


---

### `__git_force_merge_branch()`

**Merges current branch into the target one, by overriding the target.**

<details>

```
 At the end of the operation the current branch and the target branch will be identical

 Params:
 $1: the target branch
```

</details>


---

### `__git_add_tag()`

**tag generation**

<details>

```
 always generate an heavy tag

 Params:
 $1: the tag name
 $2: the optional message (autogenerated if not provided)
 $3: the optional commit id (HEAD if not provided)
```

</details>


---

### `__git_get_commit_tag()`

**Extract the given commit tag**

<details>

```
 Options:
 --snapshot-tag filters for snapshot tags
 --pseudo-snapshot-tag filters for pseudo snapshot tags

 Params:
 $1  the output var
 $2  the commit reference
```

</details>


---

### `__git_get_parent_pr()`

**Extract the parent PR of the given commit**

<details>

```
 Options:
 --tolerant  disables the "MUST-WORK" contraint of the double-underscore functions

 Params:
 $1  the output var
 $2  the commit reference
```

</details>


---

### `_git_commit_exists()`

**Tells if a given commit reference exists on the repo**


---

### `_git_is_dirty()`

**Fails if the worktre has uncommitted or untracked files**


---

### `__docker_exec()`

**Runs a docker operation and summarise the output**

<details>

```
 Params:
 $@: all params are forwarded to the docker command and params of _summarize_stream
```

</details>


---

### `__docker()`

**Runs a docker operation**

<details>

```
 Params:
 $@: all params are forwarded to the docker command
```

</details>


---

### `_docker_is_image_on_registry()`

**Tells if a image is present on the registry**

<details>

```
 registry is taken from the given address or falls back as for docker standard policies

 Params:
 $1: the image address
```

</details>


---

### `_pom_get_project_artifact_id()`

**Extacts the artifactId from a pom**

<details>

```
 Params:
 $1: dest var
 $2: pom file pathname
```

</details>


---

### `_pom_get_project_version()`

**Extacts the version of a artifactId from a pom**

<details>

```
 Params:
 $1: dest var
 $2: pom file pathname
```

</details>


---

### `_pom_set_project_version()`

**Sets the version of a artifactId from a pom**

<details>

```
 Params:
 $1: new version
 $2: pom file pathname
```

</details>


---

### `_pom_get_project_property()`

**Extacts a property from a pom**

<details>

```
 Params:
 $1: dest var
 $2: pom file pathname
 $3: property name
```

</details>


---

### `_pom_set_project_property()`

**Sets a property from a pom**

<details>

```
 Params:
 $1: new value
 $2: pom file pathname
 $3: property name
```

</details>


---

### `_pom_get_depman_artifact_version()`

**Extacts the version of an artifact dependency of the dependency management section**

<details>

```
 Params:
 $1: dest var
 $2: pom file pathname
 $3: the artifact id
```

</details>


---

### `_pom_get()`

**Gets a pom property**

<details>

```
 Params:
 $1 the receiver var
 $2 the pom file
 $3 the XML path of the property to set
 $4 the property name
```

</details>


---

### `_pom_set()`

**Sets a pom property**

<details>

```
 Params:
 $1 the value to set
 $2 the pom file
 $3 the XML path of the property to set
 $4 the property name
```

</details>


---

### `_git_full_clone()`

**Clones a repository and the tags**

<details>

```
 Params:
 $1: repository url
 $2: optional dest dir or ""
 $3: optional branch to checkout or ""
 $4: optional token
```

</details>


---

### `_git_set_commit_config()`

**Sets the git commit config**

<details>

```
 Options:
 --global: sets the info globally

 Params:
 $1: user name
 $2: user email
```

</details>


---

### `_git_auto_setup_commit_config()`

**Sets the git commit config of the local repo**

<details>

```
 according with the information on the environment

 Expected Vars:
 GIT_USER_NAME: user name
 GIT_USER_EMAIL: user email
```

</details>


---

### `_git_ref_to_version()`

**Extract the tag(s) on the given gitref string**

<details>

```
 Params:
 $1: dest var
 $2: git-ref
```

</details>


---

### `_git_get_current_commit_id()`

**Returns the commit id of the current local repo**


---

### `_git_determine_highest_version()`

**Returns the tag with the highest value**

<details>

```
 Note that the command by default filters out the preview versions

 Options:
 --for: specifies the base version for the search (eg: 6.3 only looks for 6.3.* tags)

 Params:
 $1: the output var
```

</details>


---

### `_git_get_current_branch()`

**Sets the receiver var with the the current git branch**


---

### `_git_commit_exists()`

**Tells if a given commit reference exists on the repo**


---

### `_git_is_dirty()`

**Fails if the worktre has uncommitted or untracked files**

