# FEATURES FLAGS

## The following elements:

- Environment Variable `ENTANDO_OPT_FEATURES`
- Environment Variable `ENTANDO_OPT_GLOBAL_FEATURES`
- The labels defined on the PR

once combined define a list of feature-flags directives

## Syntax

### Directives

 - Enable a feature: `+{FEATURE}` or `{FEATURE}` or `ENABLE-{FEATURE}`
 - Disable a feature: `-{FEATURE}` or `DISABLE-{FEATURE}`
 - Disable a feature once: `SKIP-{FEATURE}` (only labels)
 
### General

 - Environment variables contains lists of directives separed by "," or "/" or "|" or a line-feed 
 - Note that SKIP directives are only allowed in labels, which in fact are automatically removed from the PR, after evaluation.

## Priorities rules

 1. `LABELS` wins over `ENTANDO_OPT_FEATURES` which wins over `ENTANDO_OPT_GLOBAL_FEATURES`
 2. the last directive of a given feature overrides the previous directives of the same feature
 3. Above rule #1 wins over rule #2
