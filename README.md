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

#### TODOs
* add pagination repos show
* user dashboard redirect on auth
* repo#new should note which repos are already in the system
* Flush user_repos cache every 24 hours
* Create a repo query event which enques a build on repo creation.
* Command Output and docker output to user/logs
* Construct a shell script from a config file
* Destroy docker instance after running
* Present the logs as the build is running
* save the logs somewhere
* a usable UI
