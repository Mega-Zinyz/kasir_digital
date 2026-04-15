; Inno Setup Script for Kasir Digital
; Script generated with Inno Setup 6.0 or higher

[Setup]
AppName=Kasir Digital
AppVersion=1.0.0
AppPublisher=Your Company
AppPublisherURL=https://www.example.com
AppSupportURL=https://www.example.com
AppUpdatesURL=https://www.example.com
DefaultDirName={autopf}\Kasir Digital
DefaultGroupName=Kasir Digital
AllowNoIcons=yes
LicenseFile=
OutputDir=build\windows\installer
OutputBaseFilename=KasirDigital_Installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
CloseApplications=yes
RestartApplications=yes
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Dirs]
Name: "{app}\Backup"; Permissions: users-full
Name: "{app}\Laporan"; Permissions: users-full
Name: "{app}\assets\images"; Permissions: users-full
Name: "{app}\data"; Permissions: users-full

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\kasir_digital.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Kasir Digital"; Filename: "{app}\kasir_digital.exe"
Name: "{group}\Uninstall Kasir Digital"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Kasir Digital"; Filename: "{app}\kasir_digital.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\kasir_digital.exe"; Description: "{cm:LaunchProgram,Kasir Digital}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\Backup"
Type: filesandordirs; Name: "{app}\Laporan"
Type: filesandordirs; Name: "{app}\*"
Type: dirifempty; Name: "{app}"
