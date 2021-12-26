# ABOUT EPIC BRANCHES

# BRIEF

Epic branches are long running feature branches that work like main branches but
for a topic that can't be exausted in a single topic branch/PR. Since they work
in the same way, developers also operate on it with the usual workflow but by
using the epic branch as base branch, instead of the main one.


# THE SHAPE OR AN EPIC BRANCH

```
                           [eventually, it's merged back]
                           [to main with an "epic PR"   ]
                                          |
--o--------------------------- [...] -----o---------->    [MAIN BRANCH]
   \                           [...]     /
    o--o---------o---------o-- [...] ---o                 [EPIC BRANCH]
        \       / \       /
         o-PR1-o   o-PR2-o                                [PRs]

```

#  FEATURE FLAG

- `EPIC_BRANCHES` (enabled by default)

# RULES

## 1) The Epic Branch should be named using the syntax

```
- epic/{epic-name}
```

### For instance:

```
- Epic branch: epic/a-long-change
```

the leftmost backslash is the actual separator and the part on the right is called by
these pipelines **epic name** or **epic branch qualifier**


## 2) Base branch

Of course the PRs of an epic branch should always be based and merged back
to the epic branch

## 3) PR titles

On top of the already existing PR naming contraints the PRs of an epic branch 
also need to reference the epic name.

### For instance:

```
a-long-change/ENG-999 Some change
```

## 4) Epic PR

The Epic Branch will be eventually merged back to the main branch by using a
so-called "Epic PR" that follows the PR rules of the main branch.

### Please note

- The epic version of the variables might not be exported by default on the
workflow files of the CI/CD provider and so they might not be available by
default to the pipelines.

- There is a small chance of naming conflict between epic and non epic var that
we chose to accepted in order to keep the syntax clean. This possibility anyway
turn to zero if you keep the epic names lowercase.


# IMPACT ON THE PIPELINES

## Snapshot version tags

The epic name will be added to the snapshot version tags with an "EP" segment.

### For instance:

```
v7.0.0-ENG-999-PR-121-EP-a-long-change
```

## Snapshot artifacts and images

As they are generated after the snapshot tags their naming will change accordingly

## BOM

In case of BOM these pipelines assumes the use of a corresponding 
epic branch, with the same name, on the BOM repository.
