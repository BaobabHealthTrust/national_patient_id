#!/usr/bin/ruby -w

# Generates National Patient IDs and creates and the SQL script to load them
# into a database

require 'national_patient_id'

def print_usage
  puts "Usage: dumpids.rb <start-number> <end-number> "
  puts "  e.g. dumpids.rb 3000000 3010000 > /tmp/ids.sql"
end


unless ARGV.length == 2
  print_usage
  exit
end

start_num = ARGV[0]
end_num = ARGV[1]


puts NationalPatientId.table_sql
puts NationalPatientId.ids_sql(start_num, end_num)
