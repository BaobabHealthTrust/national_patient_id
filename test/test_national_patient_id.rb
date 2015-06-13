#!/usr/bin/ruby -w
#
# Tests for NationalPatientId
#

require 'test/unit'
require 'lib/national_patient_id'


class TestNationalPatientId < Test::Unit::TestCase

  NUM = 24300000
  def setup
    @id = NationalPatientId.new(NUM)
  end

  def test_create
    assert_equal "A00006",  @id.value
    assert_equal NUM*10 + NationalPatientId.check_digitV1(NUM), @id.decimal_id


    assert_equal "0005HU",  NationalPatientId.new(500).value

    assert_equal '00000M',  NationalPatientId.new('M',6,true,30,30).value
    assert_equal '8A08A8',  NationalPatientId.new('8A08A8',6,true,30).value

    assert_equal '000000', NationalPatientId.new(nil).value
    assert_equal '000000', NationalPatientId.new('').value
  end

  def test_to_s
    assert_equal "A00-006", @id.to_s
    assert_equal "000-06V", NationalPatientId.new(20).to_s
  end

  def test_table_sql
    assert_match(/^CREATE TABLE `national_patient_ids`/,
      NationalPatientId.table_sql)
  end

  def test_ids_sql
    assert_match(
      /^INSERT INTO national_patient_ids \(value,decimal_id\) VALUES/,
      NationalPatientId.ids_sql(1,20))
  end

  def test_to_decimal
    assert_equal(NUM*10 + NationalPatientId.check_digitV1(NUM),
                 NationalPatientId.to_decimal(@id.value))
    assert_equal(20, NationalPatientId.to_decimal('000-00M'))
    assert_equal(50, NationalPatientId.to_decimal('1M'))
    assert_equal(500, NationalPatientId.to_decimal('HM'))
    assert_equal(5000, NationalPatientId.to_decimal('5HM'))

    assert_equal(20, NationalPatientId.to_decimal('M', 30))
    assert_equal(20, NationalPatientId.to_decimal('M', 30))
  end

  def test_valid
    assert_equal false, NationalPatientId.valid?(840848)
    assert NationalPatientId.valid?(8408485)
  end
end
