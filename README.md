# ArduinoIDE環境構築バッチファイル

## 概要

ArduinoIDE.bat は、Windows環境でArduino IDE（1.8.19）と関連ライブラリ・ボードパッケージの自動インストール・初期設定を行うバッチファイルです。  
PowerShellスクリプトをバッチファイルから呼び出すことで、初心者でも簡単にArduino開発環境を構築できます。

---

## 主な機能

- **Arduino IDE本体の自動ダウンロード・展開**
- **AVRボードパッケージの自動インストール**
- **ArduinoSTLライブラリの自動インストール**
- **VID/PIDの自動書き換え（boards.txt）**
- **スケッチブック保存先やデフォルトボードの自動設定（preferences.txt）**
- **設定ファイル（ini/setting.ini）が無い場合の自動生成と編集促進**

---

## 使い方

1. ArduinoIDE.bat をダブルクリックで実行します。
2. 初回実行時、`ini/settings.ini` が無い場合は自動生成され、エディタで開きます。  
   必要事項（インストール先、VID/PID）を記入し、保存してください。
3. 再度 ArduinoIDE.bat を実行すると、設定に従い自動で環境構築が始まります。
4. 完了後、Arduino IDEが起動します。

---

## iniファイル（設定ファイル）について

`ini/settings.ini` の例：

```
ArduinoIDEInstallPath=C:\\MyArduinoIDE
VID_VALUE=0x2341
PID_VALUE=0x8036
```

- `ArduinoIDEInstallPath` … Arduino IDEのインストール先パス※「\」を使いたい場合は「\\\\」に置き換えてください。
- `VID_VALUE` / `PID_VALUE` … 書き換えたいUSBデバイスのVID/PID

---

## 注意事項

- 本バッチはPowerShellを利用します。Windows専用です。
- インターネット接続が必要です。
- 既存のArduino IDEや設定ファイルが上書きされる場合があります。必要に応じてバックアップを取ってください。
   * C:\ArduinoIDE\arduino-1.8.19 (※デフォルト値)
   * %USERPROFILE%\AppData\Local\Arduino15

---

## フォルダ構成例

```
\ArduinoIDE\
├─ ArduinoIDE.bat
└─ ini\
    └─ settings.ini
```

---
### 参考
batファイルからPowerShellを実行する
https://qiita.com/lifequery/items/23476636000c91fc5cca
