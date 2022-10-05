# ENTANDO PROJECTS

# Brief

`ENP` projects are an internal specification of these pipelines for a minimal project format
based on a project file named `entando-project` or `./ent/ent-prj`.

# Project file

The project file follows a simple multiline variable assigment format.  
The assignment syntax is very limited and only supports literals, single-line values.

### Example:

```
ENTANDO_PRJ_NAME=my project
ENTANDO_PRJ_VERSION=1.0.0
```
# Priority

This project type has priority over any other project file of different type.  
The file `entando-project` has more priority than the file `./ent/ent-prj`.

# Project File Variables

| name | description |
| - | - |
| `ENTANDO_PRJ_NAME` | The name of the project |
| `ENTANDO_PRJ_VERSION` | The artifact |
| `ENTANDO_PRJ_BUILD_COMMAND` | the command to execute to perform the build |
| `ENTANDO_PRJ_TEST_COMMAND` | the command to execute to run the tests |
| `ENTANDO_PRJ_PUBLICATION_COMMAND` | the command to execute to run the artifact publication |
| `ENTANDO_PRJ_IMAGE_PUBLICATION_COMMAND` | the command to execute to the image publication |
| `ENTANDO_PRJ_BUILD_DIR_PATH` | path of the build output directory |
| `ENTANDO_PRJ_BUILD_KEY_COMMAND` | command to execute to build the build cache key |
