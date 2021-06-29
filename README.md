# entando-pipelines

Scripts for automating the Entando Pipelines

# How to use it

## Install

```
source <(curl -qsL "https://raw.githubusercontent.com/entando/entando-pipelines/{tag}/macro/install.sh")
```

## Run a macro

```
~/ppl-run {macro-name} {params}
```
## Run a sequence of macros

```
~/ppl-run {macro-name} {params} --AND {macro-name} {params} ..
```

# Enviroment Options:

| name | description | values |
| - | - | - |
| `ENTANDO_OPT_LOG_LEVEL`  | The log trace level |`TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR` |
| `ENTANDO_OPT_PR_TITLE_FORMAT` | the title format to enforce | **[M]** `SINGLE`,`HIERARCHICAL`,`ANY` |
| `ENTANDO_OPT_REPO_BOM_URL`  | the URL of the entando core bom | |
| `ENTANDO_OPT_SUDO` | sudo command to use | |
| `ENTANDO_OPT_NO_COL` | toggles the color ascii codes | `true`,`false` |
| `ENTANDO_OPT_STEP_DEBUG` | toggle the step debug in macros | `true`,`false` |

**[M]:** _Multiple values can be combined with the symbol_ `"|"`


# Defaults

Defaults are usually set on the organization as secrets.  
If they are not, the code assumes these ones:  


| name | default value |
| - | - |
| `ENTANDO_OPT_PR_RTITLE_FORMAT` | `SINGLE\|HIERARCHICAL` |
| `ENTANDO_OPT_REPO_BOM_URL`  | _the URL of the official Entando core bom repo_ |
| `ENTANDO_OPT_NO_COL` | `false` |
| `ENTANDO_OPT_SUDO` | `sudo` |
| `ENTANDO_OPT_STEP_DEBUG` | `false` |
