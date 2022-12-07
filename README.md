# cocoapods-diff

A Cocoapods plugin that shows the diff between two versions of a pod. 

It can generate a markdown showing the diff or create the Podfile for the specified versions including all the subspecs and its dependencies.

## Installation

    $ gem install cocoapods-diff

## Usage

    $ pod diff POD_NAME OLDER_VERSION NEWER_VERSION

You can pass some flags and options to generate the diff as a markdown or a Podfile:

| Option name | Description |
|---|---|
| `--regex`                | Interpret the `POD_NAME` as a regular expression |
| `--include-dependencies` | Include dependencies in diff. |
| `--platforms`            | Platforms to be compared. If not set, all platforms will be compared. Example: `--platforms=ios,tvos` |
| `--markdown`             | Output a markdown file with diffs. Example: `--markdown=path/to/save/markdown_name.md` |
| `--older-podfile`        | Output a Podfile with the newer's versions. Example: `--older-podfile=path/to/save/Podfile_name` |
| `--newer-podfile`        | Output a Podfile with the older's versions. Example: `--newer-podfile=path/to/save/Podfile_name` |

If no Markdown or Podfile options are passed, the output will be printed on console.

## Example

Running the following command:

    $ pod diff Firebase 6.0.0 10.0.0 --platforms=ios,tvos

will generate the following output:

    # Firebase

    ## ios 6.0.0 vs. 10.0.0

    | Name                                 | Minimum Supported Version | Name                                 | Minimum Supported Version |
    |-------------------------------------:|:--------------------------|-------------------------------------:|:--------------------------|
    | Firebase/Core                        | 8.0                       | Firebase/Core                        | 10.0                      |
    | Firebase/CoreOnly                    | 8.0                       | Firebase/CoreOnly                    | 10.0                      |
    | Firebase/Analytics                   | 8.0                       | Firebase/Analytics                   | 10.0                      |
    |                                      |                           | Firebase/AnalyticsWithAdIdSupport    | 10.0                      |
    |                                      |                           | Firebase/AnalyticsWithoutAdIdSupport | 10.0                      |
    | Firebase/ABTesting                   | 8.0                       | Firebase/ABTesting                   | 11.0                      |
    |                                      |                           | Firebase/AppDistribution             | 11.0                      |
    |                                      |                           | Firebase/AppCheck                    | 11.0                      |
    | Firebase/Auth                        | 8.0                       | Firebase/Auth                        | 11.0                      |
    |                                      |                           | Firebase/Crashlytics                 | 11.0                      |
    | Firebase/Database                    | 8.0                       | Firebase/Database                    | 11.0                      |
    | Firebase/DynamicLinks                | 8.0                       | Firebase/DynamicLinks                | 11.0                      |
    | Firebase/Firestore                   | 8.0                       | Firebase/Firestore                   | 11.0                      |
    | Firebase/Functions                   | 8.0                       | Firebase/Functions                   | 11.0                      |
    | Firebase/InAppMessaging              | 8.0                       | Firebase/InAppMessaging              | 11.0                      |
    |                                      |                           | Firebase/Installations               | 10.0                      |
    | Firebase/Messaging                   | 8.0                       | Firebase/Messaging                   | 11.0                      |
    |                                      |                           | Firebase/MLModelDownloader           | 11.0                      |
    | Firebase/Performance                 | 8.0                       | Firebase/Performance                 | 11.0                      |
    | Firebase/RemoteConfig                | 8.0                       | Firebase/RemoteConfig                | 11.0                      |
    | Firebase/Storage                     | 8.0                       | Firebase/Storage                     | 11.0                      |
    | Firebase/MLCommon                    | 9.0                       |                                      |                           |
    | Firebase/MLModelInterpreter          | 9.0                       |                                      |                           |
    | Firebase/MLNLLanguageID              | 9.0                       |                                      |                           |
    | Firebase/MLNLSmartReply              | 9.0                       |                                      |                           |
    | Firebase/MLNLTranslate               | 9.0                       |                                      |                           |
    | Firebase/MLNaturalLanguage           | 9.0                       |                                      |                           |
    | Firebase/MLVision                    | 9.0                       |                                      |                           |
    | Firebase/MLVisionAutoML              | 9.0                       |                                      |                           |
    | Firebase/MLVisionBarcodeModel        | 9.0                       |                                      |                           |
    | Firebase/MLVisionFaceModel           | 9.0                       |                                      |                           |
    | Firebase/MLVisionLabelModel          | 9.0                       |                                      |                           |
    | Firebase/MLVisionObjectDetection     | 9.0                       |                                      |                           |
    | Firebase/MLVisionTextModel           | 9.0                       |                                      |                           |
    | Firebase/InAppMessagingDisplay       | 8.0                       |                                      |                           |
    | Firebase/AdMob                       | 8.0                       |                                      |                           |


    ## tvos 6.0.0 vs. 10.0.0

    | Name                                 | Minimum Supported Version | Name                                 | Minimum Supported Version |
    |-------------------------------------:|:--------------------------|-------------------------------------:|:--------------------------|
    |                                      |                           | Firebase/Core                        | 12.0                      |
    |                                      |                           | Firebase/CoreOnly                    | 12.0                      |
    |                                      |                           | Firebase/Analytics                   | 12.0                      |
    |                                      |                           | Firebase/AnalyticsWithAdIdSupport    | 12.0                      |
    |                                      |                           | Firebase/AnalyticsWithoutAdIdSupport | 12.0                      |
    |                                      |                           | Firebase/ABTesting                   | 12.0                      |
    |                                      |                           | Firebase/AppCheck                    | 12.0                      |
    |                                      |                           | Firebase/Auth                        | 12.0                      |
    |                                      |                           | Firebase/Crashlytics                 | 12.0                      |
    |                                      |                           | Firebase/Database                    | 12.0                      |
    |                                      |                           | Firebase/Firestore                   | 12.0                      |
    |                                      |                           | Firebase/Functions                   | 12.0                      |
    |                                      |                           | Firebase/InAppMessaging              | 12.0                      |
    |                                      |                           | Firebase/Installations               | 12.0                      |
    |                                      |                           | Firebase/Messaging                   | 12.0                      |
    |                                      |                           | Firebase/MLModelDownloader           | 12.0                      |
    |                                      |                           | Firebase/Performance                 | 12.0                      |
    |                                      |                           | Firebase/RemoteConfig                | 12.0                      |
    |                                      |                           | Firebase/Storage                     | 12.0                      |