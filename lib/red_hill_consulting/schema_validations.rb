module RedHillConsulting
  module SchemaValidations
    module Base
      def self.extended(base)
        class << base
          alias_method :belongs_to_without_schema_validations, :belongs_to unless method_defined?(:belongs_to_without_schema_validations)
          alias_method :belongs_to, :belongs_to_with_schema_validations
        end
      end

      def belongs_to_with_schema_validations(association_id, options = {})
        belongs_to_without_schema_validations(association_id, options)
        validates_presence_of association_id unless columns_hash[reflections[association_id.to_sym].primary_key_name.to_s].null
      end

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
