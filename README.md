# BuildTree v2

## Features

### Needs
- [x] Github Integration (Auth)
- [x] Github Integration (WebHook)
- [ ] Github Integration (Callbacks)
- [x] Isolated Builds
- [ ] Secrets
- [ ] Code based configuration

### Wants
- [ ] Display/Dashboards
- [ ] Dependent Builds
- [ ] Matrix Builds
- [x] Docker based build images
- [ ] Slack Notifications
- [ ] Monorepo splits
- [ ] Elastic Builds (Spin up Workers on demand)

### Nice to Haves
- [ ] Shared Configs
- [ ] Build an arbitrary tag
- [ ] Cache
- [ ] Docker Registry
- [ ] More Secure way of granting access
- [ ] SSH Access to running docker image
- [ ] Security between builds
- [ ] Pull Request Security

#### TODOs before 0.1.0 release
- [x] Flush user_repos cache every 24 hours
- [ ] a usable UI
  - [x] Create page - point click
  - [x] Repo show page
    - [x] Colored dots
  - [x] Build show page
    - [x] Link to build show from repo show
    - [x] save the logs somewhere
  - [ ] user dash
    - [ ] Root redirects to user dash
    - [ ] Root redirects to signup if you're not signed in
    - [ ] A resync user permissions button
  - [ ] repo#new should note which repos are already in the system
  - [ ] Build Head button on repo show
- [ ] Construct a shell script from a config file
- [ ] Check out a specific SHA, not just the head of the branch
- [ ] Setup Websocket communication between front-end and builder
- [ ] Setup Websocket communication between front-end and client
- [ ] Save logs to S3 instead of the DB
- [ ] Create a repo query event which enques a build on repo creation.
- [ ] Destroy docker instance after running
- [ ] add pagination repos show
