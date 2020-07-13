#!/bin/bash

#Create GitWeb Instance Config
touch /etc/lighttpd/lighttpd_gitview.conf
config_view=/etc/lighttpd/lighttpd_gitview.conf


read -r -d '' view_contents << EOM

server.document-root = "/home/git_repo/index.html/"
server.port = 3000

server.username = "git_view"
server.groupname = "git_view"
mimetype.assign = (
  ".html" => "text/html",
  ".txt" => "text/plain",
  ".jpg" => "image/jpeg",
  ".png" => "image/png"
)

static-file.exclude-extensions = ( ".fcgi", ".php", ".rb", "~", ".inc" )
index-file.names = ( "index.html" )

server.modules += ( "mod_alias", "mod_cgi", "mod_redirect", "mod_setenv" )
url.redirect += ( "^/gitweb$" => "/gitweb/" )
alias.url += ( "/gitweb/" => "/usr/share/gitweb/" )

$HTTP["url"] =~ "^/gitweb/" {
       setenv.add-environment = (
               "GITWEB_CONFIG" => "/etc/gitweb.conf",
               "PATH" => env.PATH
       )
       cgi.assign = ( ".cgi" => "" )
       server.indexfiles = ( "gitweb.cgi" )
}

EOM

echo "$view_contents" > $config_view
