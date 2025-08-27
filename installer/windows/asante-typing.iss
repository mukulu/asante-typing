; --- Asante Typing Windows Installer (Inno Setup) ---

#define MyAppName      "Asante Typing"
#define MyAppExe       "asante_typing.exe"
#define MyPublisher    "Mukulu"
#define MyURL          "https://mukulu.org/asante-typing/"
#define MyLicenseFile  "LICENSE"     ; optional, keep if present
#define MyIconIco      "windows\runner\resources\app_icon.ico"

; Pull version from command line: iscc /DMyAppVersion=1.0.0 installer\asante-typing.iss
#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

[Setup]
AppId={{5E6D1E6E-9B7A-4F22-9B6A-8A16A9C7A1A1}  ; GUID; generate your own once and keep it stable
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyPublisher}
AppPublisherURL={#MyURL}
AppSupportURL={#MyURL}
AppUpdatesURL={#MyURL}
DefaultDirName={userappdata}\Programs\{#MyAppName}     ; per-user install (no admin prompt)
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=dist\windows
OutputBaseFilename=AsanteTypingSetup_{#MyAppVersion}
Compression=lzma
SolidCompression=yes
SetupIconFile={#MyIconIco}
UninstallDisplayIcon={app}\{#MyAppExe}
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=lowest
WizardStyle=modern
DisableWelcomePage=no
LicenseFile={#MyLicenseFile}    ; comment this line out if you don’t want a license page

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; Ship the compiled Flutter bundle (Release folder)
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
; Start Menu shortcut
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; IconFilename: "{app}\{#MyAppExe}"
; Desktop shortcut (optional task)
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExe}"; Tasks: desktopicon; IconFilename: "{app}\{#MyAppExe}"

[Run]
; Offer to run after install
Filename: "{app}\{#MyAppExe}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
