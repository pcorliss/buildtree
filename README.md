# BuildTree v2

BuildTree is an open source continous integration service.

## Features

* Github OAuth integration
* Github commits kick off builds
* Builds are isolated from one another
* Docker based build images
* Code based configuration of builds

## Installation

Generate OAuth Keys [via Github](https://github.com/settings/applications/new)
Generate random passphrase
Set Env Variables via .env file (see the following list)
Enable SSL

```
GITHUB_HOST=<GHE Enterprise or Github>
GITHUB_KEY=<Application Key>
GITHUB_SECRET=<Application Secret>
SSH_KEY_SIZE=4096 # Recomended Default but a little slow
SSH_PASSPHRASE=<Generated random phrase, recomended 40 chars>
POSTGRES_HOST=<Postgres Host>
POSTGRES_PORT=5433
POSTGRES_DATABASE=buildtree_production
POSTGRES_USER=buildtree
POSTGRES_PASS=<Generated random phrase, recomended 40 chars>
```

### Create Database

```
docker run -d --env-file=<env-file> pcorliss/buildtree
```

### On Build Machines

```
docker run -d --env-file=<env-file> --privileged pcorliss/buildtree bin/delayed_job
-n <workers> --sleep-delay=10
```

## Development

```
# Start Postgres
createuser --createdb buildtree

git clone https://github.com/pcorliss/buildtree.git
cd buildtree

# RVM recomended but as long as ruby-2.2.1 is installed you should be okay
bundle install
rake db:create:all
rake db:migrate

rspec
rails server
```

## Environment Variables

Customize your experience by setting environment variables

```
RACK_ENV=development
PORT=3000
GITHUB_HOST=...
GITHUB_KEY=<Your Github Key>
GITHUB_SECRET=<Your Github Secret>
SSH_KEY_SIZE=4096
SSH_PASSPHRASE=hello world
DEFAULT_HOST=localhost:3000
TMPDIR=/Users/.../git/buildtree/tmp
```

### TODOs before 0.1.0 release
- [x] Flush user_repos cache every 24 hours
- [x] a usable UI
  - [x] Create page - point click
  - [x] Repo show page
    - [x] Colored dots
  - [x] Build show page
    - [x] Link to build show from repo show
    - [x] save the logs somewhere
  - [x] user dash
    - [x] Root redirects to user dash
    - [x] Root redirects to signup if you're not signed in
    - [x] Fix other redirects
  - [x] repo#new should note which repos are already in the system
  - [x] Build Head button on repo show
  - [x] Nav (SignIn/Out, Dashboard, Add Repo)
- [x] Check out a specific SHA, not just the head of the branch
- [x] Construct a shell script from a config file
- [x] Github Integration (Callbacks)
- [x] Run docker within docker
- [x] Fail the build if git can't clone or checkout
- [x] A resync user permissions button
- [x] Destroy docker instance after running
- [x] After Success and Parallel Builds
- [ ] Installation documentation
  - [ ] Dockerize

#### TODOs for future releases
- [ ] Synchronous Builds
- [ ] Github Enterprise Support
- [ ] Don't require permissions on a public repo
- [ ] Create a repo if it doesn't exist but is specified
- [ ] Refactor BuildJob into easier to test modules
- [ ] Setup Websocket communication between front-end and builder
- [ ] Setup Websocket communication between front-end and client
- [ ] Fail the build if there is an error of some sort
- [ ] Save logs to S3 instead of the DB
- [ ] Kitchen Sync Dockerfile Build
- [ ] "forget about this build and cleanup after yourself” button
- [ ] Create a repo query event which enques a build on repo creation. (Is this desired behavior with the build head button?)
- [ ] add pagination repos show
- [ ] UI Breadcrumbs
- [ ] Secrets
- [ ] Matrix Builds
- [ ] Verify we're able to checkout other repos within other projects
- [ ] Slack Notifications
- [ ] Handle repo renames gracefully
- [ ] Readable Build Output - split up commands and blocks via echo
  statements
- [ ] Shared Secrets
- [ ] Elastic Builds (Spin up Workers on demand)
- [ ] Display/Store build status like queue time and run time
- [ ] Caching of dependencies cache
- [ ] Docker Registry
- [ ] SSH Access to running docker image
- [ ] Pull Request Security
- [ ] Fine-Grained Security support, view vs. create vs. admin
- [ ] Build isolation security work
- [ ] Shareable Custom Dashboards
- [ ] Better looking dashboards
- [ ] Scheduled Builds
