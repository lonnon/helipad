$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'helipad'
require 'test/unit'
require 'rexml/document'
include REXML

class TestHelipad < Test::Unit::TestCase
  def setup
    @email = "lonnon.foster@gmail.com"
    @password = "TimP4H"
    @hp = Helipad.new(@email, @password)
  end
  
  def test_authenticate
    assert_nothing_raised do
      @hp.authenticate
    end
  end
  
  def test_create
    assert_nothing_raised do
      response = @hp.create("New document", "test", "Just a test document")
      doc = Document.new response
      created = doc.root.elements["saved"].text
      assert_equal("true", created, "Document not created.")
      @hp.destroy(doc.root.elements["id"].text) if created = "true"
    end
  end
  
  def test_destroy
    create_response = @hp.create("Document for deletion", "test", "Should be deleted by test case")
    create_doc = Document.new create_response
    id = create_doc.root.elements["id"].text
    assert_nothing_raised do
      response = @hp.destroy(id)
      doc = Document.new response
      deleted = doc.root.text
      assert_equal("true", deleted, "Document not deleted.")
    end
  end

  def test_get
    assert_nothing_raised do
      @hp.get(1)
    end
    doc = Document.new @hp.get(1)
    assert_equal("test", doc.root.elements["title"].text, "Title is wrong.")
    assert_equal("test", doc.root.elements["source"].text, "Source is wrong.")
    assert_equal("test", doc.root.elements["tags/tag/name"].text, "Tags are wrong.")
    assert_equal(1, XPath.match(doc, "//tag").size, "Wrong number of tags.")
  end
  
  def test_get_html
    assert_nothing_raised do
      @hp.get_html(1)
    end
    doc = Document.new @hp.get_html(1)

  end

end