# Dependent Builds

Two types: builds that fail the primary and run in parallel. and builds
that are just kicked off by the primary.

## Parallel Builds

## Kicked off in parallel and inform status of master
May need to expand the build job to have a parent job, nil by default,
another build if kicked off. Maybe some sort of indicator that it's
build_on_success or in parallel. The top build will have a sub-project
success and master project success.

### Determining success
Am I (build_success) successful?
Are my non-parralel-children successful?

New DB attrs:

```
parent_id: int
top_parent_id: int (For conveinance)
env: json_string (PARENT_SHA:...)
parallel: boolean (necessary?)
sub_project: path (presence indicates sub project build)
build_success: just this build, not children
```

Build -> Child Build (but another repo? (Yes, repo id would be other))
Need to hide child builds List/GUI? (No)
Need to prevent circular builds (Yes)

Sets SHA, branch and repo automatically

```yaml
build_in_parallel:
- sub_project: 'some/path/inside/project/.bt.yml'
  env:
    PARENT_FOO: ...
- service: github
  organization: foo
  name: bar
  branch: master
  sha: <normally blank>
  env:
    PARENT_SHA: $SHA (We should set these automatically)
    PARENT_BRANCH: $BRANCH
```

## Kicked off by the primary on completion
Builds kicked off by the primary would want an env variable set to
indicate the originating project SHA/branch

We'd use the build job to enqueue and create more builds if successful.

We'd also need a mechanism to forward the SSH Key so they could check
out the top line project

```yaml
build_on_success:
- service: github
  organization: foo
  name: bar
  branch: master
  sha: <normally blank>
  env:
    PARENT_SHA: $SHA (We should set these automatically)
    PARENT_BRANCH: $BRANCH
- service: github
  organization: foo
  name: bar2
  branch: master
  sha: <normally blank>
  env:
    PARENT_SHA: $SHA
    PARENT_BRANCH: $BRANCH
```
