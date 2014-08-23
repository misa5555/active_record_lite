require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    
    where_line = params.keys.map{|key| "#{key.to_s} = ?"}.join(" AND ")
    p where_line + "87878787878787878"
    DBConnection.execute(<<-SQL, *values)
      SELECT
        *
      FROM  
        #{table_name} 
      WHERE
        #{where_line}
    SQL
  end
end

class SQLObject
  extend Searchable
end
