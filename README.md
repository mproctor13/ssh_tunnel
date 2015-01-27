# Description

Setup ssh tunnels between source and server.

# Requirements

## Platform:

* Ubuntu
* Debian
* Redhat
* Centos

## Cookbooks:

* openssh (Suggested but not required)

# Attributes

* `node['ssh_tunnel']['source_user']` - The user that will be used on source server, will be created automatically. Defaults to `"ssh_tunnel"`.
* `node['ssh_tunnel']['source_group']` - The primary group that Source User will be set to use. Defaults to `"daemon"`.
* `node['ssh_tunnel']['server_user']` - The user that will be used on target server, will be created automatically. Defaults to `"ssh_tunnel"`.
* `node['ssh_tunnel']['server_group']` - The primary group that User on Server will be set to use. Defaults to `"daemon"`.

# Recipes

* ssh_tunnel::source - Include this recipe on host that ssh tunnel will originate from.
* ssh_tunnel::server - Include this recipe on server that is the endpoint of SSH tunnel.

# License and Maintainer

Maintainer:: Michael P Proctor-Smith (<mproctor13@gmail.com>)

License:: Apache 2.0
