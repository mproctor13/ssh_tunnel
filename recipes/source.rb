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


if node["ssh_tunnel"]["nologin"].nil?
  node.set_unless["ssh_tunnel"]["nologin"] = `which nologin`.strip  
end

user node["ssh_tunnel"]["source_user"] do
  supports :manage_home => true
  shell node["ssh_tunnel"]["nologin"]
  action :create
end
directory "/home/#{node["ssh_tunnel"]["source_user"]}/.ssh" do
  owner node["ssh_tunnel"]["source_user"]
  group node["ssh_tunnel"]["source_group"]
  mode "0700"
  recursive true
  action :create
end
execute "generate ssh key for #{node["ssh_tunnel"]["source_user"]}." do
  user node["ssh_tunnel"]["source_user"]
  creates "/home/#{node["ssh_tunnel"]["source_user"]}/.ssh/id_rsa.pub"
  command "ssh-keygen -t rsa -q -f /home/#{node["ssh_tunnel"]["source_user"]}/.ssh/id_rsa -P \"\""
end

# Save public key to chef-server 
ruby_block 'node-save-pubkey' do
  block do
    node.set["ssh_tunnel"]['ssh-pubkey'] = File.read("/home/#{node["ssh_tunnel"]["source_user"]}/.ssh/id_rsa.pub")
    node.save unless Chef::Config['solo']
  end
end

hosts = {}
host_keys = {}
node["ssh_tunnel"]["tunnels"].each do |tunnel,config|
  sstr = "recipes:ssh_tunnel\\:\\:server AND ssh_tunnel_enabled:#{tunnel} AND chef_environment:#{node.chef_environment}"
  nodes = search(:node,  sstr)
  nodes.each do |node|
    hosts[node.name] = {} if hosts[node.name].nil?
    hosts[node.name]["tunnel"] = [] if hosts[node.name]["tunnel"].nil?
    hosts[node.name]["node"] = node
    hosts[node.name]["tunnel"] << tunnel
    host_keys[node["fqdn"]] = node["ssh_tunnel"]["ssh-hostkey"]
  end
end

template "/home/#{node["ssh_tunnel"]["source_user"]}/.ssh/known_hosts" do
  source "known_hosts.erb"
  mode '0644'
  owner 'root'
  group 'root'
  variables :host_keys => host_keys
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

