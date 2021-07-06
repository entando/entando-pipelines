# Notes about testing automation

## Run the tests with:

- `prj/run-tests.sh`

### With param

| param | description |
|-|-|
|`lib`| for the libs tests |
|`macro`| for the macro test |

or any other test label (see below)

_please note that "param" is a comma-delimited list_

### For example this way

```
ENTANDO_OPT_LOG_LEVEL=DEBUG prj/run-tests.sh macro
```

### Test Labels

A test label is a comment like this

```
#TEST:lib
```

placed just before the function to run a part of the test

### Insights

The testing process creates a temporary dir in which the test is executed.
Furthermore defines environment variable defaults, deploys some fixtures and mocks some resources by operating on the enviroment variables.

The script provides two mocked repositories that can be referenced through these variables:

- `ENTANDO_OPT_REPO_BOM_URL`: (local) url of the mock of the BOM repository
- `EE_CLONE_URL`: (local) url of the mock of an example module repository



## Functions

### FAIL

`FAIL {reason}`

Stop the test execution with an error

### ASSERT

```
ASSERT {VAR} {OP} {EXPECTED-VALUE}
```

Expects the `VAR` value to match the `EXPECTED-VALUE` according with `OP`

```
ASSERT -v {VALUE-DESC} {VALUE} {OP} {EXPECTED-VALUE}
```

Expects `VALUE` to match `EXPECTED-VALUE` according with `OP`.  
The `VALUE-DESC` is used instead of `VAR-NAME` in order to compose the error message.

#### Available `OP`s

| operator type | operators list |
|-|-|
| Numerical | `-eq`,`-ne`,`-gt`,`-ge`,`-lt`,`-le` |
| General | `=` or `==`,`!=` |
| Regexp | `=~` |

Refer to the bash "IF" documentation for details

## Special

### DBGSHELL

Drops a debug shell.  
Put it in the middle of a test to drop a shell with all the execution environment available, including the temporary test work dir, variables and functions.

### TEST__BEFORE_RUN

Define this function in order to customize the test environment

Example:

```
TEST__BEFORE_RUN() {
  GIT_USER_NAME="Test Bot"
  GIT_USER_EMAIL="test@example.com"
  PPL_CONTEXT="$(cat "$PROJECT_DIR/test/resources/my-context.json")"
}
```

### TEST__APPLY_OVERRIDES

Define this function in order to override the execution environment variables just after the pipeline context is parsed.

Example:

```
TEST__APPLY_OVERRIDES() { EE_PR_TITLE="A-MOCKED-PR-TITLE"; }
```

### ENTANDO_OPT_SHELL_ON_TEST_ASSERT

if set to true the a DBGSHELL is dropped when a test asserts

Examples:
```
ENTANDO_OPT_LOG_LEVEL=DEBUG ENTANDO_OPT_SHELL_ON_TEST_ASSERT=true prj/run-tests.sh macro
```
