module RedHillConsulting
  module SchemaValidations
    module Base
      def inherited(child)
        super
        child.columns.each do |column|
          child.validates_presence_of column.name unless column.null
        end
      end
    end
  end
end
