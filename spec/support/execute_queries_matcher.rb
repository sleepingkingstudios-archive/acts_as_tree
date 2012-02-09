# spec/support/execute_queries_matcher.rb

module SleepingKingStudios
  module RSpec
    module Matchers
      module ExecuteQueries
        # QueryCounter thanks to Ryan Bigg on StackOverflow
        #   http://stackoverflow.com/users/15245/ryan-bigg
        class QueryCounter
          cattr_accessor :query_count do 0 end

          IGNORED_SQL = [/^PRAGMA (?!(table_info))/, /^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/, /^SELECT @@ROWCOUNT/, /^SAVEPOINT/, /^ROLLBACK TO SAVEPOINT/, /^RELEASE SAVEPOINT/, /^SHOW max_identifier_length/]

          def call(name, start, finish, message_id, values)
            # FIXME: this seems bad. we should probably have a better way to indicate
            # the query was cached
            unless 'CACHE' == values[:name]
              self.class.query_count += 1 unless IGNORED_SQL.any? { |r| values[:sql] =~ r }
            end # unless
          end # method call
        end # class QueryCounter
        ActiveSupport::Notifications.subscribe('sql.active_record', QueryCounter.new)
        
        class ExecuteQueriesMatcher
          def initialize(count = nil, &block)
            @count, @block = count, block
          end # constructor initialize
          
          def matches?(expected)
            QueryCounter.query_count = 0
            expected.call
            @actual = QueryCounter.query_count
            @count.nil? ? @actual > 0 : @actual == @count
          end # method matches?
          
          def failure_message_for_should
            "expected #{@count.nil? ? "one or more" : @count} SQL queries, observed #{@actual}"
          end # method failure_message_for_should
          
          def failure_message_for_should_not
            "expected #{@count.nil? ? "zero" : "other than #{@count}"} SQL queries, observed #{@actual}"
          end # method failure_message_for_should
        end # class ExecuteQueriesMatcher
        
        def execute_queries(count = nil)
          ExecuteQueriesMatcher.new count
        end # matcher execute_queries
      end # module ExecuteQueries
    end # module Matchers
  end # module RSpec
end # module SleepingKingStudios

RSpec::configure do |config|
  config.include(SleepingKingStudios::RSpec::Matchers::ExecuteQueries)
end # configure
