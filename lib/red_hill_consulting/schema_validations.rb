module RedHillConsulting
  module SchemaValidations
    module Base
      def inherited(child)
        super

        # Don't even bother if the table doesn't yet exist
        return unless child.table_exists?

        # NOT NULL constraints
        child.columns.reject { |column| column.primary || column.name =~ /(^(((created|updated)_(at|on))|position)|_count)$/ }.each do |column|
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

        # UNIQUE constraints
        child.columns.reject { |column| column.primary }.each do |column|
          child.validates_uniqueness_of column.name if column.unique
        end
      end
    end
  end
end
