require "spec_helper"

require 'date'

describe Node do

  describe "blank" do
    subject { Node.new }

    it { should be_blank }

    it "should have a blank identifier for a blank node" do
      subject.value.should match(/^_:\w+$/)
    end
  end

  it "should create a resource node" do
    resource_uri = URI.parse('http://example.com/nodes#node_1')
    Node.new(resource_uri).should be_resource
  end

  it "should create a literal node from a literal rdf_node" do
    node1 = Node.new("hello, world")
    node2 = Node.new(node1.rdf_node)
    node2.datatype.should_not be_nil
    node2.datatype.should eql node1.datatype
  end

  it "should create a string literal" do
    node = Node.new("hello, world")
    node.should be_literal
    node.datatype.should eql Uri.new("http://www.w3.org/2001/XMLSchema#string")
  end

  it "should create a boolean literal" do
    node = Node.new(true)
    node.should be_literal
    node.datatype.should eql Uri.new("http://www.w3.org/2001/XMLSchema#boolean")
  end

  it "should create an integer number literal" do
    node = Node.new(10)
    node.should be_literal
    node.datatype.should eql Uri.new("http://www.w3.org/2001/XMLSchema#int")
  end

  it "should create a floating-point number literal" do
    node = Node.new(3.1416)
    node.should be_literal
    node.datatype.should eql Uri.new("http://www.w3.org/2001/XMLSchema#float")
  end

  it "should create a time literal" do
    node = Node.new(Time.now)
    node.should be_literal
    node.datatype.should eql Uri.new("http://www.w3.org/2001/XMLSchema#time")
  end

  it "should create a date literal" do
    node = Node.new(Date.today)
    node.should be_literal
    node.datatype.should eql Uri.new("http://www.w3.org/2001/XMLSchema#date")
  end

  it "should create a datetime literal" do
    node = Node.new(DateTime.now)
    node.should be_literal
    node.datatype.should eql Uri.new("http://www.w3.org/2001/XMLSchema#dateTime")
  end

  it "should have proper string representation" do
    node = Node.new("Bye-bye, cruel world...")
    node.to_s.should eql('"Bye-bye, cruel world..."^^<http://www.w3.org/2001/XMLSchema#string>')
  end

  it "should have a proper value for a literal node" do
    t = Time.now
    node = Node.new(t)
    node.value.should be_an_instance_of(Time)
    # surprisingly, two instances of the same time do not compare
    node.value.xmlschema.should eql(t.xmlschema)
  end

  it "should have an instance of URI for a resource node" do
    resource_uri = URI.parse('http://example.com/nodes#node_1')
    Node.new(resource_uri).value.should be_an_instance_of(URI::HTTP)
  end

end
