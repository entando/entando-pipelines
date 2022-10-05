# EXECUTION PLANS

# Brief

Execution plans are simple comma separed list of macro-commands that can be used to
control the behaviour of a pipelines process.


# Environment Vars

| VarName | Description |
| - | - |
| ENTANDO_OPT_FULL_BUILD_PLAN | The execution plan of the full build process |
| ENTANDO_OPT_TEST_POSTDEP_PLAN | The execution plan of the post-deployment process |

# Plan Commands:

```
RESET-TEST-NAMESPACE                   => deletes and recreates the test namespaces
DEPLOY-PROJECT-HELM                    => deploys the project charts present in the project
DEPLOY-OPERATOR-CLUSTER-REQUIREMENTS   => deploys the cluster requirements of the given operator
DEPLOY-OPERATOR-NAMESPACE-REQUIREMENTS => deploys the namespace requirements of the given operator (except for the deployments)
DEPLOY-OPERATOR                        => deploys the operator in the test namespace (implies DEPLOY-OPERATOR-NAMESPACE-REQUIREMENTS)
RUN-TESTS                              => runs the tests
FULL-BUILD                             => runs the full build
SUSPEND-TEST-NAMESPACE                 => scales to 0 all the deployments of the test namespace
DELETE-TEST-NAMESPACE                  => deletes the test namespace
OKD-LOGIN                              => login to the configured OKD server
COMPOSE-UP                             => if a docker compose file is present executes the "up" command on it
COMPOSE-DOWN                           => if a docker compose file is present executes the "down" command on it
```
