class Application < Rhosync::Base
  class << self
    def authenticate(username,password,session)
      true # do some interesting authentication here...
    end
    
    # Add hooks for application startup here
    # Don't forget to call super at the end!
    def initializer(path)
      super
    end
  end
end

Application.initializer(ROOT_PATH)