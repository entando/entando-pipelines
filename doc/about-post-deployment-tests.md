# POST-DEPLOYMENT K8S TEST

The pipelines are capable to create K8S environments over which "post-deployment" tests can be run. For post-deployment test is meant a test that uses the artifact and/or image just-generated by the pipelines in order to  run the tests. These environment are usually called "preview-enviroments" and can be used to run from simple smoke tests to entire tests suites.

# Execution methods:

Given it has been enabled via feature-flag:

- `MTX-MVN-POST-DEPLOYMENT-TESTS`

this subsystem determines the execution modality by looking for:

1. a script `./.github/setup-post-deployment.sh`
2. a chart file `./charts/preview/Chart.yaml`

in this order.

# About `./.github/setup-post-deployment.sh`

It's just a user script.  
With this modality the user can take full responsibility of the generation of the environment or can help preparing the chart-based method.

The script receives 3 parameters:

- the designated test namespace to use
- the project name
- the project version

if the scripts exits with status code `99` the chart-based method is also executed.

_Note:_  
_This modality is currently under review and may be removed in the future: In fact, since it can't directly access the pipelines environment and secrets, we are not sure it can be useful. Also note that this limitation is **by design**, sharing secrets with random user-scripts that can potentially come from external contributors would just be unsafe._

# About `./charts/preview/Chart.yaml`

This subsystem implements this modality in this way:

- Destroys and then recreates the test K8S namespace
- Replaces of the handlebar placeholders on the designated chart files
- Updates the helm dependencies under `preview`
- Runs the template-based manifest generation under `preview`
- Applies the manifest to the connected K8S cluster


## The following are the supported placeholders:

| name | description |
| - | - | 
| ENTANDO_PROJECT_VERSION | the project version derived from the current pipelines execution context |
| ENTANDO_IMAGE_REPO | the docker repository determined by the docker-publication subsystem |
| ENTANDO_IMAGE_TAG | the docker image tag generated by the docker-publication subsystem |
| ENTANDO_OPT_TEST_NAMESPACE | the namespace to use to run the tests, generated by the pipelines if not provided |
| ENTANDO_OPT_IMAGE_REGISTRY_CREDENTIALS | the pull credentials to use incase the registry is authenticated |
| ENTANDO_OPT_IMAGE_REGISTRY_OVERRIDE | the image registry address to use |
| ENTANDO_OPT_TEST_HOSTNAME_SUFFIX | the host name suffix to assume when deriving the full hostname to use in tests |
| ENTANDO_OPT_TEST_TLS_CRT | the TLS cert to use when creating the test tls-secret and the ca-secret |
| ENTANDO_OPT_TEST_TLS_KEY | the TLS key to use when creating the test tls-secret |

## But note that the placeholders are only replaced on these files:

- `Charts.yaml`
- `values.yaml`
- `requirements.yaml`

of the immediate subdirs of the `./charts` directory