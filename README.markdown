# git-wiki #

A wiki engine that uses Git repository as its data store and sinatra as its web framework

## Required gems ##

- sinatra
- grit
- bluecloth
- rubypants

## Getting started ##

    export WIKI_HOME=~/mywiki # governs where wiki is stored, defaults ~/wiki

    ruby git-wiki.rb

## Running in production ##

    ruby git-wiki.rb -e production [-p 8080] # optionally set port





