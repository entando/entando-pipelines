# Notes about testing automation

## Run the tests with:

- `prj/run-tests.sh`

### With param

| param | description |
|-|-|
|`lib`| for the libs tests |
|`macro`| for the macro test |

_please note that "param" is a command delimited list_

### For example this way

```
ENTANDO_OPT_LOG_LEVEL=DEBUG prj/run-tests.sh macro
```

### Insights

The function creates a temporary dir in which the test is executed.
Furthermore defines environment variable defaults, deploys some fixtures and mock some resources by operating of the enviroment variables.

The script provides two mocked repositories that can be addressed through these variables:

- `ENTANDO_OPT_REPO_BOM_URL`: a mock of the BOM repository
- `EE_CLONE_URL`: a mock of a module repository

## Functions

### FAIL

`FAIL {reason}`

Stop the test execution with an error

### ASSERT

```
ASSERT {VAR-NAME} {OP} {EXPECTED-VALUE}
```

Expects the `VAR-NAME` content to match the `EXPECTED-VALUE` according with `OP`

```
ASSERT -v {VALUE-DESC} {VAL} {OP} {EXPECTED-VALUE}
```

Expects `VAL` to match `EXPECTED-VALUE` according with `OP`.  
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
Put it in the middle to a test to drop a shell with all the execution environment available, including the temporary test work dir, variables and functions.

The function used to parse the pipelines context and populate the execution enviroment is called:

- `_ppl-load-context {pipeline context}`


### TEST_APPLY_OVERRIDES

Define a function `TEST_APPLY_OVERRIDES` before the a macro invocation in order to define the overrides to apply when the macro is being executed.
