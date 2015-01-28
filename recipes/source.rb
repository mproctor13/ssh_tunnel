#
# Cookbook Name:: ssh_tunnel
# Recipe:: source
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
  This recipe setup ssh tunnels to destination nodes configured by the [ssh_tunnel::server](#ssh_tunnelserver)

  @section Usage
    ```json
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
    ```


  #>
=end

hosts = {}
node_find = Proc.new {
  host_keys = {}
  node["ssh_tunnel"]["tunnels"].each do |tunnel,config|
    env_limit = " AND chef_environment:#{node.chef_environment}"
    sstr = "recipes:ssh_tunnel\\:\\:server AND ssh_tunnel_enabled:#{tunnel}#{env_limit}"
    Chef::Log.debug "search=[#{sstr}]"
    nodes = search(:node,  sstr)
    Chef::Log.debug "nodes_found=[#{nodes.count}]"
    nodes.each do |node|
      hosts[node.name] = {} if hosts[node.name].nil?
      hosts[node.name]["tunnel"] = [] if hosts[node.name]["tunnel"].nil?
      hosts[node.name]["node"] = node
      hosts[node.name]["tunnel"] << tunnel
      host_keys[node["fqdn"]] = node["ssh_tunnel"]["ssh-hostkey"]
    end
  end
  host_keys
}

ssh_src "ssh_tunnel" do
  src_username node["ssh_tunnel"]["source_user"]
  src_grpname node["ssh_tunnel"]["source_group"]
  finder node_find
end

hosts.each do |nodename,values|
  options = []
  values['tunnel'].each do |tunnelname|
    tunnel_config = node["ssh_tunnel"]["tunnels"][tunnelname]
    if tunnel_config["reverse"] 
      options << "-R #{tunnel_config[:local_port]}:#{tunnel_config[:remote_host]}:#{tunnel_config[:remote_port]} "
    else
      options << "-L #{tunnel_config[:local_port]}:#{tunnel_config[:remote_host]}:#{tunnel_config[:remote_port]} "
    end
  end
  
  template "/etc/init/tunnel_#{nodename}.conf" do
    source "ssh_tunnel.conf.erb"
    mode '0644'
    owner 'root'
    group 'root'
    variables({
      :tunnels => options.join(" "),
      :remote_host => values["node"]["fqdn"],
      :username => values["node"]["ssh_tunnel"]["server_user"]
    })
  end

  service "tunnel_#{nodename}" do
    supports :restart => true, :reload => true
    action [:enable, :start]
    subscribes :restart, "template[/etc/init/tunnel_#{nodename}.conf]", :delayed
  end
end

