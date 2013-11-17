class MassObject
  # takes a list of attributes.
  # creates getters and setters.
  # adds attributes to whitelist.
  def self.my_attr_accessor(*attributes)
    attributes.each do |attr_name|
      self.class_eval do
        define_method(attr_name) do
          self.instance_variable_get("@#{attr_name.to_s}")
        end

        define_method(attr_name.to_s + "=") do |other_value|
          self.instance_variable_set("@#{attr_name.to_s}", other_value)
        end
      end
    end
  end

  def self.my_attr_accessible(*attributes)
    @attributes = []

    attributes.each do |attr_name|
      @attributes << attr_name
    end
    my_attr_accessor(*attributes)
  end

  # returns list of attributes that have been whitelisted.
  def self.attributes
    @attributes
  end

  # takes an array of hashes.
  # returns array of objects.
  def self.parse_all(results)
    results.map { |options| self.new(options) }
  end

  # takes a hash of { attr_name => attr_val }.
  # checks the whitelist.
  # if the key (attr_name) is in the whitelist, the value (attr_val)
  # is assigned to the instance variable.
  def initialize(params = {})
    params.each do |attr_name, value|
      if self.class.attributes.include?(attr_name.to_sym)
        self.instance_variable_set("@#{attr_name.to_s}", value)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end
    end
  end

  protected
end