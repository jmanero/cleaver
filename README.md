Test Cluster
============
Build a test cluster with Vagrant

## Configuration Files
* Vagrantfile and Berksfile - If you don't know, you probably can't afford it.
* config.json - Berkshelf configuration. **Edit your chef server URL and credentials here**
* .chef/client.pem - *gitignored* Put the client key for the user defined in the configurations in `config.json` here.
* .chef/validator.pem - *gitignored* Put the validator key for the chef server configured in `config.json` here.

## Scripts
* `cookbook upload[ --force][ cookbook_name]|purge|reset`
  * `upload` run `berks upload` (optional --force option and cookbook) to push cookbook(s) to the chef server
  * `purge` Purge all cookbooks from the chef server and clear the local berkshelf
  * `reset` Equivalent to running `purge`, the `upload` (`--force` is never necessary as all cookbooks/versions have already been removed from the chef server)
* `node {destroy|provision|create|reset <node>[ <node> ...]}|purge`
  * `destroy|provision|create|reset <node>...` Do it to each node in the argument list
  * `purge` Delete all VMs, nodes, and clients but `chef-valadator` and `chef-webui`. **WARNING** This will delete the validation client from your enterprise-chef organization if it is not `chef-validator`!
* `network` Ensure that VirtualBox host-only networks are properly configured
* `reset` Reset cluster to like-new state: run `./networking`, `./cookbook reset`, `./node purge`, and `vagrant up rdns0 rdns-1` in sequence. **WARNING** This will delete the validation client from your enterprise-chef organization if it is not `chef-validator`!

## Notifications
Scripts make calls to `growlnotify` if it is available. This allows you to route status messages to your service of choice. I use [Prowl](http://www.prowlapp.com/) to push notifications to my iPhone when my desktop is locked.
