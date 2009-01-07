# Ruby interface to the excellent Helipad[http://pad.helicoid.net/home.html]
# online note pad.
#        
# Author: Lonnon Foster <lonnon.foster@gmail.com>
#        
# Copyright (c) 2008 Lonnon Foster. All rights reserved.
#        
# == Overview
#        
# This file provides three classes for working with
# Helipad[http://pad.helicoid.net/home.html]: +Helipad+, <tt>Helipad::Document</tt>, and
# <tt>Helipad::Response</tt>.
#
# The +Helipad+ class does all the heavy lifting. Creating an instance of
# +Helipad+ requires your login credentials.
#
#     hp = Helipad.new("lonnon@example.com", "password")
#
# Armed with an instance of +Helipad+, you can call its methods to interact
# with Helipad[http://pad.helicoid.net/home.html] documents.
#
# The <tt>Helipad::Document</tt> class holds the data contained in a
# Helipad[http://pad.helicoid.net/home.html] document. The +get+ method
# returns a <tt>Helipad::Document</tt> instance. The +find+, +get_all+, and +get_titles+
# methods return an Array of <tt>Helipad::Document</tt> instances.
#
# The <tt>Helipad::Response</tt> class holds return data sent by
# Helipad[http://pad.helicoid.net/home.html] that describes the success or
# failure of various actions. The +create+, +destroy+, and +update+ methods
# return a <tt>Helipad::Response</tt> instance.
#        
# == Examples of Use
#
# All of these examples assume that a +Helipad+ object called +hp+ exists.
#
#     hp = Helipad.new("lonnon@example.com", "password")
#            
# === Getting an Existing Document
#
#     document = hp.get(3)
#     puts document.source
#
# === Get a Document Formatted as HTML
#
#     puts hp.get_html(3)
#
# === Finding Documents
#
#     def how_many(search_term)
#       documents = hp.find(search_term)
#       documents.size
#     end
#
#     find_this = "wombats"
#     puts "#{how_many(find_this)} document(s) were found containing '#{find_this}'."
#
# === Finding Documents by Tags
#
#     documents = hp.find(:tag, "work")
#     titles = documents.collect { |doc| doc.title }
#     puts "Documents tagged with 'work':\n  #{titles.join("\n  ")}"
#
# === Creating a Document
#
#     source = File.read("cake_recipe.txt")
#     response = hp.create(:title  => "Delicious Chocolate Cake",
#                          :tags   => "recipe dessert",
#                          :source => source)
#     puts "Recipe saved" if response.saved?
#
# === Delete Documents
#
#     doc_ids = hp.find(:tag, "incriminating").collect { |doc| doc.doc_id }
#     doc_ids.each do |id|
#       hp.destroy(id)
#     end

require 'net/http'
require 'uri'
require 'rexml/document'
require 'date'

# Class +Helipad+ provides a wrapper for the {Helipad XML
# API}[http://pad.helicoid.net/document/public/6313d317].
#
# See the documentation in the file {helipad.rb}[link:files/lib/helipad_rb.html] for an overview.
class Helipad
  # Create a new +Helipad+ object.
  #
  # ==== Parameters
  # +email+ and +password+ are the same credentials you use to log on to your Helipad account.
  def initialize(email, password)
    @email = email
    @password = password
    raise(ArgumentError, "Email address not specified", caller) if @email.nil?
    raise(ArgumentError, "Password not specified", caller) if @password.nil?
  end
  
  # Create a new Helipad[http://pad.helicoid.net/home.html] document.
  #
  # ==== Parameters
  # +args+ is a Hash containing properties for the created document.
  #
  # * <tt>:title</tt> - Title for the new document. This parameter is
  #   required.
  # * <tt>:tags</tt> - Space-separated list of tags for the new document
  # * <tt>:source</tt> - Body of the new document.
  #   Helipad[http://pad.helicoid.net/home.html] understands {Textile markup}[http://pad.helicoid.net/formatting],
  #   which you can use to format the document's text.
  #
  # ==== Returns
  # This method returns a <tt>Helipad::Response</tt> object, which has the following methods:
  # * <tt>saved?</tt> - +true+ if the document was created successfully
  # * +doc_id+ - ID of the newly created document
  #
  # ==== Example
  #     hp = Helipad.new("lonnon@example.com", "password")
  #     response = hp.create(:title => "Marsupial Inventory",
  #                          :tags  => "marsupial australia animals",
  #                          :source => "|koala|2|\n|kangaroo|8|\n|platypus|1|")
  #     puts "Inventory saved as document #{response.doc_id}" if response.saved?
  def create(*args)
    options = args.extract_options!
    validate_options(options, :create)
    raise(ArgumentError, "No document options specified", caller) if options.empty?
    raise(ArgumentError, "Document must have a title", caller) if options[:title].nil?
    url = URI.parse("http://pad.helicoid.net/document/create")
    Response.new(send_request(url, build_request(options)))
  end

  # Delete a Helipad[http://pad.helicoid.net/home.html] document.
  #
  # ==== Parameter
  # * +id+ - ID of the document to delete
  #
  # ==== Returns
  # This method returns a <tt>Helipad::Response</tt> object, which has the following method:
  # * <tt>deleted?</tt> - +true+ if the document was deleted successfully
  #
  # ==== Example
  #     hp = Helipad.new("lonnon@example.com", "password")
  #     response = hp.destroy(81)
  #     puts "Document deleted" if response.deleted?
  def destroy(id)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/destroy")
    Response.new(send_request(url, build_request))
  end
  
  # Search for Helipad[http://pad.helicoid.net/home.html] documents by text content or by tags.
  #
  # ==== Parameters
  # The +find+ method searches differently depending on its arguments:
  # * <tt>find(String)</tt> - Search for the string in the titles and bodies of documents.
  # * <tt>find(:tag, String)</tt> - Search for documents tagged with the string.
  #
  # ==== Returns
  # This method returns an Array of <tt>Helipad::Document</tt> objects, or +nil+ if nothing
  # could be found with the given search string. See <tt>Helipad::Document</tt> for more details
  # about the document object.
  #
  # ==== Examples
  #     hp = Helipad.new("lonnon@example.com", "password")
  #     docs = hp.find("wibble")
  #     puts "#{docs.size} documents contain 'wibble'"
  #
  #     docs = hp.find(:tag, "diary")
  #     puts "First diary entry is titled '#{docs.first.title}'"
  def find(*args)
    raise(ArgumentError, "No find arguments supplied", caller) if args.size == 0
    term = args.extract_search_term!
    case args.first
      when :tag then find_by_tag(term)
      when nil  then search(term)
      else           raise(ArgumentError, "Unknown find option '#{args.first}' supplied", caller)
    end
  end
  
  # Retrieve a Helipad[http://pad.helicoid.net/home.html] document.
  #
  # ==== Parameter
  # * +id+ - ID of the document to retrieve
  #
  # ==== Returns
  # This method returns a <tt>Helipad::Document</tt> object, which holds the contents and
  # properties of the document. See <tt>Helipad::Document</tt> for more details about the
  # document object.
  #
  # ==== Example
  #     hp = Helipad.new("lonnon@example.com", "password")
  #     document = hp.get(29)
  #     puts "#{document.title} contains #{document.source.length} characters."
  def get(id)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/get")
    Document.new(send_request(url, build_request))
  end
  
  # Retrieve all documents on a Helipad[http://pad.helicoid.net/home.html]
  # account.
  #
  # ==== Returns
  # This method returns an Array of <tt>Helipad::Document</tt> objects. See
  # <tt>Helipad::Document</tt> for more details about the document object.
  #
  # ==== Example
  #     hp = Helipad.new("lonnon@example.com", "password")
  #     docs = hp.get_all
  #     case docs.size
  #       when > 1000 then puts "Slow down there, Shakespeare!"
  #       when >  100 then puts "That's a respectable amount of writing."
  #       when >   10 then puts "Keep at it!"
  #       else             puts "Do you even use your Helipad account?"
  #     end
  def get_all
    url = URI.parse("http://pad.helicoid.net/")
    response = REXML::Document.new(send_request(url, build_request))
    documents = Array.new
    REXML::XPath.match(response, "//document").each do |doc|
      documents.push Document.new(doc)
    end
    documents
  end

  # Retrieve an HTML-formatted version of a Helipad[http://pad.helicoid.net/home.html] document.
  #
  # ==== Parameter
  # * +id+ - ID of the document to retrieve
  #
  # ==== Returns
  # This method returns a String containing the HTML-formatted document.
  #
  # ==== Example
  #     hp = Helipad.new("lonnon@example.com", "password")
  #     puts hp.get_html(94)
  def get_html(id)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/format/html")
    doc = REXML::Document.new(send_request(url, build_request))
    REXML::XPath.match(doc, "html/child::text()").join.strip
  end
  
  # Retrieve a list of all the document titles in a Helipad[http://pad.helicoid.net/home.html] account.
  #
  # ==== Returns
  # This method returns an Array of <tt>Helipad::Document</tt> objects that contain titles, but
  # no document source. See <tt>Helipad::Document</tt> for more details about the document object.
  #
  # ==== Example
  #     hp = Helipad.new("lonnon@example.com", "password")
  #     puts "Table of Contents"
  #     hp.get_titles.each do |doc|
  #       puts doc.title
  #     end
  def get_titles
    url = URI.parse("http://pad.helicoid.net/documents/titles")
    response = REXML::Document.new(send_request(url, build_request))
    documents = Array.new
    REXML::XPath.match(response, "//document").each do |doc|
      documents.push Document.new(doc)
    end
    documents
  end
  
  # Update an existing Helipad[http://pad.helicoid.net/home.html] document.
  #
  # ==== Parameters
  # +id+ is the ID of the document to be updated.
  #
  # +args+ is a Hash containing properties to update in the document. All of the properties
  # are optional.
  #
  # * <tt>:title</tt> - Updated title for the document
  # * <tt>:tags</tt> - Space-separated list of tags for the document
  # * <tt>:source</tt> - Updated body of the document.
  #   Helipad[http://pad.helicoid.net/home.html] understands {Textile markup}[http://pad.helicoid.net/formatting],
  #   which you can use to format the document's text.
  #
  # ==== Returns
  # This method returns a <tt>Helipad::Response</tt> object, which has the following method:
  # * <tt>saved?</tt> - +true+ if the document was created successfully
  #
  # ==== Example
  #     hp = Helipad.new("lonnon@example.com", "password")
  #     response = hp.update(:title => "Marsupial Inventory (amended)",
  #                          :source => "|koala|2|\n|kangaroo|2|\n|platypus|19|")
  #     puts "Inventory updated" if response.saved?
  def update(id, *args)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/update")
    options = args.extract_options!
    validate_options(options, :update)
    raise(ArgumentError, "No options specified", caller) if options.empty?
    Response.new(send_request(url, build_request(options)))
  end
  
  
  # Contains the properties and data that make up a Helipad[http://pad.helicoid.net/home.html] document.
  #
  # Various +Helipad+ methods create and return <tt>Helipad::Document</tt> objects; there is
  # probably little reason to make an instance of <tt>Helipad::Document</tt> in your own code.
  #
  # The class contains a number of read-only methods for retrieving a document's properties. Depending
  # on which +Helipad+ method created the <tt>Helipad::Document</tt> object, some of these methods may
  # not be present. For example, the <tt>Helipad.get_titles</tt> method leaves out the +source+
  # attribute.
  # * +doc_id+ - ID of the document
  # * +title+ - Title of the document
  # * +source+ - Body of the document. Helipad[http://pad.helicoid.net/home.html] understands
  #   {Textile markup}[http://pad.helicoid.net/formatting],
  #   which you can use to format the document's text.
  # * +tags+ - An Array containing the document's tags, each of which is a String
  # * +created_on+ - A DateTime object containing the creation time of the document
  # * +updated_on+ - A DateTime object containing the document's last modification time
  # * +share+ - The URL where the document is shared, or +nil+ if the document is not shared
  # * <tt>approved?</tt> - Not sure what this means, but it's +true+ if the document's "approved"
  #   property is true, and +false+ otherwise.
  # * <tt>dangerous?</tt> - Also unsure what this means, but it's +true+ if the document's "dangerous"
  #   property is true, and +false+ otherwise.
  # * +raw_response+ - The raw XML response returned by Helipad[http://pad.helicoid.net/home.html].
  #   This could be useful if, for some reason, you want to parse the results yourself. See the
  #   {Helipad API documentation}[http://pad.helicoid.net/document/public/6313d317] for more
  #   information.
  class Document
    def initialize(source) #:nodoc:
      if source.kind_of? REXML::Element
        doc = REXML::Document.new(source.to_s)
      else
        doc = REXML::Document.new(source)
      end
      REXML::XPath.match(doc, "document/*").each do |tag|
        suffix = ""
        case tag.name
        when "approved"
          name = "approved"
          suffix = "?"
          value = tag.text == "true" ? true : false
        when "created-on"
          name = "created_on"
          value = DateTime.parse tag.text
        when "dangerous"
          name = "dangerous"
          suffix = "?"
          value = tag.text == "true" ? true : false
        when "share"
          name = "share"
          if tag.attributes["nil"] == "true"
            value = nil
          else
            value = "http://pad.helicoid.net/document/public/#{tag.text}"
          end
        when "source"
          name = "source"
          value = tag.text
        when "title"
          name = "title"
          value = tag.text
        when "updated-on"
          name = "updated_on"
          value = DateTime.parse tag.text
        when "id"
          name = "doc_id"
          value = Integer(tag.text)
        when "tags"
          name = "tags"
          value = Array.new
          REXML::XPath.match(tag, "tag/name/child::text()").each do |this_tag|
            value.push this_tag.to_s
          end
        else
          name = tag.name
          value = tag.text
        end
        self.instance_eval %{
          def self.#{name}#{suffix}
            @#{name}
          end
          @#{name} = value
        }, __FILE__, __LINE__
      end
      self.instance_eval %{
        def self.raw_response
          @raw_response
        end
        @raw_response = %{#{source}}
      }, __FILE__, __LINE__
    end
  end


  # Contains the data returned by Helipad[http://pad.helicoid.net/home.html] in response to certain
  # API calls.
  #
  # Various +Helipad+ methods create and return <tt>Helipad::Response</tt> objects; there is
  # probably little reason to make an instance of <tt>Helipad::Response</tt> in your own code.
  #
  # The class contains a number of read-only methods for retrieving a response's properties. Depending
  # on which +Helipad+ method created the <tt>Helipad::Response</tt> object, some of these methods may
  # not be present. For example, the <tt>Helipad.update</tt> method leaves out the +doc_id+
  # attribute, and <tt>Helipad.destroy</tt> doesn't use the <tt>saved?</tt> method.
  # * +doc_id+ - ID of the document associated with the response. <tt>Helipad.create</tt> returns this
  #   to let you know the ID of the document it just created.
  # * <tt>saved?</tt> - +true+ if the document was saved succesfully, otherwise +false+
  # * <tt>deleted?</tt> - +true+ if the document was deleted successfully, otherwise +false+
  # * +raw_response+ - The raw XML response returned by Helipad[http://pad.helicoid.net/home.html].
  #   This could be useful if, for some reason, you want to parse the results yourself. See the
  #   {Helipad API documentation}[http://pad.helicoid.net/document/public/6313d317] for more
  #   information.
  class Response
    def initialize(raw_response) #:nodoc:
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
          name = "doc_id"
          value = Integer(tag.text)
        else
          name = tag.name
          value = tag.text
        end
        self.instance_eval %{
          def self.#{name}#{suffix}
            @#{name}
          end
          @#{name} = value
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
    block = %{
<authentication>
  <email>#{@email}</email>
  <password>#{@password}</password>
</authentication>
    }
  end
  
  def build_request(*args)
    options = args.extract_options!
    request = "<request>#{authentication_block}"
    unless options.empty?
      request << "<document>"
      options.each_pair do |key, value|
        request << "<#{key}>#{value}</#{key}>"
      end
      request << "</document>"
    end
    request << "</request>"
  end
  
  def find_by_tag(tag)
    raise(ArgumentError, "No tag supplied", caller) if tag.nil?
    url = URI.parse("http://pad.helicoid.net/document/tag/#{URI.escape(tag)}")
    request = "<request>#{authentication_block}</request>"
    response = REXML::Document.new(send_request(url, request))
    documents = Array.new
    REXML::XPath.match(response, "//document").each do |doc|
      documents.push Document.new(doc)
    end
    documents.size > 0 ? documents : nil
  end

  def search(term)
    url = URI.parse("http://pad.helicoid.net/document/search")
    request = "<request>#{authentication_block}<search>#{term}</search></request>"
    response = REXML::Document.new(send_request(url, request))
    documents = Array.new
    REXML::XPath.match(response, "//document").each do |doc|
      documents.push Document.new(doc)
    end
    documents.size > 0 ? documents : nil
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
  
  VALID_CREATE_OPTIONS = [:title, :source, :tags] #:nodoc:
  VALID_UPDATE_OPTIONS = [:title, :source, :tags] #:nodoc:
  
  def validate_options(options, action)
    case action
      when :create then constant = VALID_CREATE_OPTIONS
      when :update then constant = VALID_UPDATE_OPTIONS
    end
    options.assert_valid_keys(constant)
  end
end

class Array #:nodoc: all
  def extract_options!
    last.is_a?(::Hash) ? pop : {}
  end

  def extract_search_term!
    last.is_a?(::String) ? pop : nil
  end
end

class Hash #:nodoc: all
  def assert_valid_keys(*valid_keys)
    unknown_keys = keys - [valid_keys].flatten
    raise(ArgumentError, "Unknown key(s): #{unknown_keys.join(", ")}") unless unknown_keys.empty?
  end
end
