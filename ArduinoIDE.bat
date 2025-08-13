<# : by earthdiver1
@echo off & setlocal EnableDelayedExpansion
cd /d %~dp0
REM 以下を参考にbatファイルからPowershellのコマンドをたたく
REM [PowerShell][右クリック送る]Word,Excel,Powerpointを読み取り専用で開く
REM https://qiita.com/lifequery/items/23476636000c91fc5cca
set BATCH_ARGS=%*
for %%A in (!BATCH_ARGS!) do set "ARG=%%~A" & set "ARG=!ARG:'=''!" & set "PWSH_ARGS=!PWSH_ARGS! "'!ARG!'""
if defined PWSH_ARGS set "PWSH_ARGS=!PWSH_ARGS:^^=^!"
endlocal &  Powershell -NoProfile -Command "$input|&([ScriptBlock]::Create((gc '%~f0'|Out-String)))" %PWSH_ARGS%
exit/b
: #>

$currentdirectory = (Get-Location).Path

$Arduino_ver="1.8.19"
$global:Arduino_Path="C:\arduino-${Arduino_ver}"
$global:Arduino_sketchesPath = "${Arduino_Path}\sketches"

$ArduinoAVRboards_ver='1.8.3'
$ArduinoSTL_ver='1.3.3'
$settings_ini_Path="${currentdirectory}\ini\settings.ini"

Function CheckSettings(){
    #ファイルを一括読み込み（改行を含む文字列として取得）
    $content = Get-Content -Path $settings_ini_Path -Raw
    $config  = ConvertFrom-StringData $content
    #ハッシュテーブルの各キーを変数として定義
    foreach ($key in $config.Keys) {
        $value = if ($config.ContainsKey($key)) { $config[$key] } else { $null }

        Set-Variable -Name $key `
                    -Value $value `
                    -Scope Global `
                    -Force
    }
    if ($config.ContainsKey("Arduino_Path")) {
        $global:Arduino_Path = $config["Arduino_Path"]+"\arduino-${Arduino_ver}"
        $global:Arduino_sketchesPath = "${Arduino_Path}\sketches"
        Write-Host "Arduino IDEのインストール先が設定されました。: $Arduino_Path"
    }
}
Function InstallArduinoIDE() {
    $url    = "https://downloads.arduino.cc/arduino-${Arduino_ver}-windows.zip"
    $zipPath = "$env:TEMP\arduino-${Arduino_ver}-windows.zip"
    $outDir = Split-Path $Arduino_Path -Parent
    Write-Host "Arduino IDE (Ver:${Arduino_ver})をインストールします。"
    if (Test-Path $Arduino_Path) {
        Write-Host "→　既にフォルダが作成されているため、以降の処理をスキップします。"
        return
    }
    # .zip ファイルをダウンロード
    Invoke-WebRequest -Uri $url -OutFile $zipPath

    # 展開先フォルダがなければ作成&展開（-Force で既存ファイルを上書き）
    Expand-Archive -Path $zipPath -DestinationPath $outDir -Force
    
    New-Item -Path $Arduino_sketchesPath -ItemType Directory | Out-Null
    New-Item -Path "${Arduino_Path}\※本フォルダはPoke-Controller向けに自動生成されたものです。不要の際は、フォルダ毎削除してください。" -ItemType File

    Write-Host "→　インストールが完了しました。"
}
Function InstallArduinoAVRboards() {
    #note 検証が面倒なので実績のあるバージョンで実装
    $url    = "https://downloads.arduino.cc/cores/avr-${ArduinoAVRboards_ver}.tar.bz2"
    $bz2Path = "$env:TEMP\avr-${ArduinoAVRboards_ver}.tar.bz2"
    $outDir_tmp  = "$env:TEMP\avr-${ArduinoAVRboards_ver}"
    $outDir  = "$env:USERPROFILE\AppData\Local\Arduino15\packages\arduino\hardware\avr\${ArduinoAVRboards_ver}"
    Write-Host "Arduino AVR boards (Ver:${ArduinoAVRboards_ver})をインストールします。"
    if (Test-Path $outDir) {
        Write-Host "→　既にフォルダが作成されているため、以降の処理をスキップします。"
        return
    }
    # .bz2 ファイルをダウンロード
    Invoke-WebRequest -Uri $url -OutFile $bz2Path

    # 展開先フォルダがなければ作成
    if (-not (Test-Path $outDir_tmp)) {
        New-Item -Path $outDir_tmp -ItemType Directory | Out-Null
    }

    # tar コマンドで展開（-x: 展開, -j: bzip2, -f: ファイル指定, -C: 出力先）
    tar -xjf $bz2Path -C $outDir_tmp
    $outDir_tmp += "\avr"
    try {
        Copy-Item -Recurse $outDir_tmp $outDir
    } catch {
        Write-Output "[!] $outDir の作成に失敗しました。"
    }
    Write-Host "→　インストールが完了しました。"
}
Function InstallArduinoSTL() {
    #note 検証が面倒なので実績のあるバージョンで実装
    $url = "https://github.com/mike-matera/ArduinoSTL/archive/refs/tags/v${ArduinoSTL_ver}.zip"
    $zipPath = "$env:TEMP\ArduinoSTL-${ArduinoSTL_ver}.zip"
    $libDir = "${Arduino_Path}\libraries\ArduinoSTL"
    Write-Host "Arduino STL (Ver:${ArduinoSTL_ver})をインストールします。"
    if (Test-Path $libDir) {
        Write-Host "→　既にフォルダが作成されているため、以降の処理をスキップします。"
    	return
    }
    Invoke-WebRequest $url -OutFile $zipPath

    Expand-Archive $zipPath -DestinationPath $env:TEMP
    Move-Item "$env:TEMP\ArduinoSTL-${ArduinoSTL_ver}" $libDir
    Write-Host "→　インストールが完了しました。"
}

Function ReplaceVIDandPID() {
    $txtfile="$env:USERPROFILE\AppData\Local\Arduino15\packages\arduino\hardware\avr\${ArduinoAVRboards_ver}\boards.txt"
    $copyfile="$env:USERPROFILE\AppData\Local\Arduino15\packages\arduino\hardware\avr\${ArduinoAVRboards_ver}\boards.txt.bak"
    # 置換マッピング（旧文字列 = 新文字列）
    $replacements = @{
        'leonardo\.vid\.1=0x[A-Fa-f0-9]+' = 'leonardo.vid.1='+${VID_VALUE}
        'leonardo\.pid\.1=0x[A-Fa-f0-9]+' = 'leonardo.pid.1='+${PID_VALUE}
        'leonardo\.build\.vid=0x[A-Fa-f0-9]+' = 'leonardo.build.vid='+${VID_VALUE}
        'leonardo\.build\.pid=0x[A-Fa-f0-9]+' = 'leonardo.build.pid='+${PID_VALUE}
    }
    if (-not (Test-Path $copyfile)) {
        Copy-Item -Path $txtfile -Destination $copyfile -Force
    } else {
        Write-Host "→　boards.txtのバックアップファイルが既に存在します。"
    }
    # ファイル全体を読み込み（Raw で一文字列）
    $content = [System.IO.File]::ReadAllText($txtfile)

    # ハッシュテーブルをループして .Replace() を連続適用
    foreach ($old in $replacements.Keys) {
        $content = [regex]::Replace($content,$old, $replacements[$old])
    }

    # 上書き保存（必要なら -Encoding 指定）
    [System.IO.File]::WriteAllText($txtfile, $content)
    Write-Host VID/PIDの上書き処理が完了しました。
}

Function Replacepreferencestxt() {
    # 置換対象ファイル
    $txtfile = "$env:USERPROFILE\AppData\Local\Arduino15\preferences.txt"
    # 置換マッピング（旧文字列 = 新文字列）
    $replacements = @{
        "board=uno" = "board=leonardo"
        "sketchbook.path=$env:USERPROFILE\OneDrive\ドキュメント\Arduino" = "sketchbook.path=${Arduino_sketchesPath}"
    }

    if (-not (Test-Path $txtfile)) {
        Write-Host "preferences.txtが見つかりません。Arduino IDEを起動して生成します。"
        # Arduino IDEを立ち上げたときにpreferences.txtが生成されるため、exe立ち上げて生成されるまで待機
        $proc = Start-Process -FilePath "${Arduino_Path}\arduino.exe" -PassThru
        Write-Host "Arduino IDEを起動しました。preferences.txtの生成を待機しています..."
        while (!(Test-Path $txtfile)) {
            sleep -m 100
        }
        sleep -m 1000
        Write-Host "preferences.txtが作成されました。exeを終了し、置換処理を行います。"
        # 例: タイトルに "Arduino" を含むウィンドウを強制終了
        Get-Process | Where-Object { $_.MainWindowTitle -like "*Arduino ${Arduino_ver}" } | Stop-Process -Force
    } else {
        Write-Host "preferences.txtが見つかりました。置換処理を行います。"
    }


    # ファイル全体を読み込み（Raw で一文字列）
    $content = [System.IO.File]::ReadAllText($txtfile)

    # ハッシュテーブルをループして .Replace() を連続適用
    foreach ($old in $replacements.Keys) {
        $content = $content.Replace($old, $replacements[$old])
    }

    # 上書き保存（必要なら -Encoding 指定）
    [System.IO.File]::WriteAllText($txtfile, $content)
    Write-Host preferences.txtの上書き処理が完了しました。
}

Function Main($aryArgs) {
    if (Test-Path $settings_ini_Path) {
        CheckSettings
    } else {
        # iniファイルがなければテンプレート内容で新規作成
        $iniTemplate = @"
Arduino_Path=C:\\ArduinoIDE
VID_VALUE=0x2341
PID_VALUE=0x8036
"@
        # 展開先フォルダがなければ作成
        $outDir_tmp = Split-Path $settings_ini_Path -Parent
        if (-not (Test-Path $outDir_tmp)) {
            New-Item -Path $outDir_tmp -ItemType Directory | Out-Null
        }
        # iniファイルを作成
        Set-Content -Path $settings_ini_Path -Value $iniTemplate -Encoding UTF8
        Write-Host "設定ファイルが見つかりません。`nleonardoの初期VID/PIDに設定するためのiniファイルを作成しました。:$settings_ini_Path"
        Write-Host "iniファイルを設定後、再度このスクリプトを実行してください。"
        # iniファイルを既定のエディタで開く
        Start-Process $settings_ini_Path
        pause
        return
    }
    
    if (($VID_VALUE -eq $null) -or ($VID_VALUE -eq '') -or ($PID_VALUE -eq $null) -or ($PID_VALUE -eq '')){
        Write-Host "VID/PIDが設定されていません。`niniファイルを編集してください。:$settings_ini_Path"
        Start-Process $settings_ini_Path
        pause
        return
    } else {
        Write-Host "下記の設定で環境構築を行います。"
        Write-Host "インストール先:$Arduino_Path"
        Write-Host "VID:$VID_VALUE"
        Write-Host "PID:$PID_VALUE"
    }
    Write-Host ""
    InstallArduinoIDE
    Write-Host ""
    InstallArduinoAVRboards
    Write-Host ""
    InstallArduinoSTL
    Write-Host ""
    ReplaceVIDandPID
    Write-Host ""
    Replacepreferencestxt
    Write-Host ""

    Write-Host "環境構築が完了しました。Arduino IDEを起動します。"
    Start-Process -FilePath "${Arduino_Path}\arduino.exe"
    pause
}

Main $Args
