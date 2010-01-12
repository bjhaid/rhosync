require File.join(File.dirname(__FILE__),'..','spec_helper')
$:.unshift File.join(__FILE__,'..','..','lib')
require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'
require 'rhosync_store'
include RhosyncStore

set :environment, :test
set :run, false
set :secret, 'secure!'

require File.join(File.dirname(__FILE__),'..','..','rhosync.rb')

describe "ApiHelper", :shared => true do
  include Rack::Test::Methods
  
  it_should_behave_like "SourceAdapterHelper"
  
  def app
    @app ||= Sinatra::Application
  end
  
  before(:each) do
    @appname = @a_fields[:name]
    basedir = File.join(File.dirname(__FILE__),'..','..')
    RhosyncStore.bootstrap(File.join(basedir,'apps'),File.join(basedir,'data'))
    @api_token = User.with_key('admin').token_id
  end
  
  after(:each) do
    FileUtils.rm_rf File.join(File.dirname(__FILE__),'..','..','apps')
  end
end

def upload_test_apps
  file = File.join(File.dirname(__FILE__),'..','apps',@appname)
  compress(file)
  zipfile = File.join(file,"#{@appname}.zip")
  post "/api/import_app", :app_name => @appname, :api_token => @api_token, 
    :upload_file => Rack::Test::UploadedFile.new(zipfile, "application/octet-stream")
  FileUtils.rm zipfile
end

def compress(path)
  path.sub!(%r[/$],'')
  archive = File.join(path,File.basename(path))+'.zip'
  FileUtils.rm archive, :force=>true
  Zip::ZipFile.open(archive, 'w') do |zipfile|
    Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|
      zipfile.add(file.sub(path+'/',''),file)
    end
  end
end
