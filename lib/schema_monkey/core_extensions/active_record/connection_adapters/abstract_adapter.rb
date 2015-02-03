module SchemaMonkey::CoreExtensions
  module ActiveRecord
    module ConnectionAdapters
      module AbstractAdapter
        def self.included(base) #:nodoc:
          base.alias_method_chain :initialize, :schema_monkey
        end

        def initialize_with_schema_monkey(*args) #:nodoc:
          initialize_without_schema_monkey(*args)

          dbm = case adapter_name
                when /^MySQL/i                 then :Mysql
                when 'PostgreSQL', 'PostGIS'   then :PostgreSQL
                when 'SQLite'                  then :SQLite3
                end

          SchemaMonkey.insert(dbm: dbm)
        end

        module SchemaCreation
          def self.included(base)
            base.class_eval do
              alias_method_chain :add_column_options!, :schema_monkey
              public :options_include_default?
            end
          end

          def add_column_options_with_schema_monkey!(sql, options)
            SchemaMonkey::Middleware::Migration::ColumnOptionsSql.start(caller: self, connection: self.instance_variable_get('@conn'), sql: sql, options: options) { |env|
              add_column_options_without_schema_monkey! env.sql, env.options
            }.sql
          end
        end
      end
    end
  end
end