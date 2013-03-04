require "spec_helper"

describe PgSearch::Features::Trigram do
  describe "#conditions" do
    with_model :Model do
      table do |t|
        t.text :text
      end
    end

    it "generates conditions SQL" do
      query = "hi"
      options = { against: [:text] }
      column = PgSearch::Configuration::Column.new("text", nil, Model)
      columns = [column]
      config = PgSearch::Configuration.new(options, Model)
      normalizer = PgSearch::Normalizer.new(config)

      trigram_feature = described_class.new(query, options, columns, Model, normalizer)

      trigram_feature.conditions.to_sql.should == <<-SQL.chomp
coalesce(#{Model.quoted_table_name}."text"::text, '') % 'hi'
      SQL
    end

    context "with normalization" do
      it "generates conditions SQL" do
        query = "hi"
        options = { against: [:text], ignoring: :accents }
        column = PgSearch::Configuration::Column.new("text", nil, Model)
        columns = [column]
        config = PgSearch::Configuration.new(options, Model)
        normalizer = PgSearch::Normalizer.new(config)

        trigram_feature = described_class.new(query, options, columns, Model, normalizer)

        trigram_feature.conditions.to_sql.should == <<-SQL.chomp
unaccent(coalesce(#{Model.quoted_table_name}."text"::text, '')) % unaccent('hi')
        SQL
      end
    end
  end
end
