module RedHillConsulting
  module SchemaValidations
    module Base
      def inherited(child)
        super
        child.content_columns.reject { |column| column.name =~ /(_at|_on)$/ }.each do |column|
          if column.klass == Fixnum
            child.validates_numericality_of column.name, :allow_nil => true, :only_integer => true
          elsif column.number?
            child.validates_numericality_of column.name, :allow_nil => true
          elsif column.klass == String && column.limit
            child.validates_length_of column.name, :allow_nil => true, :maximum => column.limit
          end

          child.validates_presence_of column.name if !column.null && column.default.nil?
        end
      end
    end
  end
end
