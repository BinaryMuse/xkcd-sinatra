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
  return do_comic(:current)
end

get '/:number' do |number|
  return do_comic(number)
end

def do_comic(number)
  # If the comic number is 0, get today's comic
  # Else get the given comic
  begin
    if number == :current
      @data = Net::HTTP.get(URI.parse("http://xkcd.com/info.0.json"))
    else
      @data = Net::HTTP.get(URI.parse("http://xkcd.com/#{number}/info.0.json"))
    end

    # Parse the JSON into data
    @data = symbolize_keys(JSON::parse(@data))
  rescue
    @data = {:safe_title => "Not Found" }
    return haml :error
  end

  # Turn the "year", "month", and "day" properties into numbers
  [:year, :month, :day].each { |key| @data[key] = @data[key].to_i }
  # Calculate the "previous" and "next" comics, if any
  @data[:previous] = @data[:num] - 1 unless @data[:num] == 1 || @data[:num].nil?
  unless Time.now.year == @data[:year] && Time.now.month == @data[:month] && Time.now.day == @data[:day]
    @data[:next] = @data[:num] + 1 unless @data[:num].nil?
  end

  # Render the page
  haml :comic
end

# change string keys into symbols
def symbolize_keys(arg)
  case arg
  when Array
    arg.map { |elem| symbolize_keys elem }
  when Hash
    Hash[
      arg.map { |key, value|
        k = key.is_a?(String) ? key.to_sym : key
        v = symbolize_keys value
        [k,v]
      }]
  else
    arg
  end
end

__END__

@@ layout
%html
  %head
    %title xkcd mini: #{@data[:safe_title]}
  %body
    = yield

@@ error
%h1 Not Found
%p
  That comic was not found.
%p
  %a{:href => "/"} Home

@@ comic
%h1= @data[:safe_title]
%p
  - unless @data[:previous].nil?
    %a{:href => "/1"}
      &lt;&lt; First
    &nbsp;|&nbsp;
    %a{:href => "/#{@data[:previous]}"}
      &lt; Previous
  - else
    &lt;&lt; First
    &nbsp;|&nbsp;
    &lt; Previous
  &nbsp;|&nbsp;
  - unless @data[:next].nil?
    %a{:href => "/#{@data[:next]}"}
      Next &gt;
    &nbsp;|&nbsp;
    %a{:href => "/"}
      Last &gt;&gt;
  - else
    Next &gt;
    &nbsp;|&nbsp;
    Last &gt;&gt;
%p
  %img{:src => @data[:img]}
%p= @data[:alt]