# frozen_string_literal: true
module Kasket
  class QueryParser
    # Examples:
    # SELECT * FROM `users` WHERE (`users`.`id` = 2)
    # SELECT * FROM `users` WHERE (`users`.`id` = 2) LIMIT 1
    # 'SELECT * FROM \'posts\' WHERE (\'posts\'.\'id\' = 574019247) '

    AND = /\s+AND\s+/i
    VALUE = /'?(\d+|\?|(?:(?:[^']|''|\\')*))'?/ # Matches: 123, ?, '123', '12''3'

    def initialize(model_class)
      @model_class = model_class

      @supported_query_pattern = /^select\s+((?:`|")#{@model_class.table_name}(?:`|")\.)?\* from (?:`|")#{@model_class.table_name}(?:`|") where (.*?)(|\s+limit 1)\s*$/i

      # Matches: `users`.id, `users`.`id`, users.id, id
      @table_and_column_pattern = /(?:(?:`|")?#{@model_class.table_name}(?:`|")?\.)?(?:`|")?([a-zA-Z]\w*)(?:`|")?/
      # Matches: KEY = VALUE, (KEY = VALUE), ()(KEY = VALUE))
      @key_eq_value_pattern = /^[\(\s]*#{@table_and_column_pattern}\s+(=|IN)\s+#{VALUE}[\)\s]*$/
    end

    def parse(sql)
      if match = @supported_query_pattern.match(sql)
        where = match[2]
        limit = match[3]

        query = {}
        query[:attributes] = sorted_attribute_value_pairs(where)
        return nil if query[:attributes].nil?

        if query[:attributes].size > 1 && query[:attributes].map(&:last).any? {|a| a.is_a?(Array)}
          # this is a query with IN conditions AND other conditions
          return nil
        end

        query[:index] = query[:attributes].map(&:first)
        query[:limit] = limit.blank? ? nil : 1
        query[:key] = @model_class.kasket_key_for(query[:attributes])
        query[:key] << '/first' if query[:limit] == 1 && !query[:index].include?(:id)
        query
      end
    end

    private

    def sorted_attribute_value_pairs(conditions)
      if attributes = parse_condition(conditions)
        attributes.sort { |pair1, pair2| pair1[0].to_s <=> pair2[0].to_s }
      end
    end

    def parse_condition(conditions = '', *values)
      values = values.dup
      conditions.split(AND).inject([]) do |pairs, condition|
        matched, column_name, operator, sql_value = *@key_eq_value_pattern.match(condition)
        if matched
          if operator == 'IN'
            if column_name == 'id'
              values = sql_value[1..-2].split(',').map(&:strip)
              pairs << [column_name.to_sym, values]
            else
              return nil
            end
          else
            value = sql_value == '?' ? values.shift : sql_value
            pairs << [column_name.to_sym, value.gsub(/''|\\'/, "'")]
          end
        else
          return nil
        end
      end
    end
  end
end
