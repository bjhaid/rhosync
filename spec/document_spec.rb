require File.join(File.dirname(__FILE__),'spec_helper')

describe "Document" do
  it_should_behave_like "SpecBootstrapHelper"
  it_should_behave_like "SourceAdapterHelper"
  
  it "should generate client docname" do
    @c.docname(:foo).should == "client:#{@a.id}:#{@u.id}:#{@c.doc_suffix(:foo)}"
  end
  
  it "should generate source docname" do
    @s.docname(:foo).should == "source:#{@a.id}:#{@u.id}:#{@s.doc_suffix(:foo)}"
  end
  
  it "should flash_data for docname" do
    @c.put_data(:foo1,{'1'=>@product1})
    Store.db.keys(@c.docname('*')).should == [@c.docname(:foo1)]
    @c.flash_data('*')
    Store.db.keys(@c.docname(:foo)).should == []
  end
end