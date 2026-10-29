; Script generated for HH Tech Hub ERP Inno Setup Installer

#define MyAppName "HH Tech Hub ERP"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "HH Tech Hub"
#define MyAppURL "https://hhtechhub.com"
#define MyAppExeName "software_house_erp.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
AppId={{D37B4785-3A21-4E89-9A24-F8E1528652A1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; Output location and setup filename
OutputDir=c:\Users\M HASEEB\Desktop\HHTechSoftwareHouseERP-main\build\installer
OutputBaseFilename=HHTechERP_Setup_v1.0.0
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main Executable
Source: "c:\Users\M HASEEB\Desktop\HHTechSoftwareHouseERP-main\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; All DLLs and Data folder
Source: "c:\Users\M HASEEB\Desktop\HHTechSoftwareHouseERP-main\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
