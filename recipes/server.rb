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

if node["ssh_tunnel"]["nologin"].nil?
  node.set_unless["ssh_tunnel"]["nologin"] = `which nologin`.strip
end

user node["ssh_tunnel"]["server_user"] do
  supports :manage_home => true, :non_unique => true
  gid node["ssh_tunnel"]["server_group"]
  uid 0
  shell node["ssh_tunnel"]["nologin"]
  action :create
end

# Save host public key to chef-server 
ruby_block 'node-save-hostkey' do
  block do
    node.set["ssh_tunnel"]['ssh-hostkey'] = File.read("/etc/ssh/ssh_host_rsa_key.pub")
  end
end

keys = []
enabled = {}
node['ssh_tunnel']['tunnels'].each do |name,active|
  if active
    sstr = "recipes:ssh_tunnel\\:\\:source AND ssh_tunnel_tunnels:#{name} AND chef_environment:#{node.chef_environment}"
    nodes = search(:node, sstr)
    nodes.each do |node|
      unless node['ssh_tunnel']['ssh-pubkey'].nil?
        node.set_unless["ssh_tunnel"]['configured'][node.fqdn] = true
        keys << node['ssh_tunnel']['ssh-pubkey']
	enabled[name] = true
      end
    end
  end
end

if keys.count > 0
  directory "/home/#{node["ssh_tunnel"]["server_user"]}/.ssh" do
    owner node["ssh_tunnel"]["server_user"]
    group node["ssh_tunnel"]["server_group"]
    mode "0700"
    recursive true
    action :create
  end
  template "/home/#{node["ssh_tunnel"]["server_user"]}/.ssh/authorized_keys" do
    source "authorized_keys.erb"
    owner node["ssh_tunnel"]["server_user"]
    group node["ssh_tunnel"]["server_group"]
    mode "0600"
    variables :ssh_keys => keys
  end
end
node.default["ssh_tunnel"]["enabled"] = enabled
node.save unless Chef::Config['solo']

