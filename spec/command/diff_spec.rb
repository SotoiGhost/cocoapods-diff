require File.expand_path("../../spec_helper", __FILE__)
require 'cocoapods-diff/version.rb'

module Pod
  POD_NAME = "Firebase"
  OLDER_VERSION = "6.0.0"
  NEWER_VERSION = "10.0.0"
  
  describe Command::Diff do
    describe "CLAide" do
      it "registers it self" do
        Command.parse(%W{ diff }).should.be.instance_of Command::Diff
      end

      describe "Validate the command" do
        it "is well-formed" do
          lambda { Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} #{NEWER_VERSION} }).validate! }
            .should.not.raise()
        end

        it "fails when a pod name is missing" do
          lambda { Command.parse(%W{ diff }).validate! }
            .should.raise(CLAide::Help)
            .message.should.match(/A Pod name is required./)
        end
  
        it "fails when a version is missing" do
          lambda { Command.parse(%W{ diff #{POD_NAME} }).validate! }
            .should.raise(CLAide::Help)
            .message.should.match(/An old Version is required./)
        end
  
        it "fails when a version to compare is missing" do
          lambda { Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} }).validate! }
            .should.raise(CLAide::Help)
            .message.should.match(/A new Version is required./)
        end

        it "fails when versions are the same" do
          lambda { Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} #{OLDER_VERSION} }).validate! }
            .should.raise(CLAide::Help)
            .message.should.match(/Versions should be different./)
        end

        it "fails when a non-existing version is passed" do
          lambda { Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} 1.0.0-beta1 }).validate! }
            .should.raise(DiffInformative)
        end

        it "fails when a more than one pod is found" do
          lambda { Command.parse(%W{ diff Fire #{OLDER_VERSION} 9.0.0 }).validate! }
            .should.raise(DiffInformative)
        end
      end

      describe "Test the command" do
        it "returns a warning if there's nothing to compare" do
          diff = Command.parse(%W{ diff GooglePlaces 6.0.0 7.0.0 })
          diff.validate!
          diff.run.should.match(/There's nothing to compare/)
        end

        it "returns the diff as string" do
          diff = Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} #{NEWER_VERSION} })
          diff.validate!
          result = diff.run
          result.should.be.instance_of String
          result.should.not.be.empty?
        end

        it "generates the diff as markdown" do
          require 'pathname'
          markdown_pathname = Pathname.new("spec/test/Firebase.md")
          diff = Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} #{NEWER_VERSION} --#{CocoapodsDiff::MARKDOWN_OPTION_NAME}=#{markdown_pathname} })
          diff.validate!
          diff.run
          markdown_pathname.exist?.should.be.true?
          markdown_pathname.empty?.should.be.false?
        end

        it "generates the newer Podfile" do
          require 'pathname'
          podfile_pathname = Pathname.new("spec/test/Podfile_newer")
          diff = Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} #{NEWER_VERSION} --#{CocoapodsDiff::NEWER_PODFILE_OPTION_NAME}=#{podfile_pathname} })
          diff.validate!
          diff.run
          podfile_pathname.exist?.should.be.true?
          podfile_pathname.empty?.should.be.false?
        end

        it "generates the older Podfile" do
          require 'pathname'
          podfile_pathname = Pathname.new("spec/test/Podfile_older")
          diff = Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} #{NEWER_VERSION} --#{CocoapodsDiff::OLDER_PODFILE_OPTION_NAME}=#{podfile_pathname} })
          diff.validate!
          diff.run
          podfile_pathname.exist?.should.be.true?
          podfile_pathname.empty?.should.be.false?
        end

        it "generates both Podfiles" do
          require 'pathname'
          newer_podfile_pathname = Pathname.new("spec/test/Podfile_newer")
          older_podfile_pathname = Pathname.new("spec/test/Podfile_older")
          diff = Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} #{NEWER_VERSION} --#{CocoapodsDiff::NEWER_PODFILE_OPTION_NAME}=#{newer_podfile_pathname} --#{CocoapodsDiff::OLDER_PODFILE_OPTION_NAME}=#{older_podfile_pathname} })
          diff.validate!
          diff.run
          newer_podfile_pathname.exist?.should.be.true?
          newer_podfile_pathname.empty?.should.be.false?
          older_podfile_pathname.exist?.should.be.true?
          older_podfile_pathname.empty?.should.be.false?
        end

        it "generates Markdown and Podfiles" do
          require 'pathname'
          markdown_pathname = Pathname.new("spec/test/Firebase.md")
          newer_podfile_pathname = Pathname.new("spec/test/Podfile_newer")
          older_podfile_pathname = Pathname.new("spec/test/Podfile_older")
          diff = Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} #{NEWER_VERSION} --#{CocoapodsDiff::MARKDOWN_OPTION_NAME}=#{markdown_pathname} --#{CocoapodsDiff::NEWER_PODFILE_OPTION_NAME}=#{newer_podfile_pathname} --#{CocoapodsDiff::OLDER_PODFILE_OPTION_NAME}=#{older_podfile_pathname} })
          diff.validate!
          diff.run
          markdown_pathname.exist?.should.be.true?
          markdown_pathname.empty?.should.be.false?
          newer_podfile_pathname.exist?.should.be.true?
          newer_podfile_pathname.empty?.should.be.false?
          older_podfile_pathname.exist?.should.be.true?
          older_podfile_pathname.empty?.should.be.false?
        end

        it "generates the diff with dependencies as markdown" do
          require 'pathname'
          markdown_pathname = Pathname.new("spec/test/Firebase_with_dependencies.md")
          diff = Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} #{NEWER_VERSION} --#{CocoapodsDiff::INCLUDE_DEPENDENCIES_FLAG_NAME} --#{CocoapodsDiff::MARKDOWN_OPTION_NAME}=#{markdown_pathname} })
          diff.validate!
          diff.run
          markdown_pathname.exist?.should.be.true?
          markdown_pathname.empty?.should.be.false?
        end

        it "generates the newer Podfile with dependencies" do
          require 'pathname'
          podfile_pathname = Pathname.new("spec/test/Podfile_newer_with_dependencies")
          diff = Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} #{NEWER_VERSION} --#{CocoapodsDiff::INCLUDE_DEPENDENCIES_FLAG_NAME} --#{CocoapodsDiff::NEWER_PODFILE_OPTION_NAME}=#{podfile_pathname} })
          diff.validate!
          diff.run
          podfile_pathname.exist?.should.be.true?
          podfile_pathname.empty?.should.be.false?
        end

        it "generates the older Podfile with dependencies" do
          require 'pathname'
          podfile_pathname = Pathname.new("spec/test/Podfile_older_with_dependencies")
          diff = Command.parse(%W{ diff #{POD_NAME} #{OLDER_VERSION} #{NEWER_VERSION} --#{CocoapodsDiff::INCLUDE_DEPENDENCIES_FLAG_NAME} --#{CocoapodsDiff::OLDER_PODFILE_OPTION_NAME}=#{podfile_pathname} })
          diff.validate!
          diff.run
          podfile_pathname.exist?.should.be.true?
          podfile_pathname.empty?.should.be.false?
        end
      end
    end
  end
end
