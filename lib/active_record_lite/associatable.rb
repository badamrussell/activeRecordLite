require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader :other_class_name, :primary_key, :foreign_key
  def other_class
    return nil if self.other_class_name.nil?
    self.other_class_name.constantize
  end

  def other_table
    return nil if other_class.nil?
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @other_class_name = params[:class_name] || name.to_s.camelize
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{name}_id"
    #p "NAME: #{name} is a #{name.class} and #{@other_class_name}"
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @other_class_name = params[:class_name] || name.to_s.singularize.camelize
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{self_class.name.undersore}_id"
  end

  def type
  end
end

module Associatable
  def assoc_params
  end

  #  :class_name => "Cat",
#  :foreign_key => "cat_id",
#  :primary_key => "id"

  def belongs_to(name, params = {})
    #A SQLObject is going to call this
    # sets up a method <name> that generates a SQL query
    # and returns one object
    b_asc = BelongsToAssocParams.new(name, params)

    self.class_eval do
      define_method(name) do
        result = DBConnection.execute(<<-SQL)
            SELECT #{self.class.table_name}.*
            FROM #{self.class.table_name}
            JOIN #{b_asc.other_table}
            ON #{b_asc.other_table}.#{b_asc.primary_key} = #{self.class.table_name}.#{b_asc.foreign_key}
            LIMIT 1
          SQL

        b_asc.other_class.new(result[0])
      end
    end
  end

  def has_many(name, params = {})
    b_asc = HasManyAssocParams.new(name, params, self.class)

    self.class_eval do
      define_method(name) do
        results = DBConnection.execute(<<-SQL)
            SELECT #{self.class.table_name}.*
            FROM #{self.class.table_name}
            JOIN #{b_asc.other_table}
            ON #{self.class.table_name}.#{b_asc.primary_key} = #{b_asc.other_table}.#{b_asc.foreign_key}
            LIMIT 1
          SQL

          results.map { |result_hash| b_asc.other_class.new(result_hash) }
      end
    end
  end

  def has_one_through(name, assoc1, assoc2)
  end
end
