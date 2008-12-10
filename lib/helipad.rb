require 'net/http'
require 'uri'

class Helipad
  def initialize(email, password)
    @email = email
    @password = password
  end
  
  def authenticate
    url = URI.parse("http://pad.helicoid.net/")
    request = "<request>#{authentication_block}</request>"
    send_request(url, request)
  end

  def create(title, tags, source)
    url = URI.parse("http://pad.helicoid.net/document/create")
    request = <<END_OF_CREATE_REQUEST
<request>
  #{authentication_block}
  <document>
    <title>#{title}</title>
    <source>#{source}</source>
    <tags>#{tags}</tags>
  </document>
</request>'
END_OF_CREATE_REQUEST
    send_request(url, request)
  end
  
  def destroy(id)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/destroy")
    request = "<request>#{authentication_block}</request>"
    send_request(url, request)
  end
  
  def get(id)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/get")
    request = "<request>#{authentication_block}</request>"
    send_request(url, request)
  end
  
  def get_html(id)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/format/html")
    request = "<request>#{authentication_block}</request>"
    send_request(url, request)
  end
  
  def update(id, title, tags, source)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/update")
    title = "<title>#{title}</title>" unless title.nil?
    tags = "<tags>#{tags}</tags>" unless tags.nil?
    source = "<source>#{source}</source>" unless source.nil?
    request = <<END_OF_UPDATE_REQUEST
<request>
  #{authentication_block}
  <document>
    #{title}
    #{source}
    #{tags}
  </document>
</request>
END_OF_UPDATE_REQUEST
    send_request(url, request)
  end
  
private
  
  def authentication_block
    block = <<END_OF_AUTHENTICATION
<authentication>
    <email>#{@email}</email>
    <password>#{@password}</password>
  </authentication>
END_OF_AUTHENTICATION
  end
  
  def send_request(url, request)
    response = Net::HTTP.start(url.host, url.port) do |http|
      http.post(url.path, request,
                {'Accept' => 'application/xml', 'Content-Type' => 'application/xml'})
    end
    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
      response.body
    else
      response.error!
    end
  end

end
