# repo-tools

simple tool to help executing operations against a batch of repositories

# Syntax

```
./repo-tools {command} {target} {options}
```

# Commands

|command|description|
|---|---|
| `install-pipeline` | Installs the current version of the pipeline present on the dir `/install` |
| `update-mainline` | Updates the mainline version (`--version {X.Y}`) on the project files |
| `status` | print the git status of the repo |
| `custom` | runs a custom command (`--cmd {command}`)against the repo |
| `create-pr` | creates a PR given the implementation dialect |

# Target

```
Syntax 1 => {repository-url}     (address of the target repository)
Syntax 2 => --batch {list-file}  (name of the list file [*1] without the extension)
```

- `[*1]` list files are found under `cli-tools/_repo/` and have extension `.list`

# Common Options

|command|description|
|---|---|
| `--base {value}` | the base development branch of the repository |
| `--reuse` | allows to reuse existing cloned repos and branches |
| `--force-new-branch` | forces a brand new PR branch even if it already exists |
| `--no-pull` | doesn't force pull in case of existing local branch |
| `--push` | pushes at the end of the operation |
| `--push-force` | force the push, useful with `--force-new-branch` |
| `--msg {value}` | the commit and/or PR message |
| `--dialect {value}` | the implementation dialect (eg: github) |
| `--log-level {value}` | the log level |


# Examples

## Clones and install on the clone the pipelines

```
./repo-tools install-pipeline --batch all-app --branch "ENG-2704-start-version-7-0" --work-dir ../tmp/repos --no-pull --no-push --reset
```

- `--no-pull` + `--foce-new-branch` =>  essentially starts from a new branch even if the branch already exists
- `--no-push` =>  doesn't automatically push the branch at the end of the operation
- `--work-dir ../tmp/repos` => instead of creating effimeral work-areas adopts a user provided persistent work-area to clone and operate on the repos
