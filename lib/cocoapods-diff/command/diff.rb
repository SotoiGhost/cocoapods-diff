require 'cocoapods-diff/version'
require 'cocoapods-diff/diffinformative'

module Pod
  class Command
    class Diff < Command
      require 'pathname'

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
          ["--#{CocoapodsDiff::INCLUDE_DEPENDENCIES_FLAG_NAME}", "Include dependencies in diff."],
          ["--#{CocoapodsDiff::PLATFORMS_OPTION_NAME}", "Platforms to be compared. If not set, all platforms will be compared. Example: --#{CocoapodsDiff::PLATFORMS_OPTION_NAME}=ios,tvos"],
          ["--#{CocoapodsDiff::MARKDOWN_OPTION_NAME}", "Output a markdown file with diffs. Example: --#{CocoapodsDiff::MARKDOWN_OPTION_NAME}=path/to/save/markdown_name.md"],
          ["--#{CocoapodsDiff::NEWER_PODFILE_OPTION_NAME}", "Output a Podfile with the newer's versions. Example: --#{CocoapodsDiff::NEWER_PODFILE_OPTION_NAME}=path/to/save/Podfile_name"],
          ["--#{CocoapodsDiff::OLDER_PODFILE_OPTION_NAME}", "Output a Podfile with the older's versions. Example: --#{CocoapodsDiff::NEWER_PODFILE_OPTION_NAME}=path/to/save/Podfile_name"]
        ].concat(super)
      end

      def initialize(argv)
        # Let's get all the command line arguments.
        @pod_name = argv.shift_argument
        @older_version = argv.shift_argument
        @newer_version = argv.shift_argument
        @use_regex = argv.flag?(CocoapodsDiff::REGEX_FLAG_NAME)
        @include_dependencies = argv.flag?(CocoapodsDiff::INCLUDE_DEPENDENCIES_FLAG_NAME)
        @platforms = argv.option(CocoapodsDiff::PLATFORMS_OPTION_NAME, "").split(",")
        @markdown_path = argv.option(CocoapodsDiff::MARKDOWN_OPTION_NAME)
        @newer_podfile_path = argv.option(CocoapodsDiff::NEWER_PODFILE_OPTION_NAME)
        @older_podfile_path = argv.option(CocoapodsDiff::OLDER_PODFILE_OPTION_NAME)
        @print_diff = @markdown_path.nil? && @newer_podfile_path.nil? && @older_podfile_path.nil?
        super
      end

      def validate!
        super

        # Valdiate the required arguments.
        help! "A Pod name is required." unless @pod_name
        help! "An old Version is required." unless @older_version
        help! "A new Version is required." unless @newer_version
        help! "Versions should be different." if @older_version === @newer_version

        # Reverse versions if the newer version is smaller than the older one.
        @older_version, @newer_version = @newer_version, @older_version if Pod::Version.new(@newer_version) < Pod::Version.new(@older_version)

        # Validate that the Podspecs with the specified versions exist by using the `pod spec which` command.
        # Arguments needed for the command.
        args = [@pod_name]
        args += ["--#{CocoapodsDiff::REGEX_FLAG_NAME}"] if @use_regex

        # Podspec with the older version validation
        begin
          older_which_spec = Pod::Command::Spec::Which.new CLAide::ARGV.new(args + ["--version=#{@older_version}"])
          older_which_spec.run
        rescue Pod::Informative => e
          raise DiffInformative, "There was a problem trying to locate the pod #{@pod_name} (#{@older_version})\n" +
            "Original error message: #{e.message}"
        end

        # Podspec with the newer version validation
        begin
          newer_which_spec = Pod::Command::Spec::Which.new CLAide::ARGV.new(args + ["--version=#{@newer_version}"])
          newer_which_spec.run
        rescue Pod::Informative => e
          raise DiffInformative, "There was a problem trying to locate the pod #{@pod_name} (#{@newer_version})\n" +
            "Original error message: #{e.message}"
        end
      end

      def run
        # As we already validate the arguments provided, it's safe to get the podspecs.
        older_spec = get_specification_for_version(@older_version)
        newer_spec = get_specification_for_version(@newer_version)

        # Warn the user if there's no subspecs to compare.
        if older_spec.subspecs.empty? && newer_spec.subspecs.empty?
          return UI.warn "There's nothing to compare for #{@pod_name} #{@older_version} vs. #{@newer_version}"
        end
        
        # Remove the default subspecs value to compare all the subspecs if any
        older_spec.default_subspecs = []
        newer_spec.default_subspecs = []

        # Get all the supported platforms without the OS version if no platforms are specified
        @platforms = (newer_spec.available_platforms.map(&:name) | older_spec.available_platforms.map(&:name)) if @platforms.empty?
        @platforms.map! { |platform| Pod::Platform.new(platform) }

        # Split the subspecs per platform now as we can use them multiple times
        @older_subspecs = {}
        @newer_subspecs = {}
        @platforms.each do |platform|
          @older_subspecs[platform.name] = older_spec.subspecs.select { |s| s.supported_on_platform?(platform) }
          @newer_subspecs[platform.name] = newer_spec.subspecs.select { |s| s.supported_on_platform?(platform) }
        end

        # Get the dependencies specs of this spec
        get_dependencies_specs(@older_version, @older_subspecs) if @include_dependencies
        get_dependencies_specs(@newer_version, @newer_subspecs) if @include_dependencies

        # If no markdown or podfile options are passed, just print the diff on console
        if @print_diff
          return UI.title "Calculating diff" do
            UI.puts generate_diff_table
          end
        end

        if @markdown_path
          UI.title "Generating the Markdown file at #{@markdown_path}" do
            generate_markdown_file
          end
        end

        if @newer_podfile_path
          UI.title "Generating the Podfile for #{newer_spec.name} #{newer_spec.version} at #{@newer_podfile_path}" do
            generate_podfile_file(@newer_podfile_path, newer_spec.version, @newer_subspecs)
          end
        end

        if @older_podfile_path
          UI.title "Generating the Podfile for #{older_spec.name} #{older_spec.version} at #{@older_podfile_path}" do
            generate_podfile_file(@older_podfile_path, older_spec.version, @older_subspecs)
          end
        end
      end

      private

      # Gets the podspec for an specific version
      def get_specification_for_version(version)
        query = @use_regex ? @pod_name : Regexp.escape(@pod_name)
        set = config.sources_manager.search_by_name(query).first
        spec_path = set.specification_paths_for_version(Pod::Version.new(version)).first
        Pod::Specification.from_file(spec_path)
      end

      # Get the dependencies specs of this spec
      def get_dependencies_specs(version, subspecs)
        podfile = podfile(version, subspecs)
        specs = Pod::Installer::Analyzer.new(config.sandbox, podfile).analyze.specs_by_target

        @platforms.each do |platform|
          key = specs.keys.find { |key| key.name.end_with?(platform.name.to_s) }
          next if key.nil?
          subspecs[platform.name] = specs[key]
        end
      end

      # Generates the diff table between versions to be printed
      def generate_diff_table
        # TODO: Diff every property between podspecs (:attributes_hash)

        diff = "# #{@pod_name}\n"

        @platforms.each do |platform|
          # Get a hash with the needed data: { name: => minimum supported version }
          older_subspecs_data = @older_subspecs[platform.name].each_with_object({}) { |subspec, hash| hash[subspec.name.to_sym] = subspec.deployment_target(platform.name) || "Not defined" }
          newer_subspecs_data = @newer_subspecs[platform.name].each_with_object({}) { |subspec, hash| hash[subspec.name.to_sym] = subspec.deployment_target(platform.name) || "Not defined" }
          
          all_names = (newer_subspecs_data.keys | older_subspecs_data.keys)
          name_header = "Name"
          version_header = "Minimum Supported Version"
          
          # Calculate the cell length to print a pretty table
          name_cell_length = all_names.max_by(&:length).length
          name_cell_length = [name_cell_length, name_header.length].max
          version_cell_length = (newer_subspecs_data.values | older_subspecs_data.values).max_by(&:length).length
          version_cell_length = [version_cell_length, version_header.length].max
          
          # Build the table
          diff += "\n## #{platform.name} #{@older_version} vs. #{@newer_version}\n\n" # Table title
          diff += "| #{name_header.ljust(name_cell_length)} | #{version_header.ljust(version_cell_length)} | #{name_header.ljust(name_cell_length)} | #{version_header.ljust(version_cell_length)} |\n" # Headers
          diff += "|-#{"".ljust(name_cell_length, "-")}:|:#{"".ljust(version_cell_length, "-")}-|-#{"".ljust(name_cell_length, "-")}:|:#{"".ljust(version_cell_length, "-")}-|\n" # Columns aligment
          
          # Table body
          all_names.each do |name|
            older_name = older_subspecs_data.keys.include?(name) ? name.to_s : ""
            older_version = older_subspecs_data[name] || ""
            newer_name = newer_subspecs_data.keys.include?(name) ? name.to_s : ""
            newer_version = newer_subspecs_data[name] || ""

            diff += "| #{older_name.ljust(name_cell_length)} | #{older_version.ljust(version_cell_length)} | #{newer_name.ljust(name_cell_length)} | #{newer_version.ljust(version_cell_length)} |\n"
          end

          diff += "\n"
        end
        diff
      end

      def generate_markdown_file
        markdown_pathname = Pathname.new(@markdown_path)
        markdown_pathname.dirname.mkpath
        markdown_pathname.write(generate_diff_table)
      end

      def generate_podfile_file(path, version, subspecs)
        podfile = "install! 'cocoapods', integrate_targets: false\n"
        podfile += "use_frameworks!\n"

        @platforms.each do |platform|
          next if subspecs[platform.name].empty?
          platform_version = subspecs[platform.name].map { |subspec| Pod::Version.new(subspec.deployment_target(platform.name) || "0") }.max

          podfile += "\ntarget '#{@pod_name}_#{platform.name}' do\n"
          podfile += "\tplatform :#{platform.name}, '#{platform_version}'\n"
          podfile += "\tpod '#{@pod_name}', '#{version}'\n"

          subspecs[platform.name].each { |subspec| podfile += "\tpod '#{subspec.name}', '#{subspec.version}'\n" }
          podfile += "end\n"
        end
        
        podfile_pathname = Pathname.new(path)
        podfile_pathname.dirname.mkpath
        podfile_pathname.write(podfile)
      end

      def podfile(version, subspecs)
        ps = @platforms
        pod_name = @pod_name
        
        Pod::Podfile.new do
          install! 'cocoapods', integrate_targets: false
          use_frameworks!

          ps.each do |p|
            next if subspecs[p.name].empty?
            platform_version = subspecs[p.name].map { |subspec| subspec.deployment_target(p.name) }.max
            
            target "#{pod_name}_#{p.name}" do
              platform p.name, platform_version
              pod pod_name, version
              subspecs[p.name].each { |subspec| pod subspec.name, subspec.version }
            end
          end
        end
      end

    end
  end
end
