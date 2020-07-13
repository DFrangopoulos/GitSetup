#!/bin/bash

sudo -s

user1=git_repo
user2=git_view

#Create Users/Groups for the gitweb and the repo
useradd $user1
useradd $user2

#Fix Shells
sed -i 's/git_repo:\/bin\/sh/git_repo:\/bin\/bash/' /etc/passwd
sed -i 's/git_view:\/bin\/sh/git_view:\/bin\/bash/' /etc/passwd

#Create Dirs for logs
mkdir /var/log/$user1
chown -R root:$user1 /var/log/$user1
chmod -R 770 /var/log/$user1

mkdir /var/log/$user2
chown -R root:$user2 /var/log/$user2
chmod -R 770 /var/log/$user2

#Create Home Dirs
mkdir /home/$user1
mkdir /home/$user1/Repos
chown -R $user1:$user1 /home/$user1
chmod -R 755 /home/$user1

mkdir /home/$user2
chown -R $user2:$user2 /home/$user2
chmod -R 755 /home/$user2

#Fix sources
sed -i 's/main/main contrib non-free/g' /etc/apt/sources.list
apt-get update
apt-get upgrade -y

#Install needed software
apt-get --no-install-recommends install lighttpd git htop gitweb -y
lighty-enable-mod cgi

#Delete Old Configs
rm /etc/lighttpd/lighttpd.conf
rm /etc/gitweb.conf

#Create GitWebConfig
touch /etc/gitweb.conf
config_web=/etc/gitweb.conf

read -d '' web_contents << EOM

# path to git projects (<project>.git)
$projectroot = "/home/git_repo/Repos";
# directory to use for temp files
$git_temp = "/tmp";

@diff_opts = ();
EOM

echo "$web_contents" > $config_web


#Create GitWeb Instance Config
touch /etc/lighttpd/lighttpd_gitview.conf
config_view=/etc/lighttpd/lighttpd_gitview.conf


read -d '' view_contents << EOM

server.document-root = "/home/git_repo/index.html/"
server.port = 3000

server.username = "git_view"
server.groupname = "git_view"

mimetype.assign = (
  ".html" => "text/html",
  ".txt" => "text/plain",
  ".jpg" => "image/jpeg",
  ".png" => "image/png",
	".css" => "text/css"
)

static-file.exclude-extensions = ( ".fcgi", ".php", ".rb", "~", ".inc" )
index-file.names = ( "index.html" )

server.modules += ( "mod_alias", "mod_cgi", "mod_redirect", "mod_setenv" )
url.redirect += ( "^/gitweb$" => "/gitweb/" )
alias.url += ( "/gitweb/" => "/usr/share/gitweb/" )

\$HTTP["url"] =~ "^/gitweb/" {
	setenv.add-environment = (
		"GITWEB_CONFIG" => "/etc/gitweb.conf",
		"PATH" => env.PATH
	)

	cgi.assign = ( ".cgi" => "" )
	server.indexfiles = ( "gitweb.cgi" )
}

EOM

echo "$view_contents" > $config_view


#Create Index.html

touch /home/$user1/index.html
config_index=/home/$user1/index.html


read -d '' index_contents << EOM

<!DOCTYPE html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Local Git Server</title>
<style type="text/css" media="screen">
body { background: #e7e7e7; font-family: Verdana, sans-serif; font-size: 11pt; }
#page { background: #ffffff; margin: 50px; border: 2px solid #c0c0c0; padding: 10px; }
#header { background: #4b6983; border: 2px solid #7590ae; text-align: center; padding: 10px; color: #ffffff; }
#header h1 { color: #ffffff; }
#body { padding: 10px; }
span.tt { font-family: monospace; }
span.bold { font-weight: bold; }
a:link { text-decoration: none; font-weight: bold; color: #C00; background: #ffc; }
a:visited { text-decoration: none; font-weight: bold; color: #999; background: #ffc; }
a:active { text-decoration: none; font-weight: bold; color: #F00; background: #FC0; }
a:hover { text-decoration: none; color: #C00; background: #FC0; }
</style>
</head>
<body>
<div id="page">
 <div id="header">
 <h1>Git Repository </h1>
 </div>
 <div id="body">
  <h2>Follow the links below for various functions:</h2>
  <ul>
   <li>Access --> <span class="tt"><a href="http://192.168.13.105:3000/gitweb/">GitWeb</a></span></li>
  </ul>
 </div>
</div>
</body>
</html>

EOM

echo "$index_contents" > $config_index

#Create Certificates
mkdir -p /etc/lighttpd/certs
cd /etc/lighttpd/certs
openssl req -new -x509 -keyout lighttpd.key -out lighttpd.pem -days 365 -nodes
chmod 400 lighttpd.pem
chmod 400 lighttpd.key

#Create Git HTTPS Instance Config

touch /etc/lighttpd/lighttpd_gitrepo.conf
config_repo=/etc/lighttpd/lighttpd_gitrepo.conf


read -d '' repo_contents << EOM

server.document-root = "/home/git_repo/index.html/"
server.port = 4000

server.username = "git_repo"
server.groupname = "git_repo"

server.modules += ( "mod_openssl", "mod_auth" , "mod_alias", "mod_cgi", "mod_redirect", "mod_setenv" )

ssl.engine = "enable" 
ssl.privkey= "/etc/lighttpd/certs/lighttpd.key" 
ssl.pemfile= "/etc/lighttpd/certs/lighttpd.pem" 

ssl.openssl.ssl-conf-cmd = ("MinProtocol" => "TLSv1.2") 

url.redirect += ( "^/git$" => "/git/" )
alias.url += ( "/git" => "/usr/lib/git-core/git-http-backend" )

$HTTP["url"] =~ "^/git" {
     cgi.assign = ("" => "")
     setenv.add-environment = (
             "GIT_PROJECT_ROOT" => "/home/git_repo/Repos/",
             "GIT_HTTP_EXPORT_ALL" => ""
     )
}

EOM

echo "$repo_contents" > $config_repo

#Create Systemd services


#Enable Systemd services


#Fix Permissions at the End
chown -R $user1:$user1 /home/$user1
chmod -R 755 /home/$user1
chown -R $user2:$user2 /home/$user2
chmod -R 755 /home/$user2
