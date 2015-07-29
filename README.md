# BuildTree v2

BuildTree is an open source continous integration service.

## Features

* Github OAuth integration
* Github commits kick off builds
* Builds are isolated from one another
* Docker based build images
* Code based configuration of builds

## Installation

## Development

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
- [ ] Construct a shell script from a config file
- [ ] Check out a specific SHA, not just the head of the branch
- [ ] Github Integration (Callbacks)
- [ ] Run docker within docker
- [ ] Installation documentation

#### TODOs for future releases
- [ ] Setup Websocket communication between front-end and builder
- [ ] Setup Websocket communication between front-end and client
- [ ] Save logs to S3 instead of the DB
- [ ] A resync user permissions button
- [ ] Create a repo query event which enques a build on repo creation.
- [ ] Destroy docker instance after running
- [ ] add pagination repos show
- [ ] UI Breadcrumbs
- [ ] Secrets
- [ ] Dependent Builds
- [ ] Matrix Builds
- [ ] Slack Notifications
- [ ] Elastic Builds (Spin up Workers on demand)
- [ ] Caching of dependencies cache
- [ ] Docker Registry
- [ ] SSH Access to running docker image
- [ ] Pull Request Security
- [ ] Fine-Grained Security support, view vs. create vs. admin
- [ ] Build isolation security work
- [ ] Shareable Custom Dashboards
