require 'cocoapods-diff/version'
require 'cocoapods-diff/diffinformative'

module Pod
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'pod' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `pod list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/pod/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
    class Diff < Command
      self.summary = 'Short description of cocoapods-diff.'

      self.description = <<-DESC
        Longer description of cocoapods-diff.
      DESC

      self.arguments = [
        CLAide::Argument.new(CocoapodsDiff::POD_NAME_ARGUMENT_NAME, true, false),
        CLAide::Argument.new(CocoapodsDiff::OLDER_VERSION_ARGUMENT_NAME, true, false),
        CLAide::Argument.new(CocoapodsDiff::NEWER_VERSION_ARGUMENT_NAME, true, false),
      ]

      def self.options
        [
          ["--#{CocoapodsDiff::REGEX_FLAG_NAME}", "Interpret the `POD_NAME` as a regular expression"],
          ["--#{CocoapodsDiff::MARKDOWN_OPTION_NAME}", "Output a markdown file with diffs. Example: --#{CocoapodsDiff::MARKDOWN_OPTION_NAME}=path/to/save/markdown_name.md"],
        ].concat(super)
      end

      def initialize(argv)
        @pod_name = argv.shift_argument
        @older_version = argv.shift_argument
        @newer_version = argv.shift_argument
        @use_regex = argv.flag?(CocoapodsDiff::REGEX_FLAG_NAME)
        @markdown_path = argv.option(CocoapodsDiff::MARKDOWN_OPTION_NAME)
        @print_diff = @markdown_path.nil?
        super
      end

      def validate!
        super
        help! "A Pod name is required." unless @pod_name
        help! "An old Version is required." unless @older_version
        help! "A new Version is required." unless @newer_version
        help! "Versions should be different." if @older_version === @newer_version

        @older_version, @newer_version = @newer_version, @older_version if Gem::Version.new(@newer_version) < Gem::Version.new(@older_version)

        params = [@pod_name]
        params += ["--#{CocoapodsDiff::REGEX_FLAG_NAME}"] if @use_regex

        begin 
          older_which_spec = Pod::Command::Spec::Which.new CLAide::ARGV.new(params + ["--version=#{@older_version}"])
          older_which_spec.run
        rescue Pod::Informative => e
          raise DiffInformative, "There was a problem trying to locate the pod #{@pod_name} (#{@older_version})\n" +
            "Original error message: #{e.message}"
        end

        begin
          newer_which_spec = Pod::Command::Spec::Which.new CLAide::ARGV.new(params + ["--version=#{@newer_version}"])
          newer_which_spec.run
        rescue Pod::Informative => e
          raise DiffInformative, "There was a problem trying to locate the pod #{@pod_name} (#{@newer_version})\n" +
            "Original error message: #{e.message}"
        end
      end

      def run
        @older_spec = get_specification_for_version(@older_version)
        @newer_spec = get_specification_for_version(@newer_version)

        @older_spec.default_subspecs = []
        @newer_spec.default_subspecs = []

        if @print_diff
          return UI.title "Calculating diff" do
            UI.puts generate_diff_table
          end
        end

        generate_markdown if @markdown_path
      end

      def get_specification_for_version(version)
        query = @use_regex ? @pod_name : Regexp.escape(@pod_name)
        set = config.sources_manager.search_by_name(query).first
        spec_path = set.specification_paths_for_version(Pod::Version.new(version)).first
        Pod::Specification.from_file(spec_path)
      end

      def generate_diff_table
        older_subspecs_names = @older_spec.subspecs.map(&:name)
        newer_subspecs_names = @newer_spec.subspecs.map(&:name)
        all_names = (newer_subspecs_names | older_subspecs_names)
        max_length = all_names.max_by(&:length).length

        diff = "# #{@pod_name}\n"
        diff += "| #{@older_version.ljust(max_length)} | #{@newer_version.ljust(max_length)} |\n"
        diff += "|-#{"-".ljust(max_length, "-")}:|:#{"-".ljust(max_length, "-")}-|\n"
        all_names.map! do |name|
          left_name = older_subspecs_names.include?(name) ? name : ""
          right_name = newer_subspecs_names.include?(name) ? name : ""
          "| #{left_name.ljust(max_length)} | #{right_name.ljust(max_length)} |\n"
        end
        diff + all_names.join()
      end

      def generate_markdown
        require 'pathname'
        markdown_pathname = Pathname.new(@markdown_path)
        markdown_pathname.dirname.mkpath
        markdown_pathname.write(generate_diff_table)
      end

      def build_podfile(spec, platforms)
        Podfile.new do
          install! "cocoapods", integrate_targets: false
          use_frameworks!
          platform platform_name, platform_version
          pod podspec.name, podspec: podspec.defined_in_file
          target "Dependencies"
        end

        @podfile ||= begin
          if podspec = @podspec
            platform = podspec.available_platforms.first
            platform_name = platform.name
            platform_version = platform.deployment_target.to_s
            source_urls = Config.instance.sources_manager.all.map(&:url).compact
            Podfile.new do
              install! 'cocoapods', integrate_targets: false, warn_for_multiple_pod_sources: false
              source_urls.each { |u| source(u) }
              platform platform_name, platform_version
              pod podspec.name, podspec: podspec.defined_in_file
              target 'Dependencies'
            end
          else
            verify_podfile_exists!
            config.podfile
          end
        end
      end
    end
  end
end
