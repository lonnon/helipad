require 'net/http'
require 'uri'
require 'rexml/document'

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

  def create(params = nil)
    url = URI.parse("http://pad.helicoid.net/document/create")
    if params
      title = "<title>#{params[:title]}</title>" unless params[:title].nil?
      tags = "<tags>#{params[:tags]}</tags>" unless params[:tags].nil?
      source = "<source>#{params[:source]}</source>" unless params[:source].nil?
    end
    request = <<END_OF_CREATE_REQUEST
<request>
  #{authentication_block}
  <document>
    #{title}
    #{source}
    #{tags}
  </document>
</request>'
END_OF_CREATE_REQUEST
    response = Response.new(send_request(url, request)) if title or tags or source
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
  
  def update(id, params = nil)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/update")
    if params
      title = "<title>#{params[:title]}</title>" unless params[:title].nil?
      tags = "<tags>#{params[:tags]}</tags>" unless params[:tags].nil?
      source = "<source>#{params[:source]}</source>" unless params[:source].nil?
    end
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
    response = Response.new(send_request(url, request)) if title or tags or source
  end
  
  class Document
    def initialize(params = nil)
      if params
        @id = params[:id]
        @title = params[:title]
        @tags = params[:tags].split unless params[:tags].nil?
        @source = params[:source]
        @raw_response = params[:raw_response]
      end
    end
  end

  class Response
    def initialize(raw_response)
      doc = REXML::Document.new raw_response
      REXML::XPath.match(doc, "response/*").each do |tag|
        Response.create_attribute tag.name, tag.text
      end
    end
    
    private
    
    def self.create_attribute(name, value)
      return unless name
      code = "def #{name}; @#{name}; end\n"
      class_eval code
    end
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
