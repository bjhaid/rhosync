require 'rubygems'
require 'redis'
require 'json'
require 'base64'
require 'zip/zip'
require 'rhosync_store/document'
require 'rhosync_store/model'
require 'rhosync_store/source'
require 'rhosync_store/user'
require 'rhosync_store/api_token'
require 'rhosync_store/app'
require 'rhosync_store/store'
require 'rhosync_store/client'
require 'rhosync_store/client_sync'
require 'rhosync_store/source_adapter'
require 'rhosync_store/source_sync'
require 'rhosync_store/bulk_data'
  
# Various module utilities for the store
module RhosyncStore
  class InvalidArgumentError < RuntimeError; end
  
  class RhosyncServerError < RuntimeError; end
  
  VERSION = '1.5.0'
  
  class << self
    attr_accessor :app_directory, :data_directory
  end

  # Server hook to initialize RhosyncStore
  def bootstrap(appdir,datadir)
    Store.create
    RhosyncStore.app_directory = appdir
    RhosyncStore.data_directory = datadir
    # Add appdir and sources subdirectory
    # to load path if appdir exists
    if File.exist?(appdir)
      Dir.entries(appdir).each do |dir|
        unless dir == '..' || dir == '.'
          set_load_path(File.join(appdir,dir))
        end
      end
    end
    create_admin_user
  end
  
  # Generate admin user on first load
  def create_admin_user
    unless User.is_exist?('admin')
      admin = User.create({:login => 'admin', :admin => 1})
      admin.password = ''
      admin.create_token
    end
  end
  
  # Sets up load path with ruby source for apps, sources, and vendor gems
  def set_load_path(appdir)
    check_and_add(appdir)
    check_and_add(File.join(appdir,'sources'))
    Dir["#{appdir}/vendor/*"].each do |dir|
      check_and_add(File.join(dir,'lib'))
    end
  end
  
  # Add path to load_path unless it has been added already
  def check_and_add(path)
    $:.unshift path unless $:.include?(path) 
  end
  
  # Serializes oav to set element
  def setelement(obj,attrib,value)
    "#{obj}:#{attrib}:#{Base64.encode64(value.to_s)}"
  end
  
  # De-serializes oav from set element
  def getelement(element)
    res = element.split(':')
    [res[0], res[1], Base64.decode64(res[2].to_s)]
  end
  
  # Generates new token (64-bit integer) based on # of 
  # microseconds since Jan 1 2009
  def get_token
    ((Time.now.to_f - Time.mktime(2009,"jan",1,0,0,0,0).to_f) * 10**6).to_i
  end
  
  # Computes token for a single client request
  def compute_token(doc_key)
    token = get_token
    Store.put_value(doc_key,token)
    token.to_s
  end
  
  # Returns require-friendly filename for a class
  def underscore(camel_cased_word)
    camel_cased_word.to_s.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
  
  # Taken from rails inflector
  def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end
  end
  
  def check_default_secret!
    if Sinatra::Application.secret == '<changeme>'                        
      Logger.error "*"*60
      Logger.error ""
      Logger.error "WARNING: Change the session secret in config.ru from <changeme> to something secure."
      Logger.error "  i.e. running `rake secret` in a rails app will generate a secret you could use."
      Logger.error ""
      Logger.error "*"*60
    end
  end
  
  
  def unzip_file(file_dir,params)
    uploaded_file = File.join(file_dir, params[:filename])
    File.open(uploaded_file, 'wb') do |file|
      file.write(params[:tempfile].read)
    end
    Zip::ZipFile.open(uploaded_file) do |zip_file|
      zip_file.each do |f|
        f_path = File.join(file_dir,f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path)
      end
    end
    FileUtils.rm_f(uploaded_file)
  end
    
  # TODO: replace with real logger
  class Logger
    @@enabled = true
    
    class << self
      attr_accessor :enabled
      
      def info(*args)
        puts args.join unless args.nil? or @@enabled == false
      end
    
      def error(*args)
        puts args.join unless args.nil? or @@enabled == false
      end
    end
  end
end


