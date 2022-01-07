# ENVIRONMENT VARIABLES USED FOR THE PUBLICATION:

| name | description |
| - | - |
| ENTANDO_OPT_DOCKER_BUILDS | Build directives (see below) |
| ENTANDO_OPT_DOCKER_ORG | The docker organization to use for the publication |
| ENTANDO_OPT_DOCKER_USERNAME | The docker user name to use for the publication |
| ENTANDO_OPT_DOCKER_PASSWORD | The docker password or token to use for the publication |

# ENVIRONMENT VARIABLES USED FOR THE TESTS:

| name | description |
| - | - |
| ENTANDO_OPT_TEST_COMPOSE_FILE | The docker-compose file to start before the execution of the standard tests |


## About `ENTANDO_OPT_DOCKER_BUILDS`

this variable used to control the execution of the publication and it's a comma-delimited list of deployment directives in the form:

 - `{docker-file-name}=>{generated-image-full-name}`

the part `generated-image-full-name` can be:

- a fully qualified image name: `{organization}/{name}:{tag}` (but organization and tag are optional)
- nothing, in which case also the `=>` is dropped and `[after-name]` is assumed
- `[simple]`: the image name is simply derived from the project name
- `[after-name]`: like simple but in case of dockerfile extension uses this form: `{organization}/{name}-{ext}:{tag}`
- `[after-tag]`: like simple but in case of dockerfile extension uses this form: `{organization}/{name}:{tag}-{ext}`


## About the rest of the image name:

- `organization` is quite obviously taken from `ENTANDO_OPT_DOCKER_ORG`
- `tag` is derived from the "current" (in PR or after merge) project version
