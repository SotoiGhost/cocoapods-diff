require File.expand_path("../../spec_helper", __FILE__)

module Pod
  describe Command::Diff do
    describe "CLAide" do
      it "registers it self" do
        Command.parse(%w{ diff }).should.be.instance_of Command::Diff
      end

      describe "Validate the command" do
        it "is well-formed" do
          lambda { Command.parse(%w{ diff Firebase 9.0.0 10.0.0 }).validate! }
            .should.not.raise()
        end

        it "fails when a pod name is missing" do
          lambda { Command.parse(%w{ diff }).validate! }
            .should.raise(CLAide::Help)
            .message.should.match(/A Pod name is required./)
        end
  
        it "fails when a version is missing" do
          lambda { Command.parse(%w{ diff Firebase }).validate! }
            .should.raise(CLAide::Help)
            .message.should.match(/An old Version is required./)
        end
  
        it "fails when a version to compare is missing" do
          lambda { Command.parse(%w{ diff Firebase 10.0.0 }).validate! }
            .should.raise(CLAide::Help)
            .message.should.match(/A new Version is required./)
        end

        it "fails when versions are the same" do
          lambda { Command.parse(%w{ diff Firebase 10.0.0 10.0.0 }).validate! }
            .should.raise(CLAide::Help)
            .message.should.match(/Versions should be different./)
        end

        it "fails when a non-existing version is passed" do
          lambda { Command.parse(%w{ diff Firebase 10.0.0 1.0.0-beta1 }).validate! }
            .should.raise(DiffInformative)
        end

        it "fails when a more than one pod is found" do
          lambda { Command.parse(%w{ diff Fire 10.0.0 9.0.0 }).validate! }
            .should.raise(DiffInformative)
        end
      end

      describe "Test the command" do
        it "returns the diff as string" do
          diff = Command.parse(%w{ diff Firebase 6.0.0 10.0.0 })
          diff.validate!
          result = diff.run
          result.should.be.instance_of String
          result.should.not.be.empty?
        end

        it "generates the diff as markdown" do
          require 'pathname'
          markdown_pathname = Pathname.new("spec/test/Firebase.md")
          diff = Command.parse(%W{ diff Firebase 6.0.0 10.0.0 --markdown=#{markdown_pathname} })
          diff.validate!
          diff.run
          markdown_pathname.exist?.should.be.true?
          markdown_pathname.empty?.should.be.false?
        end
      end
    end
  end
end
