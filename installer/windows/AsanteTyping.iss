#define AppName       "Asante Typing"
#define AppExe        "asante_typing.exe"
#define AppVersion    GetEnv("AppVersion")
#define SourceDir     "build\windows\x64\runner\Release"
#define OutputDir     "dist\windows"

[Setup]
AppId={{C92C9E0C-6A39-4D2C-9E4C-1A9C3E5A7F11}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={pf}\{#AppName}
DefaultGroupName={#AppName}
DisableDirPage=yes
DisableProgramGroupPage=yes
OutputBaseFilename=AsanteTyping-Setup-{#AppVersion}
Compression=lzma
SolidCompression=yes
OutputDir={#OutputDir}
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{commondesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Run]
Filename: "{app}\{#AppExe}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent
