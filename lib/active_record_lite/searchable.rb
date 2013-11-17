require_relative './db_connection'

module Searchable
  def where(params)
    where_clause = params.keys.map { |key| "#{key} = ?" }

    result = DBConnection.execute(<<-SQL, *params.values)
      SELECT *
      FROM #{self.table_name}
      WHERE #{where_clause.join(" AND ")}
    SQL

    result.map { |options| self.new(options) }
  end
end