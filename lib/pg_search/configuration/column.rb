require 'digest'

module PgSearch
  class Configuration
    class Column
      attr_reader :weight

      def initialize(column_name, weight, model)
        @column_name = column_name.to_s
        @weight = weight
        @model = model
        @connection = model.connection
      end

      def full_name
        "#{table_name}.#{column_name}"
      end

      def to_sql
        "coalesce(#{expression}::text, '')"
      end

      private

      def table_name
        @model.quoted_table_name
      end

      def column_name
        if @column_name =~ /to_tsvector/
          @column_name
        else
          @connection.quote_column_name(@column_name)
        end
      end

      def expression
        full_name
      end
    end
  end
end
