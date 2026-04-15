; Inno Setup Script for Kasir Digital
; Script generated with Inno Setup 6.0 or higher

[Setup]
AppId={{A1F082B8-85C1-4A6A-8AB4-0D3057D516D6}
AppName=Kasir Digital
AppVersion=1.2.11
AppPublisher=Kasir Digital
DefaultDirName={localappdata}\Kasir Digital
DefaultGroupName=Kasir Digital
AllowNoIcons=yes
OutputDir=build\windows\installer
OutputBaseFilename=KasirDigital_Installer
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
CloseApplications=yes
RestartApplications=yes
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\kasir_digital.exe
VersionInfoCompany=Kasir Digital
VersionInfoDescription=Kasir Digital Installer
VersionInfoVersion=1.2.11
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

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
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Kasir Digital"; Filename: "{app}\kasir_digital.exe"
Name: "{group}\Uninstall Kasir Digital"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Kasir Digital"; Filename: "{app}\kasir_digital.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\kasir_digital.exe"; Description: "{cm:LaunchProgram,Kasir Digital}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: dirifempty; Name: "{app}"
