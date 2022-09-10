require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

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

def find_peak_registration_hours(registrations_at_each_hour)
  # Sort number of registrations per hour from highest to lowest
  registrations_at_each_hour = registrations_at_each_hour.sort_by { |_key, value| value }.reverse.to_h

  peak_registration_hour = registrations_at_each_hour.values[0]
  peak_hours = registrations_at_each_hour.select { |_key, value| value == peak_registration_hour }
  peak_hours.sort_by { |key, _value| key }.to_h
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

registrations_at_each_hour = Hash.new(0)
registrations_at_each_day = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  # legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_number(row[:homephone])
  registration_date_and_time = Time.strptime(row[:regdate], '%m/%d/%y %k:%M')

  registrations_at_each_hour[registration_date_and_time.strftime('%l %p').strip] += 1

  puts '-----------'
  puts "Name: #{name}"
  puts "Phone Number: #{phone_number}"
  puts "Registered at: #{registration_date_and_time.strftime('%I:%M %p')} on " \
       "#{registration_date_and_time.strftime('%A')}"

  # personal_letter = erb_template.result(binding)

  # save_thank_you_letter(id, personal_letter)
end

peak_hours = find_peak_registration_hours(registrations_at_each_hour)

puts "\n\nThe peak registration hours are:"
puts peak_hours.keys.join(', ')
puts "With #{peak_hours.values.first} registrations each."
