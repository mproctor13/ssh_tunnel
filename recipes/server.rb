#
# Cookbook Name:: ssh_tunnel
# Recipe:: server
#
# Author:: Michael Proctor-Smith (<mproctor13@gmail.com>)
#
# Copyright 2015, Michael Proctor-Smith
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

=begin
  #<
  This recipe sets up node to allow connections for nodes configured by the [ssh_tunnel::source](#ssh_tunnelsource)

  @section Usage
    ```json
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
    ```


  #>
=end

enabled = {}
node_find = Proc.new {
  keys = []
  node['ssh_tunnel']['tunnels'].each do |name,active|
    if active
      env_limit = " AND chef_environment:#{node.chef_environment}"
      sstr = "recipes:ssh_tunnel\\:\\:source AND ssh_tunnel_tunnels:#{name}#{env_limit}"
      Chef::Log.debug "search=[#{sstr}]"
      nodes = search(:node, sstr)
      Chef::Log.debug "nodes_found=[#{nodes.count}]"
      nodes.each do |node|
        unless node['ssh_tunnel']['ssh-pubkey'].nil?
          node.set_unless["ssh_tunnel"]['configured'][node.fqdn] = true
          keys << node['ssh_tunnel']['ssh-pubkey']
	  enabled[name] = true
        end
      end
    end
  end
  keys
}

ssh_dst "ssh_tunnel" do
  dst_uid 0 # so that we can connect to privlaged ports
  dst_username node["ssh_tunnel"]["server_user"]
  dst_grpname node["ssh_tunnel"]["server_group"]
  finder node_find
end
node.default["ssh_tunnel"]["enabled"] = enabled
node.save unless Chef::Config['solo']

