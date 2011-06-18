require "spec_helper"

describe Model do

  it "should be created with default options" do
    lambda { Model.new }.should_not raise_exception
  end

  describe "statements" do

    before :each do
      @model = Model.new
    end

    it do
      @model.statements.should be_an_instance_of(ModelProxy)
    end

    it "should be created in the model" do
      lambda {
        @model.statements.create(statement_attributes)
      }.should change(@model.statements, :size).by(1)
    end

    it "should be bound to the model" do
      statement = @model.statements.create(statement_attributes)
      statement.model.should be(@model)
    end

    it "should be iterated over" do
      statement = @model.statements.create(statement_attributes)
      statements = []
      lambda {
        @model.statements.each do |s|
          statements << s
        end
      }.should change(statements, :size).by(1)
      statements.first.should eql(statement)
    end

    it "should be added to the model" do
      statement = Statement.new(statement_attributes)
      lambda {
        lambda {
          @model.statements.add(statement)
        }.should change(@model.statements, :size).by(1)
      }.should change(statement, :model).from(nil).to(@model)
      @model.statements.should include(statement)
    end

    it "should be found without a block" do
      statement = @model.statements.create(statement_attributes)
      @model.statements.find(:first).should eql(statement)
      @model.statements.first.should eql(statement)
      @model.statements.find(:all).should eql([statement])
      @model.statements.all.should eql([statement])
    end

    it "should be found with a block" do
      statements = []
      statement = @model.statements.create(statement_attributes)
      lambda {
        @model.statements.find(:all) do |st|
          statements << st
        end
      }.should change(statements, :size).by(1)
      statements.first.should eql(statement)
    end

    it "should be found by an attribute" do
      statements = []
      statement = @model.statements.create(statement_attributes)
      lambda {
        @model.statements.find(:all, :object => statement.object) do |st|
          statements << st
        end
      }.should change(statements, :size).by(1)
      statements.first.should eql(statement)
    end

    it "should not be found with a block" do
      statements = []
      statement = @model.statements.create(statement_attributes)
      lambda {
        @model.statements.find(:all, :object => "another object") do |st|
          statements << st
        end
      }.should_not change(statements, :size)
    end

    it "should be removed from the model" do
      statement = @model.statements.create(statement_attributes)
      lambda {
        statement.destroy
      }.should change(@model.statements, :size).by(-1)
      @model.statements.should_not include(statement)
      statement.model.should be_nil
    end


    private

    def statement_attributes
      s = URI.parse('http://example.com/concepts#subject')
      p = URI.parse('http://example.com/concepts#label')
      o = "subject!"
      {
        :subject => s,
        :predicate => p,
        :object => o
      }
    end

  end

  describe "serialization" do

    before :each do
      @model = Model.new
      s = URI.parse("http://example.com/concepts#two-dimensional_seismic_imaging")
      p = URI.parse("http://www.w3.org/2000/01/rdf-schema#label")
      o = "2-D seismic imaging@en"
      @model.statements.create(:subject => s, :predicate => p, :object => o)
    end

    it "should produce RDF/XML content" do
      content = @model.to_rdfxml
      content.should be_an_instance_of(String)
      content.should include('2-D seismic imaging')
    end

    it "should produce N-Triples content" do
      content = @model.to_ntriples
      content.should be_an_instance_of(String)
      content.should include('2-D seismic imaging@en')
    end

    it "should produce Turtle content" do
      content = @model.to_turtle
      content.should be_an_instance_of(String)
      content.should include('2-D seismic imaging@en')
    end

    it "should produce JSON content" do
      content = @model.to_json
      content.should be_an_instance_of(String)
      content.should include('2-D seismic imaging@en')
    end

    it "should produce DOT content" do
      content = @model.to_dot
      content.should be_an_instance_of(String)
      content.should include('2-D seismic imaging@en')
    end

    describe "file source" do

      before :each do
        content = '<?xml version="1.0" encoding="utf-8"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description rdf:about="http://example.com/concepts#two-dimensional_seismic_imaging"><ns0:label xmlns:ns0="http://www.w3.org/2000/01/rdf-schema#" xml:lang="en">2-D seismic imaging</ns0:label></rdf:Description></rdf:RDF>'
        reference_model = Model.new
        reference_model.from_rdfxml(content, :base_uri => 'http://example.com/concepts')
        reference_model.to_file(filename)
      end

      after :each do
        cleanup
      end

      it "should be loaded from a file" do
        lambda {
          @model.from_file(filename, :base_uri => 'http://example.com/concepts')
        }.should change(@model.statements, :size).by(1)
      end

    end

    describe "file destination" do

      before :each do
        cleanup
      end

      after :each do
        cleanup
      end

      it "should produce a file" do
        @model.to_file(filename)
        File.should be_exists(filename)
        File.size(filename).should_not be_zero
      end

    end

    private

    def cleanup
      File.delete(filename) if File.exists?(filename)
    end

    def filename
      "test_model.rdf"
    end

  end

  describe "deserialization" do

    before :each do
      @model = Model.new
    end

    it "should be successful for RDF/XML data" do
      content = '<?xml version="1.0" encoding="utf-8"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description rdf:about="http://example.com/concepts#two-dimensional_seismic_imaging"><ns0:label xmlns:ns0="http://www.w3.org/2000/01/rdf-schema#" xml:lang="en">2-D seismic imaging</ns0:label></rdf:Description></rdf:RDF>'
      lambda {
        @model.from_rdfxml(content, :base_uri => 'http://example.com/concepts')
      }.should change(@model.statements, :size).by(1)
    end

    it "should be successful for N-Triples data" do
      content = '<http://example.org/ns/a2> <http://example.org/ns/b2> <http://example.org/ns/c2> .'
      lambda {
        @model.from_ntriples(content)
      }.should change(@model.statements, :size).by(1)
    end

    it "should be successful for Turtle data" do
      content = '# this is a complete turtle document
@prefix foo: <http://example.org/ns#> .
@prefix : <http://other.example.org/ns#> .
foo:bar foo: : .'
      lambda {
        @model.from_turtle(content, :base_uri => 'http://example.com/concepts')
      }.should change(@model.statements, :size).by(1)
    end

  end

end
