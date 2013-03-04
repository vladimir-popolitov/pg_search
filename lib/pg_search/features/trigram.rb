module PgSearch
  module Features
    class Trigram < Feature
      delegate :connection, to: :model
      delegate :quote, to: :connection

      def conditions
        left = normalize(document)
        right = normalize(quote(query))

        Arel::Nodes::InfixOperation.new("%", left, right)
      end

      def rank
        [
          "similarity((#{normalize(document)}), #{normalize(":query")})",
          {:query => query}
        ]
      end
    end
  end
end
