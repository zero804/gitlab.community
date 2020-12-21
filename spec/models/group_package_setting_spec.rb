# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupPackageSetting do
  describe 'relationships' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }

    describe '#maven_duplicates_allowed' do
      it { is_expected.to allow_value(true).for(:maven_duplicates_allowed) }
      it { is_expected.to allow_value(false).for(:maven_duplicates_allowed) }
      it { is_expected.not_to allow_value(nil).for(:maven_duplicates_allowed) }
    end

    describe '#maven_duplicate_exception_regex' do
      let_it_be(:group_package_setting) { create(:group_package_setting) }

      subject { group_package_setting }

      valid_regexps = %w[SNAPSHOT .* v.+ v10.1.* (?:v.+|SNAPSHOT|TEMP)]
      invalid_regexps = ['[', '(?:v.+|SNAPSHOT|TEMP']

      valid_regexps.each do |valid_regexp|
        it { is_expected.to allow_value(valid_regexp).for(:maven_duplicate_exception_regex) }
      end

      invalid_regexps.each do |invalid_regexp|
        it { is_expected.not_to allow_value(invalid_regexp).for(:maven_duplicate_exception_regex) }
      end
    end
  end
end
