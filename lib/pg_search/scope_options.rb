require "active_support/core_ext/module/delegation"

module PgSearch
  class ScopeOptions
    attr_reader :config, :feature_options

    def initialize(config)
      @config = config
      @model = config.model
      @feature_options = Hash[config.features]
    end

    def apply(scope)
      base_scope = scope.select_values.empty?

      if base_scope
        all_columns = "#{quoted_table_name}.*"

        custom_select = Module.new do
          define_method :select do |*args, &block|
            self.select_values -= [all_columns]
            super(*args, &block)
          end
        end
      end

      scope = scope.select("(#{rank}) AS pg_search_rank")
      scope = scope.select(all_columns).extend(custom_select) if base_scope
      scope = scope.where(conditions).order("pg_search_rank DESC, #{order_within_rank}").joins(joins)

      scope
    end

    private

    delegate :connection, :quoted_table_name, :sanitize_sql_array, :to => :@model

    def conditions
      config.features.map do |feature_name, feature_options|
        "(#{sanitize_sql_array(feature_for(feature_name).conditions)})"
      end.join(" OR ")
    end

    def order_within_rank
      config.order_within_rank || "#{primary_key} ASC"
    end

    def primary_key
      "#{quoted_table_name}.#{connection.quote_column_name(@model.primary_key)}"
    end

    def joins
      config.associations.map do |association|
        association.join(primary_key)
      end.join(' ')
    end

    FEATURE_CLASSES = {
      :dmetaphone => Features::DMetaphone,
      :tsearch => Features::TSearch,
      :trigram => Features::Trigram
    }

    def feature_for(feature_name)
      feature_name = feature_name.to_sym
      feature_class = FEATURE_CLASSES[feature_name]

      raise ArgumentError.new("Unknown feature: #{feature_name}") unless feature_class

      normalizer = Normalizer.new(config)

      feature_class.new(
        config.query,
        feature_options[feature_name],
        config.columns,
        config.model,
        normalizer
      )
    end

    def rank
      (config.ranking_sql || ":tsearch").gsub(/:(\w*)/) do
        sanitize_sql_array(feature_for($1).rank)
      end
    end
  end
end
