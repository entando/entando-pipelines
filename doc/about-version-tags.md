# ABOUT VERSION TAGS

# Brief

Version tags are a way to trigger other workflows and to store build information
that otherwhise would not be possible to retrieve in a non-euristic way.

# Structure

A version tag has this structure:

- `{PREFIX}{MAINLINE}-{QUALIFIER}-{PR-SEG}+{METADATA}`

Furthermore PR-SEG and METADATA follow the "segments" format.  
A segments is key-value elements with this structure:

- `{SEG-NAME}`-`{SEG-VALUE}`


# Placeolders meaning

| Placeholder | Meaning |
|--|--|
| `PREFIX`    | single char prefix that definess the function of the tag |
| `MAINLINE`  | is the mainline version number plus a zero as patch digit (eg: 7.0.0) |
| `QUALIFIER` | is a code that logically pins together different artifacts and PR, usually the user story code |
| `PR-SEG`    | a segment that stores the pull request number; segment name is `PR` |
| `METADATA ` | build information required by the pipelines process |


# PREFIX

The prefix cat be either:

- `v` => which triggers the workflows and stores the build data
- `p` => which stores the same build data of `v` but doesn't triggers the workflows


# METADATA

The metadata is a dash-seprated list of segments


## Metadata's segments can be:

| Segment name | Meaning |
|--|--|
| `BB` |  the base branch of the PR the contains the tagged commit |
| `KB` |  the branch of the commit, if the tag is on a main or epic commit |

note that `SEG-VALUE` is escaped to handle branch names with slashes:

```
  "/" is escaped to "+2F+"
  "+" is escaped to "++"
```

# Examples


- `v7.0.0-ENG-999-PR-11+FB-develop` (a version tag on a merge commit)
- `v7.0.0-ENG-999-PR-11+BB-develop` (a version tag on a pull-request commit)
- `p7.0.0-ENG-999-PR-11+BB-develop` (a non-triggering version tag on pull-request commit)
- `v7.0.0-ENG-999-PR-11+BB-epic+2F+long-task` (a version tag on a pull-request commit of the epic branch "epic/long-task")

