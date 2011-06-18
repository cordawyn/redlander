require "spec_helper"

describe Serializer do

  it "should be created with default values" do
    lambda {
      Serializer.new
    }.should_not raise_exception
  end

  describe "model" do

    before :each do
      @model = Model.new
      s = URI.parse("http://example.com/concepts#two-dimensional_seismic_imaging")
      p = URI.parse("http://www.w3.org/2000/01/rdf-schema#label")
      o = "2-D seismic imaging@en"
      @model.statements.create(:subject => s, :predicate => p, :object => o)
    end

    [:rdfxml, :ntriples, :turtle, :dot, :json].each do |format|
      it "should be serialized into a #{format} string" do
        serializer = Serializer.new(format)
        output = serializer.to_string(@model)
        output.should be_an_instance_of(String)
        output.should_not be_empty
      end
    end

    it "should be serialized into a file" do
      cleanup
      serializer = Serializer.new(:ntriples)
      serializer.to_file(@model, filename)
      File.should be_exists(filename)
      File.size(filename).should_not be_zero
      cleanup
    end


    private

    def cleanup
      File.delete(filename) if File.exists?(filename)
    end

    def filename
      "test_model.nt"
    end

  end

end
