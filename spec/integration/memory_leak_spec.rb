require "spec_helper"

describe "memory leak" do
  context "when calling Model#find twice" do
    before do
      @model = Model.new
      @model.statements.create(statement_attributes)
    end

    it "should not occur" do
      2.times { @model.statements.first }
    end
  end

  private

  def statement_attributes
    {
      :subject => URI.parse("http://example.com/subject"),
      :predicate => URI.parse("http://example.com/predicate"),
      :object => URI.parse("object!")
    }
  end
end
