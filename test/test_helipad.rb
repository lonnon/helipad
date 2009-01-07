$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'helipad'
require 'test/unit'
require 'optparse'

class TestHelipad < Test::Unit::TestCase
  def setup
    raise(ArgumentError, "Usage: #{$0} -- email password", caller) if ARGV.length != 2
    @email = ARGV[0]
    @password = ARGV[1]
    @hp = Helipad.new(@email, @password)
    @test_string = [Array.new(6){rand(256).chr}.join].pack("m").chomp
    response = @hp.create(:title => "test #{@test_string}",
                          :tags => "test #{@test_string}", 
                          :source => "test #{@test_string}")
    @test_id = response.doc_id
  end
  
  def teardown
    @hp.destroy(@test_id)
  end
  
  def test_create
    response = nil
    assert_nothing_raised do
      response = @hp.create(:title => "New document", :tags => "test",
                            :source => "Just a test document")
    end
    assert_equal(true, response.saved?, "Document not created.")
    @hp.destroy(response.doc_id) if response.saved?
  end
  
  def test_destroy
    create_response = @hp.create(:title => "Document for deletion", :tags => "test",
                                 :source => "Should be deleted by test case")
    response = nil
    assert_nothing_raised do
      response = @hp.destroy(create_response.doc_id)
    end
    assert_equal(true, response.deleted?, "Document not deleted.")
  end

  def test_find
    documents = nil
    assert_nothing_raised do
      documents = @hp.find(@test_string)
    end
    assert_equal("test #{@test_string}", documents[0].title,
                 "By search term: First document title is wrong.")
    
    documents = @hp.find("32908p9832tn9p85h92gng825g82ngp88p9834p98v348anvs8")
    assert_nil(documents, "Bogus string should not be found.")
    
    assert_nothing_raised do
      documents = @hp.find(:tag, @test_string)
    end
    assert_equal("test #{@test_string}", documents[0].title,
                 "By tag: First document title is wrong.")
    
    documents = @hp.find(:tag, "02vhn45g70h4cgh0872h54gmv072hm45g70hmv0hmv2g20457gh")
    assert_nil(documents, "Bogus tag should not be found.")
    
    assert_raise(ArgumentError) {@hp.find}
    assert_raise(ArgumentError) {@hp.find(:wibble)}
    assert_raise(ArgumentError) {@hp.find(:tag)}
  end
  
  def test_get
    doc = nil
    assert_nothing_raised do
      doc = @hp.get(@test_id)
    end
    assert_equal("test #{@test_string}", doc.title, "Title is wrong.")
    assert_equal("test #{@test_string}", doc.source, "Source is wrong.")
    assert_equal(["test", @test_string], doc.tags, "Tags are wrong.")
  end
  
  def test_get_all
    documents = nil
    assert_nothing_raised do
      documents = @hp.get_all
    end
  end
  
  def test_get_html
    html = nil
    assert_nothing_raised do
      html = @hp.get_html(@test_id)
    end
    exemplar = %{<h1>test #{@test_string}</h1>
<p>test #{@test_string}</p>}
    assert_equal(exemplar, html, "HTML contents are wrong.")
  end

  def test_get_titles
    documents = nil
    assert_nothing_raised do
      documents = @hp.get_titles
    end
  end
  
  def test_update
    response = nil
    assert_raise(ArgumentError) {@hp.update(@test_id)}
    assert_raise(ArgumentError) {@hp.update(@test_id, :wibble => "freem")}
    
    response = @hp.update(@test_id, :title => "Modified the title")
    assert_equal(true, response.saved?, "Document title wasn't updated.")
    doc = @hp.get(@test_id)
    assert_equal("Modified the title", doc.title, "Title is wrong.")
    
    response = @hp.update(@test_id, :source => "Modified, darlin'")
    assert_equal(true, response.saved?, "Document source wasn't updated.")
    doc = @hp.get(@test_id)
    assert_equal("Modified, darlin'", doc.source, "Source is wrong.")
    
    response = @hp.update(@test_id, :tags => "test stuff")
    assert_equal(true, response.saved?, "Document tags weren't updated.")
    doc = @hp.get(@test_id)
    assert_equal(["test", "stuff"], doc.tags, "Tags are wrong.")
  end
end