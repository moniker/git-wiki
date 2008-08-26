# git-wiki #

A wiki engine that uses Git repository as its data store and sinatra as its web framework

## Required gems ##

- sinatra
- git
- grit
- maruku

## Required software ##

- git


## Getting started ##

    export WIKI_HOME=~/mywiki # governs where wiki is stored, defaults ~/wiki
    cd git-wiki
    git submodule init
    git submodule update

    cd ./sinatra;
    git submodule init
    git submodule update
    cd ..

    ruby git-wiki.rb

## Running in production ##

### Running single mongrel

    ruby git-wiki.rb -e production [-p 8080] # optionally set port

### Using thin, rack, and nginx

See config files on deploy directory and review these links below.

- [Setting up Thin on Ubuntu][]
- [Deploying Sinatra with Thin][]
- [Installing Nginx on Ubuntu][]
- [Setting up Nginx with Thin][]
- [Thin Usage][] shows how to use unix sockets with nginx


[Thin Usage]: http://code.macournoyer.com/thin/usage/
[Setting up Thin on Ubuntu]: http://articles.slicehost.com/2008/5/6/ubuntu-hardy-thin-web-server-for-ruby
[Setting up Nginx with Thin]: http://articles.slicehost.com/2008/5/27/ubuntu-hardy-nginx-rails-and-thin
[Deploying Sinatra with Thin]: http://www.gittr.com/index.php/archive/deploying-sinatra-via-thin-and-lighttpd/
[Installing Nginx on Ubuntu]: http://articles.slicehost.com/2008/5/13/ubuntu-hardy-installing-nginx-via-aptitude











