#!/usr/bin/ruby -w

# ==================================================================================
# Version 1.0.0
# ==================================================================================
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
# ==================================================================================
# Version 2.0.0 Onwards
# ==================================================================================
# == NationalPatientId
#
# Generate Unique Patient IDs
#
# === Example
#
# <tt>> id = NationalPatientId.new(20).to_s</tt>
#
# <tt>"000-0000M1"</tt>
#
# <tt>> id = NationalPatientId.new(123456789).to_s</tt>
#
# <tt>"005-2DF699"</tt>
#
#

=begin

JAVASCRIPT VALIDATION LOGIC:

function luhnCheckDigit(number) {
  var validChars = "0123456789ACDEFGHJKLMNPRTUVWXY";
  number = number.toUpperCase().trim();
  var sum = 0;
  for (var i = 0; i < number.length; i++) {
    var ch = number.charAt(number.length - i - 1);
    if (validChars.indexOf(ch) < 0) {
      alert("Invalid character(s) found!");
      return false;
    }
    var digit = ch.charCodeAt(0) - 48;
    var weight;
    if (i % 2 == 0) {
      weight = (2 * digit) - parseInt(digit / 5) * 9;
    }
    else {
      weight = digit;
    }
    sum += weight;
  }
  sum = Math.abs(sum) + 10;
  var digit = (10 - (sum % 10)) % 10;
  return digit;
}

=end

require "logger"

class NationalPatientId

  attr :decimal_id
  attr :value
  attr :base
  @@separator = '-'
  @@CHECK_DIGIT_VER = 2

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
  def initialize(num, size = 6, check_digit_source = true, src_base = 10,
                 base = 30)
    if num && src_base == 10
      num = num.to_i

      if check_digit_source

        num = num * 10 + NationalPatientId.check_digitV1(num)

      end
    end
    @decimal_id = NationalPatientId.to_decimal(num, src_base)
    @base = base

    if !check_digit_source

      @value = self.convert(@decimal_id).rjust(size-1,'0')
      
      if @@CHECK_DIGIT_VER == 2
        @value = "#{@value}#{NationalPatientId.check_digitV2(@value)}"
      elsif @@CHECK_DIGIT_VER == 3
        @value = "#{@value}#{NationalPatientId.check_digitV3(@value)}"
      end
    else

      @value = self.convert(@decimal_id).rjust(size,'0')

    end

    @value
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
          id = NationalPatientId.new(num, 6, true, 10, 30)
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

  # Version of check digit which determines the algorithm to be use
  def self.check_digit_ver
    @@CHECK_DIGIT_VER
  end
  
  # @author: Mike Mckay
  # Calculate a check digit using Luhn's Algorithm as implemented in BART
  # http://en.wikipedia.org/wiki/Luhn_algorithm
  # PatientIdentifier.calculate_checkdigit
  def self.check_digitV1(number)
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

    # checkdigit = 0
    # checkdigit = checkdigit +1 while ((sum+(checkdigit))%10)!=0

    checkdigit = (sum * 9) % 10

    checkdigit
  end

  def self.check_digitV2(id)

    id = id.to_s.strip.gsub(/\s/, "").gsub(/\-/, "")

    number = id.to_s.strip.upcase

    sum = 0

    ( 0..(number.length - 1) ).reverse_each do |i|

      ch = number[i]

      raise "Invalid character(s) found!" and return if !@@base_map.include?(ch)

      digit = ch.ord - 48

      weight = 0

      if i % 2 == 0

        weight = (2 * digit) - ((digit / 5).to_i * 9)

      else

        weight = digit

      end

      sum += weight

    end

    sum = sum.abs + 10

    digit = (10 - (sum % 10)) % 10

    digit

  end

  # This is Luhn Mod N algorithm for checksums
  # http://en.wikipedia.org/wiki/Luhn_mod_N_algorithm
  def self.check_digitV3(number)
    
    factor = 2
    sum = 0
    n = @@base_map.length;
    input = number.to_s.scan(/./)

    # Starting from the right and working leftwards is easier since 
    # the initial "factor" will always be "2" 
    input.reverse.each do |i|
      code_point = @@reverse_map[i]
      addend = factor * code_point
      
      # Alternate the "factor" that each "code_point" is multiplied by
      factor = (factor == 2) ? 1 : 2
      
      # Sum the digits of the "addend" as expressed in base "n"
      addend = (addend / n) + (addend % n)
      sum += addend
    end

    # Calculate the number that must be added to the "sum" 
    # to make it divisible by "n"
    remainder = sum % n
    check_code_point = (n - remainder) % n

    @@base_map[check_code_point]
  end


  # Checks if <tt>num<tt> has a correct check digit
  def self.valid?(num)
    core_id = num / 10
    check_digit = num % 10 # last digit

    check_digit == NationalPatientId.check_digitV1(core_id)
  end

  # Checks if <tt>id<tt> has a correct v2 check digit
  def self.v2valid?(id)

    id = id.to_s.strip.gsub(/\s/, "").gsub(/\-/, "")

    core_id = id.to_s.strip[0, (id.to_s.strip.length - 1)]

    check_digit = id.to_s.strip[(id.to_s.strip.length - 1), (id.to_s.strip.length)].to_i

    check_digit == NationalPatientId.check_digitV2(core_id)

  end
  
  # Checks if <tt>id<tt> has a correct v3 check digit
  def self.v3valid?(id)

    id = id.to_s.strip.gsub(/\s/, "").gsub(/\-/, "")
    core_id = id.to_s.strip[0, (id.to_s.strip.length - 1)]
    check_digit = id.to_s.strip[(id.to_s.strip.length - 1), (id.to_s.strip.length)].to_i
    
    check_digit == NationalPatientId.check_digitV3(core_id)
  end

  def self.couch_table

    "require 'couchrest_model'

    class Npid < CouchRest::Model::Base

      def incremental_id=(value)
        self['_id']=value.to_s
      end

      def incremental_id
          self['_id']
      end

      property :national_id, String
      property :site_code, String
      property :assigned, TrueClass, :default => false
      property :region, String

      timestamps!

      design do
        view :by__id
        view :by_national_id
        view :by_site_code
        view :by_site_code_and_assigned
        view :by_assigned
      end

    end
  "

  end

  def self.couch_ids_json(start_num, end_num, shuffle = true, size = 8, file_limit = 300000)

    if shuffle

      Dir.mkdir("./tmp") if !File.exist?("./tmp")

      folder = "./tmp/#{Time.now.strftime("%Y%m%d%H%M%S")}_#{start_num}_#{end_num}"

      Dir.mkdir(folder) if !File.exist?(folder)

      file_number = 0

      docs = "{\"docs\":[\n"

      lines = 0

      logger = Logger.new File.open("#{folder}/log.log", "w+")

      j = start_num.to_i

      (start_num.to_i..end_num.to_i).map{|i| i}.shuffle.each{|n|

        npid = NationalPatientId.new(n, size, false).to_s.gsub(/\-/, "")

        docs += "{\"_id\":\"#{j}\",\"national_id\":\"#{npid}\", \"type\":\"Npid\",\"created_at\":\"#{Time.now}\",\"assigned\":#{false}}"

        logger.info "Adding #{npid}"

        j += 1

        lines += 1

        if lines == file_limit - 1 or j == end_num.to_i - 1

          file_number += 1

          docs += "\n]}"

          file = File.open("#{folder}/#{"%06d" % file_number}.json", "w+")

          file.write(docs)

          file.close

          logger.info "Saving file #{"%06d" % file_number}.json"

          docs = "{\"docs\":[\n"

          lines = 0

        else

          docs += ",\n"

        end

      }

      docs = ""

    else

      Dir.mkdir("./tmp") if !File.exist?("./tmp")

      folder = "./tmp/#{Time.now.strftime("%Y%m%d%H%M%S")}_#{start_num}_#{end_num}"

      Dir.mkdir(folder) if !File.exist?(folder)

      file_number = 0

      docs = "{\"docs\":[\n"

      lines = 0

      logger = Logger.new File.open("#{folder}/log.log", "w+")

      j = start_num.to_i

      (start_num.to_i..end_num.to_i).each{|n|

        npid = NationalPatientId.new(n, size, false).to_s.gsub(/\-/, "")

        docs += "{\"_id\":\"#{j}\",\"national_id\":\"#{npid}\", \"type\":\"Npid\",\"created_at\":\"#{Time.now}\",\"assigned\":false}"

        logger.info "Adding #{npid}"

        j += 1

        lines += 1

        if lines == file_limit - 1 or j == end_num.to_i - 1

          file_number += 1

          docs += "\n]}"

          file = File.open("#{folder}/#{"%06d" % file_number}.json", "w+")

          file.write(docs)

          file.close

          logger.info "Saving file #{"%06d" % file_number}.json"

          docs = "{\"docs\":[\n"

          lines = 0

        else

          docs += ",\n"

        end

      }

      docs = ""

    end

  end

end
