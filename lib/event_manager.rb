require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

# Make any zip code into a five-digit zip code
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  stdout = $stdout

  begin
    $stdout = StringIO.new

    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by ' \
    'visiting www.commoncause.org/take-action/find-elected-officials'
  ensure
    $stdout = stdout
  end
end

def save_thank_you_letter(id, personal_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts personal_letter
  end
end

def clean_phone_number(phone_number)
  phone_number = phone_number.split(/\D/).join

  phone_number = phone_number[1..] if phone_number.length == 11 && phone_number[0] == '1'

  if phone_number.length == 10
    "(#{phone_number[0..2]}) #{phone_number[3..5]}-#{phone_number[6..]}"
  else
    'Invalid phone number'
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  # legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])

  puts '-----------'
  puts "Name: #{name}"
  puts "Phone Number: #{phone_number}"

  # personal_letter = erb_template.result(binding)

  # save_thank_you_letter(id, personal_letter)
end
