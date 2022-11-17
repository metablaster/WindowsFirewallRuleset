
# Generating online help files

Brief explanation on how to make modules support updatable and online help

## Table of Contents

- [Generating online help files](#generating-online-help-files)
  - [Table of Contents](#table-of-contents)
  - [Help info xml file](#help-info-xml-file)
    - [XML help file name syntax](#xml-help-file-name-syntax)
    - [XML file content syntax](#xml-file-content-syntax)
    - [Module manifest](#module-manifest)
    - [Help info file location](#help-info-file-location)
  - [Help content cab file](#help-content-cab-file)
    - [makecab.exe syntax](#makecabexe-syntax)
    - [CAB file name syntax](#cab-file-name-syntax)
    - [CAB file content syntax](#cab-file-content-syntax)
    - [Make CAB Example](#make-cab-example)
    - [Help content location](#help-content-location)

## Help info xml file

### XML help file name syntax

```none
<ModuleName>_<ModuleGUID>_HelpInfo.xml
```

Organize help files by UICulture into separate folders, ex. for en-US:

```none
\ModulePath
    \ModuleName
        \ModuleName_ModuleGUID_HelpInfo.xml
        \en-US
            \about_ModuleName.help.txt
            \ModuleName.psm1-Help.xml
```

### XML file content syntax

[HelpInfo XML Sample File][sample helpifo]

[HelpInfo XML Schema][sample helpifo schema]

### Module manifest

```none
HelpInfoURI = "https://URL_TO/Manifest.Module_66e38822-834d-4a90-b9c6-9e600a472a0a_HelpInfo.xml"
```

### Help info file location

1. Put help info file into module root directory
2. Push module online, and take URL
3. Set `HelpInfoUri` key of the module manifest to URL

## Help content cab file

### makecab.exe syntax

```none
source         File to compress
destination    File name to give compressed file
/L dir         Location to place destination (default is current directory)
/V[n]          Verbosity level (1..3)
```

```none
makecab source destination /L TargetDir /V3
```

### CAB file name syntax

```none
<ModuleName>_<ModuleGUID>_<UICulture>_HelpContent.cab
```

Organize CAB files by module version into separate folders, ex:

- `0.6.0/Manifest.Module_66e38822-834d-4a90-b9c6-9e600a472a0a_en-US_HelpContent.cab`
- `0.7.0/Manifest.Module_66e38822-834d-4a90-b9c6-9e600a472a0a_en-US_HelpContent.cab`

### CAB file content syntax

[File Types Permitted in an Updatable Help CAB File][updatable help file types]

### Make CAB Example

```none
cd $ProjectRoot
makecab.exe Templates\Manifest.Module\Manifest.Module.help.txt Manifest.Module_66e38822-834d-4a90-b9c6-9e600a472a0a_en-US_HelpContent.cab /V3 /L Config\HelpContent
```

### Help content location

1. Put cab file somewhere into repository outside module directory
2. Push repository and take URL to online directory containing cab file
3. Put URL into `HelpContentUri` element in the HelpInfo XML file

[Table of Contents](#table-of-contents)

[sample helpifo]: https://docs.microsoft.com/en-us/powershell/scripting/developer/help/helpinfo-xml-sample-file?view=powershell-7
[sample helpifo schema]: https://docs.microsoft.com/en-us/powershell/scripting/developer/help/helpinfo-xml-schema?view=powershell-7
[updatable help file types]: https://docs.microsoft.com/en-us/powershell/scripting/developer/help/file-types-permitted-in-an-updatable-help-cab-file?view=powershell-7
