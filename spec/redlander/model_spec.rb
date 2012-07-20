require "spec_helper"

describe Model do
  let(:model) { described_class.new }
  subject { model }

  describe "statements" do
    subject { model.statements }

    it { should be_an_instance_of(ModelProxy) }

    context "when enumerated" do
      context "without a block" do
        subject { model.statements.each }

        it { should be_a Enumerator }
      end

      context "with a block" do
        before do
          @statement = subject.create(statement_attributes)
          @statements = []
        end

        it "should be iterated over" do
          expect {
            subject.each { |s| @statements << s }
          }.to change(@statements, :size).by(1)
          expect(@statements).to include @statement
        end
      end
    end

    context "when searched" do
      subject { model.statements.find(:first, @conditions) }

      before { @statement = model.statements.create(statement_attributes) }

      context "with empty conditions" do
        before { @conditions = {} }

        it { should eql @statement }
      end

      context "with matching conditions" do
        before { @conditions = {:object => @statement.object} }

        it { should eql @statement }
      end

      context "with non-matching conditions" do
        before { @conditions = {:object => "another object"} }

        it { should be_nil }
      end
    end

    it "should be created in the model" do
      expect {
        subject.create(statement_attributes)
      }.to change(subject, :size).by(1)
    end

    it "should be added to" do
      statement = Statement.new(statement_attributes)
      lambda { subject.add(statement) }.should change(subject, :size).by(1)
      subject.should include(statement)
    end

    it "should be removed from" do
      statement = subject.create(statement_attributes)
      lambda {
        subject.delete(statement)
      }.should change(subject, :size).by(-1)
      subject.should_not include(statement)
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
    before do
      s = URI.parse("http://example.com/concepts#two-dimensional_seismic_imaging")
      p = URI.parse("http://www.w3.org/2000/01/rdf-schema#label")
      o = "2-D seismic imaging@en"
      subject.statements.create(:subject => s, :predicate => p, :object => o)
    end

    it "should produce RDF/XML content" do
      content = subject.to_rdfxml
      content.should be_an_instance_of(String)
      content.should include('2-D seismic imaging')
    end

    it "should produce N-Triples content" do
      content = subject.to_ntriples
      content.should be_an_instance_of(String)
      content.should include('2-D seismic imaging@en')
    end

    it "should produce Turtle content" do
      content = subject.to_turtle
      content.should be_an_instance_of(String)
      content.should include('2-D seismic imaging@en')
    end

    it "should produce JSON content" do
      content = subject.to_json
      content.should be_an_instance_of(String)
      content.should include('2-D seismic imaging@en')
    end

    it "should produce DOT content" do
      content = subject.to_dot
      content.should be_an_instance_of(String)
      content.should include('2-D seismic imaging@en')
    end

    describe "file destination" do
      before { cleanup }

      after { cleanup }

      it "should produce a file" do
        subject.to_file(filename)
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
    context "from RDF/XML" do
      before { @filename = Redlander.fixture_path("doap.rdf") }

      it "should parse from string" do
        expect {
          subject.from_rdfxml File.read(@filename), :base_uri => "http://rubygems.org/gems/rdf"
        }.to change(subject.statements, :size).by(62)
      end

      it "should parse from URI/file" do
        expect {
          subject.from_rdfxml URI("file://" + @filename), :base_uri => "http://rubygems.org/gems/rdf"
        }.to change(subject.statements, :size).by(62)
      end

      it "should filter statements" do
        filter_object = Uri.new("http://ar.to/#self")
        expect {
          subject.from_rdfxml Uri.new("file://" + @filename), :base_uri => "http://rubygems.org/gems/rdf" do |st|
            st.object.resource? ? st.object.uri != filter_object : true
          end
        }.to change(subject.statements, :size).by(57)
      end
    end

    context "from NTriples" do
      before { @filename = Redlander.fixture_path("doap.nt") }

      it "should parse from string" do
        expect {
          subject.from_ntriples File.read(@filename)
        }.to change(subject.statements, :size).by(62)
      end

      it "should parse from URI/file" do
        expect {
          subject.from_ntriples URI("file://" + @filename)
        }.to change(subject.statements, :size).by(62)
      end
    end

    context "from Turtle" do
      before { @filename = Redlander.fixture_path("doap.ttl") }

      it "should parse from string" do
        expect {
          subject.from_turtle File.read(@filename), :base_uri => "http://rubygems.org/gems/rdf"
        }.to change(subject.statements, :size).by(62)
      end

      it "should parse from URI/file" do
        expect {
          subject.from_turtle URI("file://" + @filename), :base_uri => "http://rubygems.org/gems/rdf"
        }.to change(subject.statements, :size).by(62)
      end
    end
  end

  describe "transactions" do
    before do
      Redland.stub(:librdf_model_transaction_start => 0,
                   :librdf_model_transaction_commit => 0,
                   :librdf_model_transaction_rollback => 0)
    end

    context "when start fails" do
      before { Redland.stub(:librdf_model_transaction_start => -1) }

      it "should raise RedlandError" do
        lambda {
          subject.transaction { true }
        }.should raise_exception RedlandError
      end
    end

    context "when commit fails" do
      before { Redland.stub(:librdf_model_transaction_commit => -1) }

      it "should raise RedlandError" do
        lambda {
          subject.transaction { true }
        }.should raise_exception RedlandError
      end
    end

    context "when rollback fails" do
      before { Redland.stub(:librdf_model_transaction_rollback => -1) }

      it "should raise RedlandError" do
        lambda {
          subject.rollback
        }.should raise_exception RedlandError
      end
    end
  end
end
