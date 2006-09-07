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
        # TODO: validates_uniqueness_of association_id ...
      end

      def inherited(child)
        super

        # Don't even bother if the table doesn't yet exist
        return unless child.table_exists?
        
        # NOT NULL constraints
        child.content_columns.reject { |column| column.name =~ /^(((created|updated)_(at|on))|position)$/ }.each do |column|
          if column.type == :integer
            child.validates_numericality_of column.name, :allow_nil => true, :only_integer => true
          elsif column.number?
            child.validates_numericality_of column.name, :allow_nil => true
          elsif column.text? && column.limit
            child.validates_length_of column.name, :allow_nil => true, :maximum => column.limit
          end
          
          if !column.null && column.default.nil?
            # Work-around for a "feature" of the way validates_presence_of handles boolean fields
            # See http://dev.rubyonrails.org/ticket/5090 and http://dev.rubyonrails.org/ticket/3334
            if column.type == :boolean
              child.validates_inclusion_of column.name, :in => [true, false], :message => ActiveRecord::Errors.default_error_messages[:blank]
            else
              child.validates_presence_of column.name
            end
          end
        end
        
        # Single-column UNIQUE indexes
        # TODO: Probably need to ignore _id columns?
        child.connection.indexes(child.table_name, "#{child.name} Indexes").each do |index|
          child.validates_uniqueness_of index.columns.first if index.unique && index.columns.size == 1
        end
      end
    end
  end
end
