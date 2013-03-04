require "spec_helper"

describe PgSearch::Features::TSearch do
  describe "#tsdocument" do
    with_model :Model do
      table do |t|
        t.text :text
      end
    end

    context "when ignoring accents" do
      it "passes the columns through the unaccent function" do
        query = "hi"
        options = { against: [:text], ignoring: :accents }
        column = PgSearch::Configuration::Column.new("text", nil, Model)
        columns = [column]
        config = PgSearch::Configuration.new(options, Model)
        normalizer = PgSearch::Normalizer.new(config)

        tsearch_feature = described_class.new(query, options, columns, Model, normalizer)

        tsearch_feature.send(:tsdocument).should == <<-SQL.chomp
to_tsvector(:dictionary, unaccent(coalesce(#{Model.quoted_table_name}."text"::text, '')))
        SQL
      end
    end
  end
end
