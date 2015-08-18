# BuildTree v2

BuildTree is an open source continous integration service.

## Features

* Github OAuth integration
* Github commits kick off builds
* Builds are isolated from one another
* Docker based build images
* Code based configuration of builds
* Parallel and After Success Builds
* SubProject builds

## Local Development

### Required Keys/Tokens

Generate OAuth Keys [via Github](https://github.com/settings/applications/new)

Use `http://<hostname>:<port>/` and `http://<hostname>:<port>/auth` as
your Homepage and Callback URL.

### Local Dev Machine Setup

```
# Update .env with GITHUB_KEY and GITHUB_SECRET
cp .env.example .env
# Start Postgres
# Create a buildtree user with permissions
createuser --createdb buildtree

git clone https://github.com/pcorliss/buildtree.git
cd buildtree

# RVM is what I use but as long as ruby-2.2.1 is installed you should be okay
bundle install
rake db:create:all
rake db:migrate

spring rspec
rails server

# Build Worker Requires
# >= git 2.3
# Running docker host `docker ps -a`
./bin/delayed_job run --sleep-delay=5
```

## Running BuildTree via Docker Compose on a Single Host

```
rake secret # SECRET_KEY_BASE
pwgen -s1 16 # POSTGRES_PASS & POSTGRES_PASSWORD
pwgen -s1 16 # SSH_PASSPHRASE
host -f # DEFAULT_HOST

cp docker-compose.yml.example my-buildtree.yml
cp .env-compose.example .env-compose

# If using boot2docker set DEFAULT_HOST to the hostname of your VM
docker-compose -f my-buildtree.yml up -d db
docker-compose -f my-buildtree.yml run app bundle exec rake db:migrate
docker-compose -f my-buildtree.yml up --no-recreate
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
  - [x] Dockerize
  - [x] Dockerhub
  - [x] Docker Compose
    - [x] Fix Assets
    - [ ] Default Host - Maybe we could make this get the FQDN on boot
  - [x] Docker Compose Example
  - [ ] Terraform
- [ ] Tag
- [ ] Screenshots

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
- [ ] SSL Config without forking
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
