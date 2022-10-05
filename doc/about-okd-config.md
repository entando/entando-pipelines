# ENVIRONMENT VARIABLES USED TO CONNECT TO OKD/OCP (openshift):

Once activate via:

- `ENTANDO_OPT_OKD_LOGIN=true`

and provided a:

- `ENTANDO_OPT_OKD_LOGIN_URL`

the pipelines try to connect to an OKD instance before running the FULL-BUILD or the post-deployment tests.

Check the help of `kube.oc-login` for info about the remainig environment variables.
