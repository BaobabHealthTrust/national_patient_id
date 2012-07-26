#!/usr/bin/ruby -w

# == NationalPatientId
# 
# Generate Unique Patient IDs
#
# === Example
#
# <tt>> id = NationalPatientId.new(20).to_s</tt>
#
# <tt>"000-06V"</tt>
#
# <tt>> id = NationalPatientId.new(123456789).to_s</tt>
#
# <tt>"1MT-4P33"</tt>
#
#

class NationalPatientId

  attr :decimal_id
  attr :value
  attr :base
  @@separator = '-'

  # we are taking out letters B, I, O, Q, S, Z because they might be
  # mistaken for 8, 1, 0, 0, 5, 2 respectively
  @@base_map = ['0','1','2','3','4','5','6','7','8','9','A','C','D','E','F','G',
                'H','J','K','L','M','N','P','R','T','U','V','W','X','Y']
              
  @@reverse_map = {'0' => 0,'1' => 1,'2' => 2,'3' => 3,'4' => 4,'5' => 5,
                   '6' => 6,'7' => 7,'8' => 8,'9' => 9,
                   'A' => 10,'C' => 11,'D' => 12,'E' => 13,'F' => 14,'G' => 15,
                   'H' => 16,'J' => 17,'K' => 18,'L' => 19,'M' => 20,'N' => 21,
                   'P' => 22,'R' => 23,'T' => 24,'U' => 25,'V' => 26,'W' => 27,
                   'X' => 28,'Y' => 29}

  # Create a National Patient ID
  #
  # <tt>num</tt> is the decimal equivalent of the Base <tt>base</tt> Id to be
  # created without the check digit
  def initialize(num, src_base = 10, base = 30)
    if num && src_base == 10
      num = num.to_i
      num = num * 10 + NationalPatientId.check_digit(num)
    end
    @decimal_id = NationalPatientId.to_decimal(num, src_base)
    @base = base
    @value = self.convert(@decimal_id).rjust(6,'0')
  end

  # @author: Mike Mckay
  # Calculate a check digit using Luhn's Algorithm as implemented in BART
  # http://en.wikipedia.org/wiki/Luhn_algorithm
  # PatientIdentifier.calculate_checkdigit
  def self.check_digit(number)
    # This is Luhn's algorithm for checksums
    # http://en.wikipedia.org/wiki/Luhn_algorithm
    # Same algorithm used by PIH (except they allow characters)
    number = number.to_s
    number = number.split(//).collect { |digit| digit.to_i }
    parity = number.length % 2

    sum = 0
    number.each_with_index do |digit,index|
      digit = digit * 2 if index%2==parity
      digit = digit - 9 if digit > 9
      sum = sum + digit
    end

    checkdigit = 0
    checkdigit = checkdigit +1 while ((sum+(checkdigit))%10)!=0
    checkdigit
  end

  # Convert a Base 10 <tt>number</tt> to the specified <tt>base</tt>
  def convert(num)
    results = ''
    quotient = num.to_i
      
    while quotient > 0 
      results = @@base_map[quotient % @base] + results
      quotient = (quotient / @base)
    end
    results
  end

  # When converting to string, print a hyphen after the third character
  def to_s
    "#{@value.slice(0,3)}#{@@separator}#{@value.slice(3,@value.length)}"
  end

  # SQL to create schema for the table to store the ids
  def self.table_sql
    "CREATE TABLE `national_patient_ids` (
        `id` int(11) NOT NULL auto_increment,
        `value` VARCHAR(8) NOT NULL,
        `decimal_id` int(11) NOT NULL DEFAULT 0,
        `location_id` int(11),
        PRIMARY KEY(id)
      ) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
  end

  # SQL to populate Ids from <tt>start_num</tt> to <tt>end_num</tt> into a table
  def self.ids_sql(start_num, end_num)
    "INSERT INTO national_patient_ids (value,decimal_id) VALUES " +
    (start_num.to_i..end_num.to_i).map{|num|
      id = NationalPatientId.new(num, 10, 30)
      "'#{id}',#{id.decimal_id})"
    }.join(',') + ';'
  end

  # Convert given <tt>num</tt> in from the specified <tt>from_base</tt> to
  # decimal (base 10)
  def self.to_decimal(num, from_base=30)
    decimal = 0
    num.to_s.gsub(@@separator, '').split('').reverse.each_with_index do |n, i|
      decimal += @@reverse_map[n] * (from_base ** i)
    end
    decimal
  end

  # Checks if <tt>num<tt> has a correct check digit
  def self.valid?(num)
    core_id = num / 10
    check_digit = num % 10 # last digit

    check_digit == NationalPatientId.check_digit(core_id)
  end

end