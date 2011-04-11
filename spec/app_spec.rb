require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), 'support', 'shared_examples')

describe "App" do
  # it_should_behave_like "SpecBootstrapHelper"
  # it_should_behave_like "SourceAdapterHelper"

  it_behaves_like "SharedInitHelper" do
    it "should create app with fields" do
      @a.id.should == @a_fields[:name]
      @a1 = App.load(@a_fields[:name])
      @a1.id.should == @a.id
      @a1.name.should == @a_fields[:name]
    end

    it "should add source adapters" do
      @a1 = App.load(@a_fields[:name])
      @a1.sources.members.sort.should == ["FixedSchemaAdapter", "SampleAdapter"]
    end    
  end  
end