Rails::Plugin::Loader.new(initializer, File.join(directory, '..', 'redhillonrails_core')).load

ActiveRecord::Base.send(:include, RedHillConsulting::SchemaValidations::ActiveRecord::Base)
