# Autor: Manuel Reyes Alcalá

# frozen_string_literal: false

require 'csv'
require 'google/apis/civicinfo_v2'
require 'googleauth'

puts 'Event manager initialized'



contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

def clean_zipcode(zipcode)
  # fix the zip codes
  # zip code null: to_s = ''
  # zip codes < 5: add zeros until 5
  # zip codes > 5: truncate to the firsts 5
  zipcode.to_s.rjust(5, '0')[0..4] # returning the fixed zip code
end

def legislators_by_zipcode(zipcode)
  drive = Google::Apis::CivicinfoV2::CivicInfoService.new
  drive.key = ENV['GOOGLE_API_KEY']
  begin
    legislators = drive.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]) # This sintax is for an array of words
    legislators.officials.map(&:name).join(', ')
  rescue 
    'you can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

template_letter = File.read('form_letter.html')
contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  puts "#{name} #{zipcode}, #{legislators = legislators_by_zipcode(zipcode)}\n\n"

  personal_letter = template_letter.gsub('FIRST_NAME', name)
  personal_letter.gsub!('LEGISLATORS', legislators)

  puts personal_letter
end
