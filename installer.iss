; === Defines ================================================================
#define SourceDir "C:\Users\JohnMukulu\development\asante-typing"
#define MyAppName "Asante Typing"
#define MyAppVersion "1.0.0"
#define MyPublisher "Mukulu"
#define MyURL "https://mukulu.org"
; Most Flutter Windows apps output as asante_typing.exe (underscore). Change if yours differs.
#define MyExeName "asante_typing.exe"
#define BuildDir "build\windows\x64\runner\Release"
#define OutputDir "dist"

; === Setup ==================================================================
[Setup]
AppId={{1B7E6CC0-31A5-4C23-AE1C-FAF2E0E0A1AB}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyPublisher}
AppPublisherURL={#MyURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableDirPage=yes
DisableProgramGroupPage=yes
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x64
PrivilegesRequired=admin
Compression=lzma
SolidCompression=yes
OutputBaseFilename=AsanteTyping-{#MyAppVersion}-Setup
OutputDir={#SourceDir}\{#OutputDir}
WizardStyle=modern
; Use your Flutter app icon (exists in the default template)
SetupIconFile={#SourceDir}\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyExeName}
; Show a nice AppName in "Apps & features"
AppContact={#MyURL}
AppComments={#MyAppName} - {#MyPublisher}

; === Languages ==============================================================
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

; === Tasks (optional desktop icon) =========================================
[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

; === Files (copy the entire Release bundle) =================================
[Files]
Source: "{#SourceDir}\{#BuildDir}\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

; === Icons ==================================================================
[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyExeName}"; Tasks: desktopicon

; === Run after install ======================================================
[Run]
Filename: "{app}\{#MyExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

; === Optional niceties ======================================================
[Setup]
; Prevent installing over a running instance
CloseApplications=yes
CloseApplicationsFilter=*.exe,*.dll

; === (Optional) Version info for the installer executable ===================
[VersionInfo]
CompanyName={#MyPublisher}
FileDescription={#MyAppName} Installer
FileVersion={#MyAppVersion}
LegalCopyright=© {#MyPublisher}
ProductName={#MyAppName}
ProductVersion={#MyAppVersion}
