module RedHillConsulting
  module SchemaValidations
    module Base
      def inherited(child)
        super
        child.content_columns.reject { |column| column.name =~ /(_at|_on)$/ }.each do |column|
          if column.klass == Fixnum
            child.validates_numericality_of column.name, :allow_nil => column.null, :only_integer => true
          elsif column.number?
            child.validates_numericality_of column.name, :allow_nil => column.null
          elsif column.class == String and column.limit
            child.validates_length_of column.name, :allow_nil => column.null, :maximum => column.limit
          elsif !column.null
            child.validates_presence_of column.name
          end
        end
      end
    end
  end
end
