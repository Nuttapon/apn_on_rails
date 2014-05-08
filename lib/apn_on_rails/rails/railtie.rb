if defined?(::Rails::Railtie) # backwards compatible

module Apn
  module Rails
    
    class Railtie < ::Rails::Railtie
      rake_tasks do
        Dir[File.join(File.dirname(__FILE__),'..', 'tasks/*.rake')].each { |f| load f }
      end
    end
    
  end
end

end
