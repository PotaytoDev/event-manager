require 'csv'
require 'google/apis/civicinfo_v2'

# Make any zip code into a five-digit zip code
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

puts 'Event Manager Initialized!'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])

  stdout = $stdout

  begin
    $stdout = StringIO.new

    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    )

    legislator_names = legislators.officials.map(&:name)
    legislators_string = legislator_names.join(', ')
  rescue
    legislators_string = 'You can find your representatives by ' \
    'visiting www.commoncause.org/take-action/find-elected-officials'
  ensure
    $stdout = stdout
  end

  puts "Name: #{name}, Zip Code: #{zipcode}, Legislators: #{legislators_string}"
end
