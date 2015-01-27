name             "ssh_tunnel"
maintainer       "Michael P Proctor-Smith"
maintainer_email "mproctor13@gmail.com"
license          "Apache 2.0"
description      "Setup ssh tunnels between source and server."
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

%w( ubuntu debian redhat centos ).each do |os|
  supports os
end

suggests "openssh"

attribute "ssh_tunnel/source_user", 
  :display_name => "User on Source",
  :description => "The user that will be used on source server, will be created automatically.",
  :type => "string",
  :required => "required",
  :default => "ssh_tunnel" 

attribute "ssh_tunnel/source_group", 
  :display_name => "Source User's Group.",
  :description => "The primary group that Source User will be set to use.",
  :type => "string",
  :required => "required",
  :default => "daemon"
 
attribute "ssh_tunnel/server_user", 
  :display_name => "User on Server",
  :description => "The user that will be used on target server, will be created automatically.",
  :type => "string",
  :required => "required",
  :default => "ssh_tunnel" 

attribute "ssh_tunnel/server_group", 
  :display_name => "Source User's Group.",
  :description => "The primary group that User on Server will be set to use.",
  :type => "string",
  :required => "required",
  :default => "daemon"

recipe "ssh_tunnel::source", "Include this recipe on host that ssh tunnel will originate from."
recipe "ssh_tunnel::server", "Include this recipe on server that is the endpoint of SSH tunnel."

