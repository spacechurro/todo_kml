require 'rubygems'
require 'json'
require 'open-uri'
require 'builder'

todo_url = ARGV[0]
output_file = ARGV[1]
destination_dir = ARGV[2]
doc = open(todo_url).read

json_doc = JSON.parse(doc)

todos = json_doc['response']['todos']['items']

f = File.open(output_file, 'w')
xml = Builder::XmlMarkup.new(:target => f, :indent => 2)
xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

xml.kml( "xmlns" => 'http://www.opengis.net/kml/2.2') {
  xml.document {
    todos.each do |todo|
      xml.placemark {
        venue = todo['tip']['venue']
        location = venue['location']
        categories = venue['categories']

        xml.name venue['name']

        desc = "#{location['address']}\n"
        desc << " (#{location['crossStreet']})\n" unless location['crossStreet'].to_s.empty?
        desc << "#{categories.map { |c| c['name']}.join(', ')}\n" unless categories.empty?
        desc << "http://foursquare.com/venue/#{venue['id']}"
        xml.description desc
        xml.point {
          xml.coordinates "#{location['lng']}, #{location['lat']}, 0"
        }
      }
    end
  }
}

f.close

fixed_kml = File.read(output_file).gsub('document', 'Document').gsub('point', 'Point').gsub('placemark', 'Placemark')
File.open(output_file, 'w') { |f| f << fixed_kml }

`scp #{output_file} #{destination_dir}`
