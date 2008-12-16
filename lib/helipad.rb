require 'net/http'
require 'uri'
require 'rexml/document'

class Helipad
  def initialize(email, password)
    @email = email
    @password = password
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
    Response.new(send_request(url, request)) if title or tags or source
  end
  
  def destroy(id)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/destroy")
    request = "<request>#{authentication_block}</request>"
    Response.new(send_request(url, request))
  end
  
  def get(id)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/get")
    request = "<request>#{authentication_block}</request>"
    send_request(url, request)
  end
  
  def get_all
    url = URI.parse("http://pad.helicoid.net/")
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
    Response.new(send_request(url, request)) if title or tags or source
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
      REXML::XPath.match(doc, "//*").each do |tag|
        suffix = ""
        case tag.name
        when "saved"
          name = "saved"
          suffix = "?"
          value = tag.text == "true" ? true : false
        when "deleted"
          name = "deleted"
          suffix = "?"
          value = tag.text == "true" ? true : false
        when "id"
          name = "id"
          value = Integer(tag.text)
        else
          name = tag.name
          value = tag.text
        end
        self.instance_eval %{
          def self.doc_#{name}#{suffix}
            @doc_#{name}
          end
          @doc_#{name} = value
        }, __FILE__, __LINE__ unless tag.name == "response"
      end
      self.instance_eval %{
        def self.raw_response
          @raw_response
        end
        @raw_response = %{#{raw_response}}
      }, __FILE__, __LINE__
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
