BASE_PATH = '/var/www/dev-wiki'
APP_HOME = BASE_PATH + '/git-wiki'
SINATRA_PATH = 'sinatra/lib/sinatra' # relative to APP_HOME
APP = 'git-wiki' # relative to APP_HOME

ENV['WIKI_HOME'] = BASE_PATH + '/content' # force this so not rely on HOME

$LOAD_PATH.unshift APP_HOME
require SINATRA_PATH

Sinatra::Application.default_options.merge!(
  :raise_errors => false,
  :run => false,
  :root => APP_HOME,
  :views => APP_HOME + '/views',
  :public => APP_HOME + '/public',
  :env => :production
)

require APP
run Sinatra.application


