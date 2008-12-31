$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'helipad'
require 'test/unit'

class TestHelipad < Test::Unit::TestCase
  def setup
    @email = "lonnon.foster@gmail.com"
    @password = "TimP4H"
    @hp = Helipad.new(@email, @password)
  end
  
  def test_create
    response = nil
    assert_nothing_raised do
      response = @hp.create(:title => "New document", :tags => "test",
                            :source => "Just a test document")
    end
    assert_equal(true, response.doc_saved?, "Document not created.")
    @hp.destroy(response.doc_id) if response.doc_saved?
  end
  
  def test_destroy
    create_response = @hp.create(:title => "Document for deletion", :tags => "test",
                                 :source => "Should be deleted by test case")
    response = nil
    assert_nothing_raised do
      response = @hp.destroy(create_response.doc_id)
    end
    assert_equal(true, response.doc_deleted?, "Document not deleted.")
  end

  def test_find
    documents = nil
    assert_nothing_raised do
      documents = @hp.find("test")
    end
    assert_equal("test", documents[0].doc_title, "By search term: First document title is wrong.")
    
    documents = @hp.find("32908p9832tn9p85h92gng825g82ngp88p9834p98v348anvs8")
    assert_nil(documents, "Bogus string should not be found.")
    
    assert_nothing_raised do
      documents = @hp.find(:tag, "test")
    end
    assert_equal("test", documents[0].doc_title, "By tag: First document title is wrong.")
    
    documents = @hp.find(:tag, "02vhn45g70h4cgh0872h54gmv072hm45g70hmv0hmv2g20457gh")
    assert_nil(documents, "Bogus tag should not be found.")
    
    assert_raise(ArgumentError) {@hp.find}
    assert_raise(ArgumentError) {@hp.find(:wibble)}
    assert_raise(ArgumentError) {@hp.find(:tag)}
  end
  
  def test_get
    doc = nil
    assert_nothing_raised do
      doc = @hp.get(1)
    end
    assert_equal("test", doc.doc_title, "Title is wrong.")
    assert_equal("test", doc.doc_source, "Source is wrong.")
    assert_equal(["test"], doc.doc_tags, "Tags are wrong.")
  end
  
  def test_get_all
    documents = nil
    assert_nothing_raised do
      documents = @hp.get_all
    end
    assert_equal("test", documents[0].doc_title, "First document title is wrong.")
    assert_equal("test", documents[0].doc_source, "First document source is wrong.")
    assert_equal(["test"], documents[0].doc_tags, "First document tags are wrong.")
  end
  
  def test_get_html
    html = nil
    assert_nothing_raised do
      html = @hp.get_html(1)
    end
    exemplar = %{<h1>test</h1>
<p>test</p>}
    assert_equal(exemplar, html, "HTML contents are wrong.")
  end

  def test_get_titles
    documents = nil
    assert_nothing_raised do
      documents = @hp.get_titles
    end
    assert_equal("test", documents[0].doc_title, "First document title is wrong.")
  end
  
  def test_update
    create_response = @hp.create(:title => "Document to be modified", :tags => "test",
                                 :source => "Modify me, baby")
    if create_response.doc_saved?
      response = nil
      assert_nothing_raised do
        response = @hp.update(create_response.doc_id)
      end
      assert_nil(response, "Update should return nil when no params are supplied.")

      response = @hp.update(create_response.doc_id, :title => "Modified the title")
      assert_equal(true, response.doc_saved?, "Document title wasn't updated.")
      doc = @hp.get(create_response.doc_id)
      assert_equal("Modified the title", doc.doc_title, "Title is wrong.")
      
      response = @hp.update(create_response.doc_id, :source => "Modified, darlin'")
      assert_equal(true, response.doc_saved?, "Document source wasn't updated.")
      doc = @hp.get(create_response.doc_id)
      assert_equal("Modified, darlin'", doc.doc_source, "Source is wrong.")

      response = @hp.update(create_response.doc_id, :tags => "test stuff")
      assert_equal(true, response.doc_saved?, "Document tags weren't updated.")
      doc = @hp.get(create_response.doc_id)
      assert_equal(["test", "stuff"], doc.doc_tags, "Tags are wrong.")

      @hp.destroy(create_response.doc_id)
    end
  end
end