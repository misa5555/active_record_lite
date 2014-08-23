require_relative 'db_connection'
require 'active_support/inflector'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject
  def self.columns
     datas = DBConnection.execute2("SELECT * FROM #{self.table_name}")
      
     @columns = datas[0].map{|colum| colum.to_sym}   
  end

  def self.finalize!
    self.columns.each do |column|
      
      define_method "#{column}" do
        self.attributes["#{column}".to_sym] 
      end

      define_method "#{column}=" do |value|
        self.attributes["#{column}".to_sym] = value 
      end
    end  
  end

  def self.table_name=(table_name)
    @table_name = table_name  
  end

  def self.table_name
    @table_name || self.name.underscore.concat("s")
  end

  def self.all
    result = DBConnection.execute(<<-SQL) 
      SELECT #{self.table_name}.*
      FROM #{self.table_name}
    SQL
    parse_all(result)
  end

  def self.parse_all(results)
    alls = []
    results.each do |hash|
      alls << self.new(hash)
    end
    alls
  end

  def self.find(id)
    self.all.find { |obj| obj.id == id }
  end
  
  def attributes
    if @attributes.nil?
      @attributes = {}
    else
      @attributes
    end 
  end

  def insert
    col_length = self.class.columns.length
    col_names = self.class.columns.map{|c|c.to_s}.join(", ")
    question_marks = (["?"]*col_length).join(", ")
    *values = attribute_values 
    DBConnection.execute(<<-SQL, *values) 
      INSERT INTO 
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks}) 
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params={})
    params.each do |attr_name, value|
      if self.class.columns.include?(attr_name.to_sym)
        self.send("#{attr_name}=", value)
      else  
        raise "unknown attribute '#{attr_name}'"   
      end
    end 
  end

  def save
    if self.id.nil?
      insert
    else
      update
    end  
  end

  def update
    attr_names = self.class.columns.map{|column|column.to_s}
    conditions = attr_names.map{|attr_name|"#{attr_name} = ?"}.join(",")

    DBConnection.execute(<<-SQL, *attribute_values, self.id) 
      UPDATE
        #{self.class.table_name} 
      SET  
        #{conditions}
      WHERE
        id = ?
      SQL
  end

  def attribute_values
    self.class.columns.map{|column| self.send("#{column.to_sym}")} 
  end

end
