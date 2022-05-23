# DATA REPOSITORY

From `v1.4.0` pipelines support the use of a git repository to centralize configurations like pipeline settings or scan suppression files.
This repository is internally called "data repository", or simply "data-repo".

# ACTIVATION

The data repository is actived by the definition of the variable `ENTANDO_OPT_DATA_REPO`.  
The following are the available configuration variables:

```
ENTANDO_OPT_DATA_REPO =>        url of the data repository
ENTANDO_OPT_DATA_REPO_TOKEN =>  optional token in case the data repository is authenticated
```

# NO SECRETS POLICY

This repository can also potentially contain other data but **NEVER SECRETS** for which instead the it will be necessary to use the native secrets of the underlaying CI/CD.

# OVERVIEW

The pipelines call the script `./configure.sh` in order to gather properties related to the information stored in the data-repo. The most important properties returned by the script are:

```
ENTANDO_OPT_ENVIRONMENT_FILE => path of the file that contains the pipelines environment definition.
ENTANDO_OPT_ENVIRONMENTS => the names of the environments definitions to load
```

## Input

The script usually takes its decisions by checking some of the input arguments:

```
REPO_NAME="$1"            # repo name
NEAREST_BASE_BRANCH="$2"  # nearest base branch
BRANCHING_TYPE="$3"       # branching type
PIPELINE_JOB="$4"         # pipeline job
ENVIRONMENT_NAMES="$5"    # the proposed list of environments to load
FIRST_STEP="$6"           # true if this is the first step of a job
DEBUG_MODE="$7"           # debug mode flag
```

## Output

the scripts print the properties assignments (X=Y) to the stdout, separed by a unix newline (`\n'`)

**Note that** when it comes to returning paths relative to the script base dir, the script is required to compose an absolute paths.


## Notes about the executions

The script is called for every step of every job of the pipeline and keep in mind the the filesystem is cleared between different job executios but persists between different steps executions.
So if you need to run some job initialization procedure you may implement your logic or just ensure that the input argument `FIRST_STEP` is `"true"`.

# STORY OR BRANCH AFFINITY

The pipeline will try to load the data-repo commit more suitable for the codebase being built, by using this criteria:

**Given:**

 - `{{qualifier}}` is the ticket qualifier reported on the PR title
 - `{{branch-name}}` is a placeholder of the nearest base branch of the codebase commit being build

**Then:**

1. The pipeline tries to checkout the data-repo branch of name `{{branch-name}}/{{qualifier}}`
2. If the branch is not found, the pipeline tries to checkout the data-repo tag of name `{{branch-name}}-latest`
3. If the tag is not found then the pipelines checkout the data-repo branch `{{branch-name}}`
4. If none of the above are satisfied, then the execution is terminated with an error


# More advanced config scripts

Note that the configure script is also allowed to prepare files on the fly, if you need more control and dynamism.

For example, on `FIRST_STEP="true"` you may generate on the fly an alternative environment file and provide its specific (and potentially temporary) path on the property `ENTANDO_OPT_ENVIRONMENT_FILE`

# Environments definitions file

It's a file that specifies a list of property assignment grouped into different sections called "environments".  
For example:

```
[base]
MODE=simple
[with-full-build]
MODE=full
RUN_TEST=true
[with-special-build]
MODE=special
RUN_TEST=false
```

a property assignment is defined as such:

```
PROPERTY=VALUE
([A-Za-z_]*)=(.*)
```

but can also be preceded by a modified char separed by a semicolon:

```
M;PROPERTY=VALUE

Where M can be:
- a: append to existing value
- p: preserve existing value if provided values is empty
```


It's possible to compose two or more environments by using the `ENTANDO_OPT_ENVIRONMENT_NAMES`, for example:

```
ENTANDO_OPT_ENVIRONMENT_NAMES="base,with-full-build"
```

The environments are loaded from left to right and in case of conflicting properties the ones loaded last "win".

Note that the configure script is a good place to map a specific repo to a specific `ENTANDO_OPT_ENVIRONMENT_NAMES` value.
