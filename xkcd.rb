require 'net/http'
require 'uri'
require 'sinatra'
require 'json'
require 'haml'

# Blank route for the favicon to keep errors low
get '/favicon.ico' do
  nil
end

# Index redirects to /0
get '/' do
  redirect '/0'
end

get '/:number' do |number|
  # If the comic number is 0, get today's comic
  # Else get the given comic
  if number == "0"
    @data = Net::HTTP.get(URI.parse("http://xkcd.com/info.0.json"))
  else
    @data = Net::HTTP.get(URI.parse("http://xkcd.com/#{number}/info.0.json"))
  end

  # Parse the JSON into data
  @data = JSON::parse(@data, :symbolize_names => true)

  # Turn the "year", "month", and "day" properties into numbers
  [:year, :month, :day].each { |key| @data[key] = @data[key].to_i }
  # Calculate the "previous" and "next" comics, if any
  @data[:previous] = @data[:num] - 1 unless @data[:num] == 1
  unless Time.now.year == @data[:year] && Time.now.month == @data[:month] && Time.now.day == @data[:day]
    @data[:next] = @data[:num] + 1
  end

  # Render the page
  haml :comic
end

__END__

@@ layout
%html
  %head
    %title xkcd mini: #{@data[:safe_title]}
  %body
    = yield

@@ comic
%h1= @data[:safe_title]
%p
  - unless @data[:previous].nil?
    %a{:href => "/#{@data[:previous]}"}
      Previous
  - unless @data[:previous].nil? || @data[:next].nil?
    &nbsp;|&nbsp;
  - unless @data[:next].nil?
    %a{:href => "/#{@data[:next]}"}
      Next
%p
  %img{:src => @data[:img]}
%p= @data[:alt]