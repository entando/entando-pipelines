# A macro is..

A macro is a function that implements a high level job or step.

## It is defined on code this way:

```
ppl--{macro-name}() {
  ...
}
```

## And invoked from pipelines this way:

```
~/ppl-run {macro-name} {args}
```

_Please note that the `ppl--` prefix is dropped on invocation_

## Multiple invocations are possible by using "`..`" as separator:

```
~/ppl-run {macro-name} {args} \
       .. {macro-name} {args}
```

_Note:_  
- _the symbol "`@`" before a macro name prevents an error from interrupting the whole execution_

# Arguments

Macros have 4 standardized options:

 - `--id {id}` the identifier of the macro execution, used for log messages
 - `--lcd {dir}` the local directly where the project repository was cloned
 - `--token {token}` a token to use insted of the one provided by the context
 - `--out {file}` file pathname where the full output of the command is written

However, they may or may not be supported and may or may not be mandatory, depending on the macro.   
Only "`--id`" is always supported, but not mandatory.

# List of Macros

Check [macros.md](macros.md) for a list of macros and related documentation
