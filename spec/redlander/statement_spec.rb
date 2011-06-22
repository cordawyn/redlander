require "spec_helper"

describe Statement do

  it "should be created with default values" do
    statement = nil
    lambda { statement = Statement.new }.should_not raise_exception
    statement.subject.should be_nil
    statement.predicate.should be_nil
    statement.object.should be_nil
  end

  it "should be created with the given values" do
    statement = create_statement
    statement.subject.should be_an_instance_of(Node)
    statement.predicate.should be_an_instance_of(Node)
    statement.object.should be_an_instance_of(Node)
  end

  it "should have proper attributes" do
    statement = create_statement
    statement.subject.value.to_s.should eql('http://example.com/concepts#subject')
    statement.predicate.value.to_s.should eql('http://example.com/concepts#label')
    statement.object.value.should eql('subject!')
  end

  it do
    statement = Statement.new
    lambda {
      statement.should_not be_valid
    }.should change(statement.errors, :size).by(1)
  end

  it do
    create_statement.should be_valid
  end

  [:subject, :predicate, :object].each do |attribute|
    it "should be assigned a #{attribute}" do
      statement = Statement.new
      attr = Node.new(statement_attributes[attribute])
      lambda {
        statement.send("#{attribute}=", attr)
      }.should change(statement, attribute).from(nil).to(attr)
    end
  end

  it "should not be assigned the same attribute twice" do
    statement = Statement.new
    object = "object!"
    lambda {
      2.times do
        statement.object = object
      end
    }.should raise_exception
    object.should be_frozen
  end


  private

  def create_statement
    Statement.new(statement_attributes)
  end

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
