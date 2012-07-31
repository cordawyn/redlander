require "spec_helper"
require "date"

describe Node do
  before { @options = {} }

  describe "blank" do
    subject { described_class.new(nil, @options) }

    it { should be_blank }

    it "should have a blank identifier for a blank node" do
      subject.to_s.should eql "_:#{subject.value}"
    end

    describe "value" do
      subject { described_class.new(nil, @options).value }

      it "should be UTF-8 encoded" do
        expect(subject.encoding).to eql Encoding::UTF_8
      end

      it { should match(/^r\d+/) }

      context "when given :blank_id" do
        before { @options = {:blank_id => "blank0"} }

        it { should eql "blank0" }
      end
    end
  end

  describe "resource" do
    it "should create a resource node" do
      resource_uri = URI.parse('http://example.com/nodes#node_1')
      Node.new(resource_uri).should be_resource
    end

    it "should have an instance of URI for a resource node" do
      resource_uri = URI('http://example.com/nodes#node_1')
      Node.new(resource_uri).value.should be_an_instance_of(URI::HTTP)
    end
  end

  describe "literal" do
    it "should be created from a literal rdf_node" do
      node1 = Node.new("hello, world")
      node2 = Node.new(node1.rdf_node)
      node2.datatype.should_not be_nil
      node2.datatype.should eql node1.datatype
    end

    it "should be created from a string" do
      node = Node.new("hello, world")
      node.should be_literal
      node.datatype.should eql URI("http://www.w3.org/2001/XMLSchema#string")
    end

    it "should be created from a boolean value" do
      node = Node.new(true)
      node.should be_literal
      node.datatype.should eql URI("http://www.w3.org/2001/XMLSchema#boolean")
    end

    it "should be created from an integer value" do
      node = Node.new(10)
      node.should be_literal
      node.datatype.should eql URI("http://www.w3.org/2001/XMLSchema#integer")
    end

    it "should be created from a floating-point value" do
      node = Node.new(3.1416)
      node.should be_literal
      node.datatype.should eql URI("http://www.w3.org/2001/XMLSchema#float")
    end

    it "should be created from a time value" do
      node = Node.new(Time.now)
      node.should be_literal
      node.datatype.should eql URI("http://www.w3.org/2001/XMLSchema#time")
    end

    it "should be created from a date value" do
      node = Node.new(Date.today)
      node.should be_literal
      node.datatype.should eql URI("http://www.w3.org/2001/XMLSchema#date")
    end

    it "should be created from a datetime value" do
      node = Node.new(DateTime.now)
      node.should be_literal
      node.datatype.should eql URI("http://www.w3.org/2001/XMLSchema#dateTime")
    end

    it "should have proper string representation" do
      node = Node.new("Bye-bye, cruel world...")
      node.to_s.should eql('"Bye-bye, cruel world..."^^<http://www.w3.org/2001/XMLSchema#string>')
    end

    it "should have a properly instantiated value" do
      t = Time.now
      node = Node.new(t)
      node.value.should be_an_instance_of(Time)
      # surprisingly, two instances of the same time do not compare
      node.value.xmlschema.should eql(t.xmlschema)
    end

    it "should have UTF-9 encoded value" do
      node = Node.new("test")
      expect(node.value.encoding).to eql Encoding::UTF_8
    end
  end
end
