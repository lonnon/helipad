# Ruby interface to the excellent Helipad[http://pad.helicoid.net/home.html] online note pad.
# 
# Author: Lonnon Foster <lonnon.foster@gmail.com>
# 
# Copyright (c) 2008 Lonnon Foster. All rights reserved.
# 
# == Overview
# 
# This file provides three classes for working with \Helipad.
# 
# == Examples of Use
#
# All of these examples assume that a Helipad object called +hp+ exists.
#
#     hp = Helipad.new("lonnon@example.com", "password")
#     
# === Getting an Existing Document
#
#     document = hp.get(3)
#     puts document.doc_source
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
#     titles = documents.collect { |doc| doc.doc_title }
#     puts "Documents tagged with 'work':\n  #{titles.join("\n  ")}"
#
# === Creating a Document
#
#     source = File.read("cake_recipe.txt")
#     response = hp.create(:title  => "Delicious Chocolate Cake",
#                          :tags   => "recipe dessert",
#                          :source => source)
#     puts "Recipe saved" if response.doc_saved?
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
# See the documentation for the file helipad.rb for an overview.
class Helipad
  # Create a new Helipad object.
  #
  # +email+ and +password+ are the same credentials you use to log on to your Helipad account.
  def initialize(email, password)
    @email = email
    @password = password
    raise(ArgumentError, "Email address not specified", caller) if @email.nil?
    raise(ArgumentError, "Password not specified", caller) if @password.nil?
  end
  
  def create(*args)
    options = args.extract_options!
    validate_options(options, :create)
    raise(ArgumentError, "No document options specified", caller) if options.empty?
    raise(ArgumentError, "Document must have a title", caller) if options[:title].nil?
    title = "<title>#{options[:title]}</title>"
    tags = "<tags>#{options[:tags]}</tags>" unless options[:tags].nil?
    source = "<source>#{options[:source]}</source>" unless options[:source].nil?
    url = URI.parse("http://pad.helicoid.net/document/create")
    request = %{
<request>
  #{authentication_block}
  <document>
    #{title}
    #{source}
    #{tags}
  </document>
</request>
    }
    Response.new(send_request(url, request)) if title or tags or source
  end

  def destroy(id)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/destroy")
    request = "<request>#{authentication_block}</request>"
    Response.new(send_request(url, request))
  end
  
  def find(*args)
    raise(ArgumentError, "No find arguments supplied", caller) if args.size == 0
    term = args.extract_search_term!
    case args.first
      when :tag then find_by_tag(term)
      when nil  then search(term)
      else           raise(ArgumentError, "Unknown find option '#{args.first}' supplied", caller)
    end
  end
  
  def get(id)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/get")
    request = "<request>#{authentication_block}</request>"
    Document.new(send_request(url, request))
  end
  
  def get_all
    url = URI.parse("http://pad.helicoid.net/")
    request = "<request>#{authentication_block}</request>"
    response = REXML::Document.new(send_request(url, request))
    documents = Array.new
    REXML::XPath.match(response, "//document").each do |doc|
      documents.push Document.new(doc)
    end
    documents
  end

  def get_html(id)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/format/html")
    request = "<request>#{authentication_block}</request>"
    doc = REXML::Document.new(send_request(url, request))
    REXML::XPath.match(doc, "html/child::text()").join.strip
  end
  
  def get_titles
    url = URI.parse("http://pad.helicoid.net/documents/titles")
    request = "<request>#{authentication_block}</request>"
    response = REXML::Document.new(send_request(url, request))
    documents = Array.new
    REXML::XPath.match(response, "//document").each do |doc|
      documents.push Document.new(doc)
    end
    documents
  end
  
  def update(id, *args)
    url = URI.parse("http://pad.helicoid.net/document/#{id}/update")
    options = args.extract_options!
    validate_options(options, :update)
    title = "<title>#{options[:title]}</title>" unless options[:title].nil?
    tags = "<tags>#{options[:tags]}</tags>" unless options[:tags].nil?
    source = "<source>#{options[:source]}</source>" unless options[:source].nil?
    raise(ArgumentError, "No options specified", caller) if (title.nil? and tags.nil? and source.nil?)
    request = %{
<request>
  #{authentication_block}
  <document>
    #{title}
    #{source}
    #{tags}
  </document>
</request>
    }
    Response.new(send_request(url, request))
  end
  
  
  class Document
    def initialize(source)
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
            value = tag.text
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
          name = "id"
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
          def self.doc_#{name}#{suffix}
            @doc_#{name}
          end
          @doc_#{name} = value
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
    block = %{
<authentication>
  <email>#{@email}</email>
  <password>#{@password}</password>
</authentication>
    }
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
  
  VALID_CREATE_OPTIONS = [:title, :source, :tags]
  VALID_UPDATE_OPTIONS = [:title, :source, :tags]
  
  def validate_options(options, action)
    case action
      when :create then constant = VALID_CREATE_OPTIONS
      when :update then constant = VALID_UPDATE_OPTIONS
    end
    options.assert_valid_keys(constant)
  end
end


class Array
  def extract_options!
    last.is_a?(::Hash) ? pop : {}
  end

  def extract_search_term!
    last.is_a?(::String) ? pop : nil
  end
end


class Hash
  def assert_valid_keys(*valid_keys)
    unknown_keys = keys - [valid_keys].flatten
    raise(ArgumentError, "Unknown key(s): #{unknown_keys.join(", ")}") unless unknown_keys.empty?
  end
end
