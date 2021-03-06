unit UFRMPascalCoinWalletConfig;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{ Copyright (c) 2016 by Albert Molina

  Distributed under the MIT software license, see the accompanying file LICENSE
  or visit http://www.opensource.org/licenses/mit-license.php.

  This unit is a part of Pascal Coin, a P2P crypto currency without need of
  historical operations.

  If you like it, consider a donation using BitCoin:
  16K3HCZRhFUtM8GdWRcfKeaa6KsuyxZaYk

  }

interface

uses
{$IFnDEF FPC}
  Windows,
  ShellApi,
{$ELSE}
  LCLIntf, LCLType, LMessages,
{$ENDIF}
  Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ComCtrls, UAppParams, UWalletKeys;

type

  TMinerPrivateKey = (mpk_NewEachTime, mpk_Random, mpk_Selected);

  { TFRMPascalCoinWalletConfig }

  TFRMPascalCoinWalletConfig = class(TForm)
    cbJSONRPCMinerServerActive: TCheckBox;
    ebDefaultFee: TEdit;
    lbMiningServerBindIpDefault: TLabel;
    lbRpcServerBindIpDefault: TLabel;
    RPCServerPort: TEdit;
    MiningServerIp: TEdit;
    Label8: TLabel;
    RPCServerPortDefault: TLabel;
    RPCServerIp: TEdit;
    Label1: TLabel;
    cbSaveLogFiles: TCheckBox;
    cbShowLogs: TCheckBox;
    bbOk: TBitBtn;
    bbCancel: TBitBtn;
    Label6: TLabel;
    Label7: TLabel;
    udInternetServerPort: TUpDown;
    ebInternetServerPort: TEdit;
    Label2: TLabel;
    InternetServerPortDefault: TLabel;
    bbUpdatePassword: TBitBtn;
    Label3: TLabel;
    ebMinerName: TEdit;
    Label4: TLabel;
    cbShowModalMessages: TCheckBox;
    Label5: TLabel;
    udJSONRPCMinerServerPort: TUpDown;
    ebJSONRPCMinerServerPort: TEdit;
    lblDefaultJSONRPCMinerServerPort: TLabel;
    gbMinerPrivateKey: TGroupBox;
    rbGenerateANewPrivateKeyEachBlock: TRadioButton;
    rbUseARandomKey: TRadioButton;
    rbMineAllwaysWithThisKey: TRadioButton;
    cbPrivateKeyToMine: TComboBox;
    cbSaveDebugLogs: TCheckBox;
    bbOpenDataFolder: TBitBtn;
    udRPCServerPort: TUpDown;
    procedure FormCreate(Sender: TObject);
    procedure bbOkClick(Sender: TObject);
    procedure bbUpdatePasswordClick(Sender: TObject);
    procedure cbSaveLogFilesClick(Sender: TObject);
    procedure bbOpenDataFolderClick(Sender: TObject);
  private
    FAppParams: TAppParams;
    FWalletKeys: TWalletKeys;
    procedure SetAppParams(const Value: TAppParams);
    procedure SetWalletKeys(const Value: TWalletKeys);
    Procedure UpdateWalletConfig;
  public
    Property AppParams : TAppParams read FAppParams write SetAppParams;
    Property WalletKeys : TWalletKeys read FWalletKeys write SetWalletKeys;
  end;

implementation

uses UConst, UAccounts, ULog, UCrypto, UFolderHelper;

{$IFnDEF FPC}
  {$R *.dfm}
{$ELSE}
  {$R *.lfm}
{$ENDIF}

procedure TFRMPascalCoinWalletConfig.bbOkClick(Sender: TObject);
Var
  df : Int64;
  mpk : TMinerPrivateKey;
  i : Integer;
  rawKey : AnsiString;
  hexKey : AnsiString;
begin
  if udInternetServerPort.Position = udJSONRPCMinerServerPort.Position then raise Exception.Create('Internet server port and Mining server port are equal!');
  if udInternetServerPort.Position = udRPCServerPort.Position then raise Exception.Create('Internet server port and RPC server port are equal!');
  if udRPCServerPort.Position = udJSONRPCMinerServerPort.Position then raise Exception.Create('RPC server port and Mining server port are equal!');

  if TAccountComp.TxtToMoney(ebDefaultFee.Text, df) then begin
    AppParams.SetValue(CT_PARAM_DefaultFee, df);
  end else begin
    ebDefaultFee.Text := TAccountComp.FormatMoney(AppParams.GetValue(CT_PARAM_DefaultFee, 0));
    raise Exception.Create('Invalid Fee value');
  end;

  AppParams.SetValue(CT_PARAM_InternetServerPort, udInternetServerPort.Position);
  AppParams.SetValue(CT_PARAM_RPC_BIND_IP, RPCServerIp.Text);
  AppParams.SetValue(CT_PARAM_RPC_PORT, udRPCServerPort.Position);
  AppParams.SetValue(CT_PARAM_MINING_SERVER_BIND_IP, MiningServerIp.Text);
  AppParams.SetValue(CT_PARAM_MINING_SERVER_PORT, udJSONRPCMinerServerPort.Position);

  if rbGenerateANewPrivateKeyEachBlock.Checked then mpk := mpk_NewEachTime
  else if rbUseARandomKey.Checked then mpk := mpk_Random
  else if rbMineAllwaysWithThisKey.Checked then begin
    mpk := mpk_Selected;
    if cbPrivateKeyToMine.ItemIndex<0 then raise Exception.Create('Must select a private key');
    i := PtrInt(cbPrivateKeyToMine.Items.Objects[cbPrivateKeyToMine.ItemIndex]);
    if (i<0) Or (i>=FWalletKeys.Count) then raise Exception.Create('Invalid private key');
    rawKey := TAccountComp.AccountKey2RawString(FWalletKeys.Key[i].AccountKey);
    SetLength(hexKey, Length(rawKey) * 2);
    BinToHex(@rawKey[1], @hexKey[1], Length(rawKey));
    AppParams.SetValue(CT_PARAM_MinerPrivateKeySelectedPublicKey, hexKey);
  end else mpk := mpk_Random;

  AppParams.SetValue(CT_PARAM_MinerPrivateKeyType, integer(mpk));
  AppParams.SetValue(CT_PARAM_MINING_SERVER_ACTIVE, cbJSONRPCMinerServerActive.Checked );
  AppParams.SetValue(CT_PARAM_SaveLogFiles, cbSaveLogFiles.Checked );
  AppParams.SetValue(CT_PARAM_ShowLogs, cbShowLogs.Checked );
  AppParams.SetValue(CT_PARAM_SaveDebugLogs, cbSaveDebugLogs.Checked);
  AppParams.SetValue(CT_PARAM_MINER_NAME, ebMinerName.Text);
  AppParams.SetValue(CT_PARAM_ShowModalMessages, cbShowModalMessages.Checked);

  ModalResult := MrOk;
end;

procedure TFRMPascalCoinWalletConfig.bbOpenDataFolderClick(Sender: TObject);
begin
  {$IFDEF FPC}
  OpenDocument(pchar(TFolderHelper.GetPascalCoinDataFolder))
  {$ELSE}
  shellexecute(0, 'open', pchar(TFolderHelper.GetPascalCoinDataFolder), nil, nil, SW_SHOW)
  {$ENDIF}
end;

procedure TFRMPascalCoinWalletConfig.bbUpdatePasswordClick(Sender: TObject);
Var s,s2 : String;
begin
  if Not Assigned(FWalletKeys) then exit;
  if Not FWalletKeys.IsValidPassword then begin
    s := '';
    Repeat
      if Not InputQuery('Wallet Password','Insert Wallet Password',s) then exit;
      FWalletKeys.WalletPassword := s;
      if Not FWalletKeys.IsValidPassword then Application.MessageBox(PChar('Invalid password'),PChar(Application.Title),MB_ICONERROR+MB_OK);
    Until FWalletKeys.IsValidPassword;
  end;
  if FWalletKeys.IsValidPassword then begin
    s := ''; s2 := '';
    if Not InputQuery('Change password','Type new password',s) then exit;
    if trim(s)<>s then raise Exception.Create('Password cannot start or end with a space character');
    if Not InputQuery('Change password','Type new password again',s2) then exit;
    if s<>s2 then raise Exception.Create('Two passwords are different!');

    FWalletKeys.WalletPassword := s;
    Application.MessageBox(PChar('Password changed!'+#10+#10+
      'Please note that your new password is "'+s+'"'+#10+#10+
      '(If you lose this password, you will lose your Wallet forever !)'),
      PChar(Application.Title),MB_ICONWARNING+MB_OK);
  end;
  UpdateWalletConfig;
end;

procedure TFRMPascalCoinWalletConfig.cbSaveLogFilesClick(Sender: TObject);
begin
  cbSaveDebugLogs.Enabled := cbSaveLogFiles.Checked;
end;

procedure TFRMPascalCoinWalletConfig.FormCreate(Sender: TObject);
begin
  InternetServerPortDefault.Caption := Format('Default %d', [CT_NetServer_Port]);
  RPCServerPortDefault.Caption := Format('Default %d',[CT_RPC_DEFAULT_PORT]);
  lblDefaultJSONRPCMinerServerPort.Caption := Format('Default %d', [CT_MINING_SERVER_DEFAULT_PORT]);
  lbRpcServerBindIpDefault.Caption := Format('Default %s', [CT_RPC_DEFAULT_BIND_IP]);
  lbMiningServerBindIpDefault.Caption := Format('Default %s', [CT_MINING_SERVER_DEFAULT_BIND_IP]);

  ebDefaultFee.Text := TAccountComp.FormatMoney(0);
  ebMinerName.Text := '';
  bbUpdatePassword.Enabled := false;
  UpdateWalletConfig;
end;

procedure TFRMPascalCoinWalletConfig.SetAppParams(const Value: TAppParams);
begin
  FAppParams := Value;
  if Not Assigned(Value) then exit;
  Try
    udInternetServerPort.Position := AppParams.GetValue(CT_PARAM_InternetServerPort, CT_NetServer_Port);
    ebDefaultFee.Text := TAccountComp.FormatMoney(AppParams.GetValue(CT_PARAM_DefaultFee, 0));
    cbJSONRPCMinerServerActive.Checked := AppParams.GetValue(CT_PARAM_MINING_SERVER_ACTIVE, true);
    case TMinerPrivateKey(AppParams.GetValue(CT_PARAM_MinerPrivateKeyType, Integer(mpk_Random))) of
      mpk_NewEachTime : rbGenerateANewPrivateKeyEachBlock.Checked := true;
      mpk_Random : rbUseARandomKey.Checked := true;
      mpk_Selected : rbMineAllwaysWithThisKey.Checked := true;
    else rbUseARandomKey.Checked := true;
    end;
    UpdateWalletConfig;
    cbSaveLogFiles.Checked := AppParams.GetValue(CT_PARAM_SaveLogFiles, false);
    cbShowLogs.Checked := AppParams.GetValue(CT_PARAM_ShowLogs, false);
    cbSaveDebugLogs.Checked := AppParams.GetValue(CT_PARAM_SaveDebugLogs, false);
    ebMinerName.Text := AppParams.GetValue(CT_PARAM_MINER_NAME, '');
    cbShowModalMessages.Checked := AppParams.GetValue(CT_PARAM_ShowModalMessages, false);

    RPCServerIp.Text := FAppParams.GetValue(CT_PARAM_RPC_BIND_IP, CT_RPC_DEFAULT_BIND_IP);
    udRPCServerPort.Position := FAppParams.GetValue(CT_PARAM_RPC_PORT, CT_RPC_DEFAULT_PORT);

    MiningServerIp.Text := FAppParams.GetValue(CT_PARAM_MINING_SERVER_BIND_IP, CT_MINING_SERVER_DEFAULT_BIND_IP);
    udJSONRPCMinerServerPort.Position := FAppParams.GetValue(CT_PARAM_MINING_SERVER_PORT, CT_MINING_SERVER_DEFAULT_PORT);
  Except
    On E:Exception do begin
      TLog.NewLog(lterror,ClassName,'Exception at SetAppParams: '+E.Message);
    end;
  End;
  cbSaveLogFilesClick(nil);
end;

procedure TFRMPascalCoinWalletConfig.SetWalletKeys(const Value: TWalletKeys);
begin
  FWalletKeys := Value;
  UpdateWalletConfig;
end;


procedure TFRMPascalCoinWalletConfig.UpdateWalletConfig;
Var i, iselected : Integer;
  s : String;
  wk : TWalletKey;
  rawKey : AnsiString;
begin
  if Assigned(FWalletKeys) then begin
    if FWalletKeys.IsValidPassword then begin
      if FWalletKeys.WalletPassword='' then begin
        bbUpdatePassword.Caption := 'Wallet without password, protect it!';
      end else begin
        bbUpdatePassword.Caption := 'Change Wallet password';
      end;
    end else begin
        bbUpdatePassword.Caption := 'Wallet with password, change it!';
    end;
    cbPrivateKeyToMine.Items.Clear;
    for i := 0 to FWalletKeys.Count - 1 do begin
      wk := FWalletKeys.Key[i];
      if (wk.Name='') then begin
        s := TCrypto.ToHexaString( TAccountComp.AccountKey2RawString(wk.AccountKey));
      end else begin
        s := wk.Name;
      end;
      if wk.CryptedKey<>'' then begin
        cbPrivateKeyToMine.Items.AddObject(s,TObject(i));
      end;
    end;
    cbPrivateKeyToMine.Sorted := true;
    if Assigned(FAppParams) then begin
      s := FAppParams.GetValue(CT_PARAM_MinerPrivateKeySelectedPublicKey, '');
      SetLength(rawKey, Length(s) div 2);
      HexToBin(@s[1], @rawKey[1], Length(rawKey));
      iselected := FWalletKeys.IndexOfAccountKey(TAccountComp.RawString2Accountkey(rawKey));
      if iselected>=0 then begin
        iselected :=  cbPrivateKeyToMine.Items.IndexOfObject(TObject(iselected));
        cbPrivateKeyToMine.ItemIndex := iselected;
      end;

    end;

  end else bbUpdatePassword.Caption := '(Wallet password)';
  bbUpdatePassword.Enabled := Assigned(FWAlletKeys);
end;

end.
