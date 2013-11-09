require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
  end

  def other_table
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @other_class_name = params.other_class_name || camel_case(name)
    @primary_key = params.primary_key || "id"
    @foreign_key = params.foreign_key || "#{name}_id"
    #@other_class =
    #@other_table_name =
  end

  def type
  end

  private

  def camel_case(name)
    _index = name.index("_")
    while _index
      name = name[0..._index] + name[_index+1].upcase + name[_index+2..-1]
      _index = name.index("_")
    end
    name
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
  end

  def type
  end
end

module Associatable
  def assoc_params
  end

  def belongs_to(name, params = {})
    #A SQLObject is going to call this
    # sets up a method <name> that generates a SQL query
    # and returns one object
    puts "BELONG TO..."
    BelongsToAssocParams.new(name, params)

    self.parse_all()
  end

  def has_many(name, params = {})
  end

  def has_one_through(name, assoc1, assoc2)
  end
end
