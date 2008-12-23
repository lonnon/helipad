$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'helipad'
require 'test/unit'
require 'rexml/document'
include REXML

class TestHelipad < Test::Unit::TestCase
  def setup
    @email = "lonnon.foster@gmail.com"
    @password = "TimP4H"
    @hp = Helipad.new(:email => @email, :password => @password)
  end
  
  def test_create
    assert_nothing_raised do
      response = @hp.create(:title => "New document", :tags => "test",
                            :source => "Just a test document")
      assert_equal(true, response.doc_saved?, "Document not created.")
      @hp.destroy(response.doc_id) if response.doc_saved?
    end
  end
  
  def test_destroy
    create_response = @hp.create(:title => "Document for deletion", :tags => "test",
                                 :source => "Should be deleted by test case")
    assert_nothing_raised do
      response = @hp.destroy(create_response.doc_id)
      assert_equal(true, response.doc_deleted?, "Document not deleted.")
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
  
  def test_get_all
    assert_nothing_raised do
      @hp.get_all
    end
  end
  
  def test_get_html
    assert_nothing_raised do
      doc = Document.new @hp.get_html(1)
    end
  end

  def test_update
    create_response = @hp.create(:title => "Document to be modified", :tags => "test",
                                 :source => "Modify me, baby")
    if create_response.doc_saved?
      assert_nothing_raised do
        response = @hp.update(create_response.doc_id)
        assert_nil(response, "Update should return nil when no params are supplied.")

        response = @hp.update(create_response.doc_id, :title => "Modified the title")
        assert_equal(true, response.doc_saved?, "Document wasn't updated.")
        doc = Document.new @hp.get(create_response.doc_id)
        assert_equal("Modified the title", doc.root.elements["title"].text, "Title is wrong.")
        
        response = @hp.update(create_response.doc_id, :source => "Modified, darlin'")
        assert_equal(true, response.doc_saved?, "Document wasn't updated.")
        doc = Document.new @hp.get(create_response.doc_id)
        assert_equal("Modified, darlin'", doc.root.elements["source"].text, "Source is wrong.")

        response = @hp.update(create_response.doc_id, :tags => "test stuff")
        assert_equal(true, response.doc_saved?, "Document wasn't updated.")
        doc = Document.new @hp.get(create_response.doc_id)
        tags = Array.new
        XPath.match(doc, "//tags/tag/name/child::text()").each do |tag|
          tags.push tag.to_s
        end
        assert_equal(["test", "stuff"], tags, "Tags are wrong.")
      end
      @hp.destroy(id)
    end
  end
end