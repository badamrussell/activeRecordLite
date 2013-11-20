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
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] || "#{name}_id".to_sym
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @other_class_name = params[:class_name] || name.to_s.singularize.camelize
    @primary_key = params[:primary_key] || :id
    @foreign_key = params[:foreign_key] ||  "#{self_class.name.underscore}_id".to_sym
  end

  def type
  end
end

module Associatable

  def assoc_params
    @assoc_params ||= {}
    @assoc_params
  end

  def belongs_to(name, params = {})
    b_asc = BelongsToAssocParams.new(name, params)
    assoc_params[name] = b_asc

    define_method(name) do
      result = DBConnection.execute(<<-SQL, self.send(b_asc.foreign_key))
          SELECT *
          FROM #{b_asc.other_table}
          WHERE #{b_asc.other_table}.#{b_asc.primary_key} = ?
          LIMIT 1
        SQL
      b_asc.other_class.parse_all(result)[0]
    end
  end

  def has_many(name, params = {})
    if params.has_key?(:through)
      mid_assoc = params[:through]
      last_assoc = params[:source]

      puts "CURRENT: #{self}"
      puts "ASSOC  : #{mid_assoc}"
      puts "ASC OBJ: #{assoc_params}"
      assoc_params
      puts send(mid_assoc)
      #puts assoc_params[mid_assoc].instance_variables
      puts "---------"
      puts assoc_params[mid_assoc].other_class_name
      puts "#{mid_assoc}  #{last_assoc}"

      define_method(name)
        results = DBConnection.execute(<<-SQL, self.send(b_asc.primary_key))
              SELECT *
              FROM #{b_asc.other_table}
              WHERE #{b_asc.other_table}.#{b_asc.foreign_key} = ?
            SQL
      end

    else
      b_asc = HasManyAssocParams.new(name, params, self.class)
      assoc_params[name] = b_asc

      define_method(name) do
        results = DBConnection.execute(<<-SQL, self.send(b_asc.primary_key))
            SELECT *
            FROM #{b_asc.other_table}
            WHERE #{b_asc.other_table}.#{b_asc.foreign_key} = ?
          SQL
        b_asc.other_class.parse_all(results)
      end
    end


  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      params1 = self.class.assoc_params[assoc1]
      params2 = params1.other_class.assoc_params[assoc2]

      self_key = self.class.assoc_params[assoc1].foreign_key

      unless (params1.nil? && params2.nil?)
        result = DBConnection.execute(<<-SQL, self.send(self_key))
            SELECT #{params2.other_table}.*
            FROM #{params2.other_table}
            JOIN #{params1.other_table}
            ON #{params2.other_table}.#{params2.primary_key} = #{params1.other_table}.#{params2.foreign_key}
            WHERE #{params1.other_table}.#{params1.primary_key} = ?
            LIMIT 1
          SQL

        params2.other_class.parse_all(result)[0]
      end
    end
  end
end