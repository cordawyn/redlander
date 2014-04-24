require 'spec_helper'

describe 'garbage collection' do

  describe Uri do

    it 'is garbage collected when destroyed' do
      Uri.new('http://example.com/subject')
      expect(ObjectSpace.each_object(Uri).count).to eq(1)
      GC.start
      expect(ObjectSpace.each_object(Uri).count).to eq(0)
    end 
  end

  describe Node do

    it 'is garbage collected when destroyed' do
      Node.new(test_statement[:subject])
      expect(ObjectSpace.each_object(Node).count).to eq(1)
      GC.start
      expect(ObjectSpace.each_object(Node).count).to eq(0)
    end
  end

  describe Statement do

    it 'is garbage collected when destroyed' do
      Statement.new(test_statement)
      expect(ObjectSpace.each_object(Statement).count).to eq(1)
      GC.start
      expect(ObjectSpace.each_object(Statement).count).to eq(0)
    end
  end

  describe Model do

    it 'is garbage collected when destroyed' do
      Model.new
      expect(ObjectSpace.each_object(Model).count).to eq(1)
      GC.start
      expect(ObjectSpace.each_object(Model).count).to eq(0)
    end
  end

  describe Query::Results do

    it 'is garbage collected when destroyed' do
      model = Model.new
      model.statements.add(Statement.new(test_statement))
      model.query('select * {?s ?p ?o}')
      expect(ObjectSpace.each_object(Query::Results).count).to eq(1)
      GC.start
      expect(ObjectSpace.each_object(Query::Results).count).to eq(0)
    end
  end

  it 'collects all objects after using Model' do
    model = Model.new
    expect(ObjectSpace.each_object(Model).count).to eq(1)

    model.statements.add(Statement.new(test_statement))
    expect(ObjectSpace.each_object(Node).count).to eq(3)
    expect(ObjectSpace.each_object(Statement).count).to eq(1)

    model.query('select * {?s ?p ?o}')
    expect(ObjectSpace.each_object(Node).count).to eq(6)
    expect(ObjectSpace.each_object(Query::Results).count).to eq(1)

    # allow model to be garbage collected
    model = nil

    GC.start
    expect(ObjectSpace.each_object(Model).count).to eq(0)
    expect(ObjectSpace.each_object(Statement).count).to eq(0)
    expect(ObjectSpace.each_object(Node).count).to eq(0)
    expect(ObjectSpace.each_object(Query::Results).count).to eq(0)
  end

  private

  def test_statement
    {
      :subject => URI.parse("http://example.com/subject"),
      :predicate => URI.parse("http://example.com/predicate"),
      :object => URI.parse("object!")
    }
  end
end
