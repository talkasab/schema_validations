module RedHillConsulting
  module SchemaValidations
    module Base
      def inherited(child)
        super
        child.content_columns.reject { |column| column.name =~ /(_at|_on)$/ }.each do |column|
          child.validates_presence_of column.name unless column.null
        end
      end
    end
  end
end
