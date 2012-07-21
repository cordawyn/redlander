require "spec_helper"

describe Statement do
  subject { described_class.new(statement_attributes) }

  context "with default values" do
    subject { described_class.new }

    it "should have nil subject" do
      subject.subject.should be_nil
    end

    it "should have nil predicate" do
      subject.predicate.should be_nil
    end

    it "should have nil object" do
      subject.object.should be_nil
    end

    [:subject, :predicate, :object].each do |attribute|
      it "should be assigned a #{attribute}" do
        attr = Node.new(statement_attributes[attribute])
        expect {
          subject.send("#{attribute}=", attr)
        }.to change(subject, attribute).from(nil).to(attr)
      end
    end
  end

  it "should be created with the given values" do
    subject.subject.should be_an_instance_of(Node)
    subject.predicate.should be_an_instance_of(Node)
    subject.object.should be_an_instance_of(Node)
  end

  it "should have proper attributes" do
    subject.subject.value.to_s.should eql('http://example.com/concepts#subject')
    subject.predicate.value.to_s.should eql('http://example.com/concepts#label')
    subject.object.value.should eql('subject!')
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
