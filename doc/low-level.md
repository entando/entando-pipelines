
---

### `_github.remove-package()`

**Removes a package from a repository**

<details>

```
 Params:
 $1: full repository identifier (owner/name)
 $2: package version
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
 ENTANDO_OPT_GIT_USER_NAME: user name
 ENTANDO_OPT_GIT_USER_EMAIL: user email
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

### `_git_ref_exists()`

**Tells if a given tag exists on the repo**


---

### `_git_is_dirty()`

**Fails if the worktre has uncommitted or untracked files**


---

### `_github.remove-package()`

**Removes a package from a repository**

<details>

```
 Params:
 $1: full repository identifier (owner/name)
 $2: package version
```

</details>

