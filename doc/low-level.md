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

### `_semver_ex_parse()`

**Extended version of _semver_parse that also supports 4 digit versions**

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

### `print_current_function_name()`

**Prints the current function name with decorations**

<details>

```
 Params:
 $1  prefix decoration
 $2  suffix decoration
```

</details>

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

### `_pp_adjust_var()`

**Adjust a variable for pretty printing**

<details>

```
 Params:
 $1: the variable to cut
 $2: the max len
```

</details>

### `_NONNULL()`

**Validates for non-null a list of mandatory variables**

<details>

```
 Fatals if a violation is found
```

</details>

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

### `__VERIFY()`

**See __VERIFY_EXPRESSION**

### `DBGSHELL()`

**Drops a shell that inherits the caller environment**

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

### `_extract_pr_title_prefix()`

**Gets the prefix of the PR title**

<details>

```
 Params:
 $1 destination var
 $2 the PR title
```

</details>

### `START_MACRO()`

**Setups the enviroment for a macro execution**

<details>

```
 Params:
 $1 macro name
 $2 pipeline context to parse

 shellcheck disable=SC2034
```

</details>

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

### `_FATAL()`

**Stops the execution with a fatal error**

<details>

```
 and prints the callstack

 Options
 [-s]  simple: omits the stacktrace
 [-S n] skips n levels of the call stack
 [-99] uses 99 as exit code, which indicates test assertion

 Params:
 $1  error message
```

</details>

### `_SOE()`

**STOP ON ERROR**

### `_set_var()`

**Sets a variable given the name and the value**

<details>

```
 IMPORTANT:
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

### `_pkg_get()`

**Install a packet**

<details>

```
 Params:
 $1: name of the packet

 Options:
 -c command: installation check based on command presence
```

</details>

### `require_mandatory_command()`

**Ensura a mandatory command is avaliable**

<details>

```
 Params:
 $1:   command
 [$2]: optional description of the command
```

</details>

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

### `__mvn_deploy()`

**Runs a maven deploy over the received environment params**

<details>

```
 Params:
 $1: repository id
 $2: repository url
```

</details>

### `__git()`

**Runs an arbitrary git command and FATALS if it fails**

### `__git_set_repo_defaults()`

**Sets the repository defaults**

### `__git_init()`

**Runs a git init and sets the repository defaults**

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

### `_git_ref_to_version()`

**Extract the tag(s) on the given gitref string**

<details>

```
 Params:
 $1: dest var
 $2: git-ref
```

</details>

### `_git_get_current_commit_id()`

**Returns the commit id of the current local repo**

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

### `__git_auto_checkout()`

**Checkouts a branch**

<details>

```
 Params:
 $1: the branch to checkout
```

</details>

### `_git_get_current_branch()`

**Sets the receiver var with the the current git branch**

### `__git_force_merge_branch()`

**Merges current branch into the target one, by overriding the target.**

<details>

```
 At the end of the operation the current branch and the target branch will be identical

 Params:
 $1: the target branch
```

</details>

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

### `__git_get_commit_tag()`

**Extract the given commit tag**

<details>

```
 Options:
 --pr-tag filters for snapshot tags

 Params:
 $1  the output var
 $2  the commit reference
```

</details>

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

### `_git_commit_exists()`

**Tells if a given commit reference exists on the repo**

### `__docker()`

**Runs a docker operation**

<details>

```
 Params:
 $@: all params are forwarded to the docker command
```

</details>

### `_pom_get_project_artifact_id()`

**Extacts the artifactId from a pom**

<details>

```
 Params:
 $1: dest var
 $2: pom file pathname
```

</details>

### `_pom_get_project_version()`

**Extacts the version of a artifactId from a pom**

<details>

```
 Params:
 $1: dest var
 $2: pom file pathname
```

</details>

### `_pom_set_project_version()`

**Sets the version of a artifactId from a pom**

<details>

```
 Params:
 $1: new version
 $2: pom file pathname
```

</details>

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

### `_semver_ex_parse()`

**Extended version of _semver_parse that also supports 4 digit versions**

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

### `print_current_function_name()`

**Prints the current function name with decorations**

<details>

```
 Params:
 $1  prefix decoration
 $2  suffix decoration
```

</details>

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

### `_pp_adjust_var()`

**Adjust a variable for pretty printing**

<details>

```
 Params:
 $1: the variable to cut
 $2: the max len
```

</details>

### `_NONNULL()`

**Validates for non-null a list of mandatory variables**

<details>

```
 Fatals if a violation is found
```

</details>

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

### `__VERIFY()`

**See __VERIFY_EXPRESSION**

### `DBGSHELL()`

**Drops a shell that inherits the caller environment**

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

### `_extract_pr_title_prefix()`

**Gets the prefix of the PR title**

<details>

```
 Params:
 $1 destination var
 $2 the PR title
```

</details>

### `START_MACRO()`

**Setups the enviroment for a macro execution**

<details>

```
 Params:
 $1 macro name
 $2 pipeline context to parse

 shellcheck disable=SC2034
```

</details>

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

### `_FATAL()`

**Stops the execution with a fatal error**

<details>

```
 and prints the callstack

 Options
 [-s]  simple: omits the stacktrace
 [-S n] skips n levels of the call stack
 [-99] uses 99 as exit code, which indicates test assertion

 Params:
 $1  error message
```

</details>

### `_SOE()`

**STOP ON ERROR**

### `_set_var()`

**Sets a variable given the name and the value**

<details>

```
 IMPORTANT:
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

### `_pkg_get()`

**Install a packet**

<details>

```
 Params:
 $1: name of the packet

 Options:
 -c command: installation check based on command presence
```

</details>

### `require_mandatory_command()`

**Ensura a mandatory command is avaliable**

<details>

```
 Params:
 $1:   command
 [$2]: optional description of the command
```

</details>

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

### `__mvn_deploy()`

**Runs a maven deploy over the received environment params**

<details>

```
 Params:
 $1: repository id
 $2: repository url
```

</details>

### `__git()`

**Runs an arbitrary git command and FATALS if it fails**

### `__git_set_repo_defaults()`

**Sets the repository defaults**

### `__git_init()`

**Runs a git init and sets the repository defaults**

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

### `_git_ref_to_version()`

**Extract the tag(s) on the given gitref string**

<details>

```
 Params:
 $1: dest var
 $2: git-ref
```

</details>

### `_git_get_current_commit_id()`

**Returns the commit id of the current local repo**

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

### `__git_auto_checkout()`

**Checkouts a branch**

<details>

```
 Params:
 $1: the branch to checkout
```

</details>

### `_git_get_current_branch()`

**Sets the receiver var with the the current git branch**

### `__git_force_merge_branch()`

**Merges current branch into the target one, by overriding the target.**

<details>

```
 At the end of the operation the current branch and the target branch will be identical

 Params:
 $1: the target branch
```

</details>

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

### `__git_get_commit_tag()`

**Extract the given commit tag**

<details>

```
 Options:
 --pr-tag filters for snapshot tags

 Params:
 $1  the output var
 $2  the commit reference
```

</details>

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

### `_git_commit_exists()`

**Tells if a given commit reference exists on the repo**

### `__docker()`

**Runs a docker operation**

<details>

```
 Params:
 $@: all params are forwarded to the docker command
```

</details>

### `_pom_get_project_artifact_id()`

**Extacts the artifactId from a pom**

<details>

```
 Params:
 $1: dest var
 $2: pom file pathname
```

</details>

### `_pom_get_project_version()`

**Extacts the version of a artifactId from a pom**

<details>

```
 Params:
 $1: dest var
 $2: pom file pathname
```

</details>

### `_pom_set_project_version()`

**Sets the version of a artifactId from a pom**

<details>

```
 Params:
 $1: new version
 $2: pom file pathname
```

</details>

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

### `_git_ref_to_version()`

**Extract the tag(s) on the given gitref string**

<details>

```
 Params:
 $1: dest var
 $2: git-ref
```

</details>

### `_git_get_current_commit_id()`

**Returns the commit id of the current local repo**

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

### `_git_get_current_branch()`

**Sets the receiver var with the the current git branch**

### `_git_commit_exists()`

**Tells if a given commit reference exists on the repo**

