# entando-pipelines

A GitFlow-like workflow implementation for GitHub Actions, with some spice

# Brief

The primary aim of the entando pipelines is to provide a set of high level functions called "macros", designed to be called from the provider workflow scripts. The pipeline developer should avoid creating logic on the provider scripts and instead always implement it in this repository.

## Supported project types

 `maven` | `npm`

## Features:

`PR VALIDITY CHECKS` | `PR PREVIEW ARTIFACTS AND IMAGES` | `FEATURE FLAGS` | `CUSTOM ENVIRONMENT VARS`
| `BOM (BILL-OF-MATERIALS)` | `K8S POST-DEPLOYMENT TESTS` | `OKD CONNECTION` | `DOCKER PUBLICATION`
| `DOCKER-COMPOSE IN TESTS` | `MVN NEXUS PUBLICATION` | `MVN GPG SIGNATURE` | `SNYK SCANS` | `SNYK CONTAINER SCANS` |
`SONARCLOUD SCANS` | `OWASP SCANS` | `EPIC BRANCHES` | `CUSTOM PROJECT FILES (ENP)`

# Install

```
bash <(curl -qsL "https://raw.githubusercontent.com/entando/entando-pipelines/{version-tag}/macro/install.sh")
```


# Macros

A macro is a function that implements an high level job or step.
It is invoked this way:

```
~/ppl-run {macro-name} {args}
```

See also: [About Macros](doc/about-macros.md) and [Macros List](doc/macros.md)


# Configuration

Configuration mostly happens through environment variables.

See [About Configuration](doc/about-config.md) for an overview and some insight

# Additional info and doc

Check the [documentation subdir](doc) for [release notes](doc/RELEASE-NOTES.md), methods reference doc, insight about [testing](doc/TESTING.md) and more.

# Guests Projects

this repository also hosts two "guest" projects:

- `/installation` which are the entando suggested workflow files for the specific provider and project type
- `/cli-tools` which are auxiliary cli script, normally used to simplify interacting with the pipelines and the repositories
