module CocoapodsDiff
  NAME = "cocoapods-diff"
  VERSION = "0.8.1"
  SUMMARY = "Shows the diff between two versions of a pod."
  DESCRIPTION = <<-DESC
    A Cocoapods plugin that shows the diff between two versions of a pod. 
    It can generate a markdown showing the diff or create the Podfile for the specified versions including all the subspecs and its dependencies.   
  DESC

  # CLAide Arguments
  POD_NAME_ARGUMENT_NAME = "POD_NAME"
  OLDER_VERSION_ARGUMENT_NAME = "OLDER_VERSION"
  NEWER_VERSION_ARGUMENT_NAME = "NEWER_VERSION"

  # CLAide Flags
  REGEX_FLAG_NAME = "regex"
  INCLUDE_DEPENDENCIES_FLAG_NAME = "include-dependencies"

  # CLAide Options
  PLATFORMS_OPTION_NAME = "platforms"
  MARKDOWN_OPTION_NAME = "markdown"
  OLDER_PODFILE_OPTION_NAME = "older-podfile"
  NEWER_PODFILE_OPTION_NAME = "newer-podfile"
end
