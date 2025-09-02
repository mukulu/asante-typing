; Inno Setup script for Asante Typing (Windows)
; Place this file in the repository root and compile with ISCC.
; You may pass /DMyAppVersion=1.2.3 and /DMyAppExeName=asante_typing.exe.

#define MyAppName       "Asante Typing"
#define MyAppPublisher  "John Francis Mukulu"
#define MyAppURL        "https://mukulu.org/asante-typing"

; ----- Version handling -----
#ifdef MyAppVersion
  #define AppVer MyAppVersion
#else
  #define AppVer "0.1.0"
#endif

; ----- Executable name (the .exe inside your Release folder) -----
#ifdef MyAppExeName
  #define AppExeName MyAppExeName
#else
  ; Default Flutter exe name; change if your project produces a different name
  #define AppExeName "asante_typing.exe"
#endif

; ----- Paths (relative to this .iss location) -----
#define BuildDir        AddBackslash(SourcePath) + "build\\windows\\x64\\runner\\Release"
#define LicenseFilePath AddBackslash(SourcePath) + "LICENSE"
#define SetupIconPath   AddBackslash(SourcePath) + "windows\\runner\\resources\\app_icon.ico"

[Setup]
AppId={{BBA9B65E-DBB4-4B1D-9D84-8A9D54A8F1B4}  ; any stable GUID is fine
AppName={#MyAppName}
AppVersion={#AppVer}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
LicenseFile={#LicenseFilePath}
SetupIconFile={#SetupIconPath}
UninstallDisplayIcon={app}\{#AppExeName}
; Let build script set /O... ; fallback if compiled manually:
OutputDir=dist\windows
OutputBaseFilename={#MyAppName}-{#AppVer}-Setup
ArchitecturesInstallIn64BitMode=x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
DisableDirPage=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; Install everything from the Flutter release output folder
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent