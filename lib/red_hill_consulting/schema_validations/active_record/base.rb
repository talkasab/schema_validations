module RedHillConsulting::SchemaValidations::ActiveRecord
  module Base
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def self.extended(base)
        class << base
          alias_method_chain :belongs_to, :schema_validations
        end
      end

      def belongs_to_with_schema_validations(association_id, options = {})
        belongs_to_without_schema_validations(association_id, options)

        column = columns_hash[reflections[association_id.to_sym].primary_key_name.to_s]

        # NOT NULL constraints
        module_eval(
          "validates_presence_of column.name, :on => :#{column.required_on}, :if => lambda { |record| record.#{association_id}.nil? }"
        ) if column.required_on

        # UNIQUE constraints
        validates_uniqueness_of column.name, :scope => column.unique_scope, :allow_nil => true if column.unique
      end

      def inherited(child)
        super

        # Don't even bother if: the class is abstract; not a base class; or the table doesn't exist
        return if child.abstract_class? || !child.base_class? || child.name.blank? || !child.table_exists?

        child.content_columns.reject { |column| column.name =~ /^(((created|updated)_(at|on))|position)$/ }.each do |column|
          # Data-type validation
          if column.type == :integer
            child.validates_numericality_of column.name, :allow_nil => true, :only_integer => true
          elsif column.number?
            child.validates_numericality_of column.name, :allow_nil => true
          elsif column.text? && column.limit
            child.validates_length_of column.name, :allow_nil => true, :maximum => column.limit
          end

          # NOT NULL constraints
          if column.required_on
            # Work-around for a "feature" of the way validates_presence_of handles boolean fields
            # See http://dev.rubyonrails.org/ticket/5090 and http://dev.rubyonrails.org/ticket/3334
            if column.type == :boolean
              child.validates_inclusion_of column.name, :on => column.required_on, :in => [true, false], :message => ActiveRecord::Errors.default_error_messages[:blank]
            else
              child.validates_presence_of column.name, :on => column.required_on
            end
          end

          # UNIQUE constraints
          child.validates_uniqueness_of column.name, :scope => column.unique_scope, :allow_nil => true if column.unique
        end
      end
    end
  end
end
