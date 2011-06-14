require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Parser do

  it "should be created with default values" do
    lambda {
      Parser.new
    }.should_not raise_exception
  end

  describe "string source" do

    it "should be parsed into the model" do
      parser = Parser.new
      model = Model.new
      lambda {
        parser.from_string(model, content[:rdfxml], :base_uri => base_uri[:rdfxml])
      }.should change(model.statements, :size).by(1)
    end

  end

  describe "file source" do

    before :each do
      reference_model = Model.new
      reference_model.from_rdfxml(content[:rdfxml], :base_uri => base_uri[:rdfxml])
      reference_model.to_file(filename)
    end

    after :each do
      cleanup
    end

    it "should be parsed into the model" do
      parser = Parser.new
      model = Model.new
      lambda {
        parser.from_file(model, filename, :base_uri => base_uri[:rdfxml])
      }.should change(model.statements, :size).by(1)
    end

  end


  describe "statements" do

    it do
      Parser.new(:ntriples).statements(content[:ntriples]).should be_an_instance_of(ParserProxy)
    end

    [:rdfxml, :turtle, :ntriples].each do |format|
      it "should parse #{format} content" do
        parser = Parser.new(format)
        statements = []
        lambda {
          parser.statements(content[format], :base_uri => base_uri[format]).each do |st|
            statements << st
          end
        }.should change(statements, :size).by(1)
      end
    end

  end


  private

  def cleanup
    File.delete(filename) if File.exists?(filename)
  end

  def filename
    "test_model.rdf"
  end

  def content
    {
      :ntriples => '<http://example.org/ns/a2> <http://example.org/ns/b2> <http://example.org/ns/c2> .',
      :turtle => '# this is a complete turtle document
@prefix foo: <http://example.org/ns#> .
@prefix : <http://other.example.org/ns#> .
foo:bar foo: : .',
      :rdfxml => '<?xml version="1.0" encoding="utf-8"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><rdf:Description rdf:about="http://example.com/concepts#two-dimensional_seismic_imaging"><ns0:label xmlns:ns0="http://www.w3.org/2000/01/rdf-schema#" xml:lang="en">2-D seismic imaging</ns0:label></rdf:Description></rdf:RDF>'
    }
  end

  def base_uri
    {
      :ntriples => nil,
      :turtle => 'http://example.com/concepts',
      :rdfxml => 'http://example.com/concepts'
    }
  end

end
