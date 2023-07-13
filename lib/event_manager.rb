# Autor: Manuel Reyes Alcalá

# frozen_string_literal: false

require 'csv'
require 'google/apis/civicinfo_v2'
require 'googleauth'
require 'erb'

puts 'Event manager initialized'

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
    drive.representative_info_by_address(
      # This sintax is for an array of words
      address: zipcode, levels: 'country', roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError => e
    "#{e}. You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone_number)
  phone_number.delete!('-. ()') # making the strings look the same
  if phone_number.length >= 10
    phone_number.slice!(0) if phone_number.length == 11 && phone_number[0] == '1'
    phone_number
  else
    'Invalid phone number'
  end
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_numbers(row[5])
  puts phone_number

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end
