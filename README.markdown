# git-wiki #

A wiki engine that uses Git repository as its data store and sinatra as its web framework

## Required gems ##

- sinatra
- git
- grit
- kramdown  - faster Ruby-only version of Maruku, see [http://kramdown.rubyforge.org](http://kramdown.rubyforge.org)
- coderay   - (optional) for code syntax highlighting

## Required software ##

- git


## Getting started ##

    export WIKI_HOME=~/mywiki # governs where wiki is stored, defaults ~/wiki
    cd git-wiki
    git submodule init && git submodule update && cd ./sinatra && git submodule init && git submodule update && cd ..

    ruby git-wiki.rb

### Works in JRuby too

    jruby -S git-wiki.rb 

## Running in production ##

### Running single mongrel

    ruby git-wiki.rb -e production [-p 8080] # optionally set port

