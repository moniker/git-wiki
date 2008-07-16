#!/usr/bin/env ruby

require 'fileutils'
require 'environment'
require 'sinatra'

get('/') { redirect "/#{HOMEPAGE}" }

# page paths

get '/:page' do
  @page = Page.new(params[:page])
  @page.tracked? ? show(:show, @page.title) : redirect('/e/' + @page.basename)
end


get '/:page/raw' do
  @page = Page.new(params[:page])
  @page.raw_body
end

get '/:page/append' do
  @page = Page.new(params[:page])
  @page.body = @page.raw_body + "\n\n" + params[:text]
  redirect '/' + @page.basename
end

get '/e/:page' do
  @page = Page.new(params[:page])
  show :edit, "Editing #{@page.title}"
end

post '/e/:page' do
  @page = Page.new(params[:page])
  @page.update(params[:body], params[:message])
  redirect '/' + @page.basename
end

post '/eip/:page' do
  @page = Page.new(params[:page])
  @page.update(params[:body])
  @page.body
end

get '/h/:page' do
  @page = Page.new(params[:page])
  show :history, "History of #{@page.title}"
end

get '/h/:page/:rev' do
  @page = Page.new(params[:page], params[:rev])
  show :show, "#{@page.title} (version #{params[:rev]})"
end

get '/d/:page/:rev' do
  @page = Page.new(params[:page])
  show :delta, "Diff of #{@page.title}"
end

# application paths (/a/ namespace)

get '/a/list' do
  pages = $repo.log.first.gtree.children
  # only listing pages and stripping page_extension from url
  @pages = pages.select { |f,bl| f[0,1] != '_'}.sort.map { |name, blob| Page.new(name.strip_page_extension) } rescue []
  show(:list, 'Listing pages')
end

get '/a/patch/:page/:rev' do
  @page = Page.new(params[:page])
  header 'Content-Type' => 'text/x-diff'
  header 'Content-Disposition' => 'filename=patch.diff'
  @page.delta(params[:rev])
end

get '/a/tarball' do
  header 'Content-Type' => 'application/x-gzip'
  header 'Content-Disposition' => 'filename=archive.tgz'
  archive = $repo.archive('HEAD', nil, :format => 'tgz', :prefix => 'wiki/')
  File.open(archive).read
end

get '/a/branches' do
  @branches = $repo.branches
  show :branches, "Branches List"
end

get '/a/branch/:branch' do
  $repo.checkout(params[:branch])
  redirect '/' + HOMEPAGE
end

get '/a/history' do
  @history = $repo.log
  show :branch_history, "Branch History"
end

get '/a/revert_branch/:sha' do
  $repo.with_temp_index do
    $repo.read_tree params[:sha]
    $repo.checkout_index
    $repo.commit('reverted branch')
  end
  redirect '/a/history'
end

get '/a/merge_branch/:branch' do
  $repo.merge(params[:branch])
  redirect '/' + HOMEPAGE
end

get '/a/delete_branch/:branch' do
  $repo.branch(params[:branch]).delete
  redirect '/a/branches'
end

post '/a/new_branch' do
  $repo.branch(params[:branch]).create
  $repo.checkout(params[:branch])
  if params[:type] == 'blank'
    # clear out the branch
    $repo.chdir do
      Dir.glob("*").each do |f|
        File.unlink(f)
        $repo.remove(f)
      end
      touchfile
      $repo.commit('clean branch start')
    end
  end
  redirect '/a/branches'
end

post '/a/new_remote' do
  $repo.add_remote(params[:branch_name], params[:branch_url])
  $repo.fetch(params[:branch_name])
  redirect '/a/branches'
end

get '/a/search' do
  @search = params[:search]
  @grep = $repo.grep(@search)
  show :search, 'Search Results'
end

# file upload attachments

get '/a/file/upload/:page' do
  @page = Page.new(params[:page])
  show :attach, 'Attach File for ' + @page.title
end

post '/a/file/upload/:page' do
  @page = Page.new(params[:page])
  @page.save_file(params[:file], params[:name])
  redirect '/e/' + @page.basename
end

get '/a/file/delete/:page/:file.:ext' do
  @page = Page.new(params[:page])
  @page.delete_file(params[:file] + '.' + params[:ext])
  redirect '/e/' + @page.basename
end

get '/_:page/:file.:ext' do
  @page = Page.new(params[:page])
  send_file(File.join(@page.attach_dir, params[:file] + '.' + params[:ext]))
end

# allow subdirectories, needs to go last since using wild card
=begin

get '/e/*' do
  file = request.env["REQUEST_PATH"][3..-1] # strip off leading /e/
  @page = Page.new(file)
  show :edit, "Editing #{@page.title}"
end


# get page
get '/*' do
  file = request.env["REQUEST_PATH"][1..-1] # strip off leading /
  @page = Page.new(file)
  @page.tracked? ? show(:show, @page.title) : redirect('/e/' + @page.basename)
end

=end

# support methods

def page_url(page)
  "#{request.env["rack.url_scheme"]}://#{request.env["HTTP_HOST"]}/#{page}"
end

private

  def show(template, title)
    @title = title
    erb(template)
  end

  def touchfile
    # adds meta file to repo so we have somthing to commit initially
    $repo.chdir do
      f = File.new(".meta",  "w+")
      f.puts($repo.current_branch)
      f.close
      $repo.add('.meta')
    end
  end
