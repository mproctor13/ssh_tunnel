# Description

Setup ssh tunnels between source and server.

# Requirements

## Platform:

* Ubuntu
* Debian
* Redhat
* Centos

## Cookbooks:

* ssh_src_dst

# Attributes

* `node['ssh_tunnel']['source_user']` - The user that will be used on source server, will be created automatically. Defaults to `"ssh_tunnel"`.
* `node['ssh_tunnel']['source_group']` - The primary group that Source User will be set to use. Defaults to `"daemon"`.
* `node['ssh_tunnel']['server_user']` - The user that will be used on target server, will be created automatically. Defaults to `"ssh_tunnel"`.
* `node['ssh_tunnel']['server_group']` - The primary group that User on Server will be set to use. Defaults to `"daemon"`.

# Recipes

* [ssh_tunnel::source](#ssh_tunnelsource) - Include this recipe on host that ssh tunnel will originate from.
* [ssh_tunnel::server](#ssh_tunnelserver) - Include this recipe on server that is the endpoint of SSH tunnel.

## ssh_tunnel::source

  This recipe setup ssh tunnels to destination nodes configured by the [ssh_tunnel::server](#ssh_tunnelserver)


### Usage
    {
      "name":"source_node",
      "ssh_tunnel": {
        "tunnels": {
          "https": {
            "reverse": true,
            "local_port": 443,
	    "remote_port": 443,
            "remote_host": "localhost"
          },
          "http": {
            "reverse": true,
            "local_port": 80,
            "remote_port": 1234,
            "remote_host": "localhost"
	  }
        }
      },
      "run_list": [
        "recipe[ssh_tunnel::source]"
      ]
    }


## ssh_tunnel::server

  This recipe sets up node to allow connections for nodes configured by the [ssh_tunnel::source](#ssh_tunnelsource)


### Usage
    {
      "name":"destination_node",
      "ssh_tunnel": {
        "tunnels": {
          "chef": true,
          "other": true
        }
      },
      "run_list": [
        "recipe[ssh_tunnel::server]"
      ]
    }



License & Authors
-----------------
- Author:: Michael Proctor-Smith (<mproctor13@gmail.com>)

```text
Copyright:: 2015, Michael Proctor-Smith

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
