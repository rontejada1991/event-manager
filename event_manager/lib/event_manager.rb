require "csv"
require 'sunlight/congress'
require 'erb'
require 'date'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def parse_regdate(regdate, time)
  regdate = DateTime.strptime(regdate, "%m/%d/%y %H:%M")

  case time
  when "hour" then regdate.hour
  when "wday" then regdate.wday
  else regdate
  end
end

def selected_regdates(contents, col, time)
  all_regdates = Hash.new(0)

  contents.each do |row|
    regdate = parse_regdate(row[col], time)
    all_regdates[regdate] += 1
  end

  all_regdates
end

def get_highest_regdates(regdates)
  regdates.select { |k, v| v == regdates.values.max }
end

def clean_phone_numbers(phone_number)
  phone_number = phone_number.to_s.gsub(/-|\(|\)|\.| /, "")

  if phone_number.length < 10 || phone_number.length > 11
    phone_number = "INVALID: #{phone_number}"
  end

  if phone_number.length == 11
    if phone_number[0] == "1"
      phone_number = phone_number[1..-1]
    else
      phone_number = "INVALID: #{phone_number}"
    end
  end

  return phone_number
end

def legislators_by_zipcode(zipcode)
  legislators = Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  regdate = row[:regdate]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_numbers(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)
  puts "#{id} | #{name} | #{regdate} | #{zipcode} | #{phone_number}"
end

contents.rewind
hour_regdates = selected_regdates(contents, :regdate, "hour")
highest_hour_regdates = get_highest_regdates(hour_regdates)
puts "Peak registration hours: #{highest_hour_regdates.keys}"

contents.rewind
wday_regdates = selected_regdates(contents, :regdate, "wday")
highest_wday_regdates = get_highest_regdates(wday_regdates)
puts "Peak registration week days: #{highest_wday_regdates.keys}"