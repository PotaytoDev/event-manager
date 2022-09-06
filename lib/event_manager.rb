require 'csv'
require 'google/apis/civicinfo_v2'

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

    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    )

    legislator_names = legislators.officials.map(&:name)
    legislator_names.join(', ')
  rescue
    'You can find your representatives by ' \
    'visiting www.commoncause.org/take-action/find-elected-officials'
  ensure
    $stdout = stdout
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  puts "Name: #{name}, Zip Code: #{zipcode}, Legislators: #{legislators}"
end
