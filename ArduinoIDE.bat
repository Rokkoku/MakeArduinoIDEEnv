<# : by earthdiver1
@echo off & setlocal EnableDelayedExpansion
cd /d %~dp0
REM �ȉ����Q�l��bat�t�@�C������Powershell�̃R�}���h��������
REM [PowerShell][�E�N���b�N����]Word,Excel,Powerpoint��ǂݎ���p�ŊJ��
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
    #�t�@�C�����ꊇ�ǂݍ��݁i���s���܂ޕ�����Ƃ��Ď擾�j
    $content = Get-Content -Path $settings_ini_Path -Raw
    $config  = ConvertFrom-StringData $content
    #�n�b�V���e�[�u���̊e�L�[��ϐ��Ƃ��Ē�`
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
        Write-Host "Arduino IDE�̃C���X�g�[���悪�ݒ肳��܂����B: $Arduino_Path"
    }
}
Function InstallArduinoIDE() {
    $url    = "https://downloads.arduino.cc/arduino-${Arduino_ver}-windows.zip"
    $zipPath = "$env:TEMP\arduino-${Arduino_ver}-windows.zip"
    $outDir = Split-Path $Arduino_Path -Parent
    Write-Host "Arduino IDE (Ver:${Arduino_ver})���C���X�g�[�����܂��B"
    if (Test-Path $Arduino_Path) {
        Write-Host "���@���Ƀt�H���_���쐬����Ă��邽�߁A�ȍ~�̏������X�L�b�v���܂��B"
        return
    }
    # .zip �t�@�C�����_�E�����[�h
    Invoke-WebRequest -Uri $url -OutFile $zipPath

    # �W�J��t�H���_���Ȃ���΍쐬&�W�J�i-Force �Ŋ����t�@�C�����㏑���j
    Expand-Archive -Path $zipPath -DestinationPath $outDir -Force
    
    New-Item -Path $Arduino_sketchesPath -ItemType Directory | Out-Null
    New-Item -Path "${Arduino_Path}\���{�t�H���_��Poke-Controller�����Ɏ����������ꂽ���̂ł��B�s�v�̍ۂ́A�t�H���_���폜���Ă��������B" -ItemType File

    Write-Host "���@�C���X�g�[�����������܂����B"
}
Function InstallArduinoAVRboards() {
    #note ���؂��ʓ|�Ȃ̂Ŏ��т̂���o�[�W�����Ŏ���
    $url    = "https://downloads.arduino.cc/cores/avr-${ArduinoAVRboards_ver}.tar.bz2"
    $bz2Path = "$env:TEMP\avr-${ArduinoAVRboards_ver}.tar.bz2"
    $outDir_tmp  = "$env:TEMP\avr-${ArduinoAVRboards_ver}"
    $outDir  = "$env:USERPROFILE\AppData\Local\Arduino15\packages\arduino\hardware\avr\${ArduinoAVRboards_ver}"
    Write-Host "Arduino AVR boards (Ver:${ArduinoAVRboards_ver})���C���X�g�[�����܂��B"
    if (Test-Path $outDir) {
        Write-Host "���@���Ƀt�H���_���쐬����Ă��邽�߁A�ȍ~�̏������X�L�b�v���܂��B"
        return
    }
    # .bz2 �t�@�C�����_�E�����[�h
    Invoke-WebRequest -Uri $url -OutFile $bz2Path

    # �W�J��t�H���_���Ȃ���΍쐬
    if (-not (Test-Path $outDir_tmp)) {
        New-Item -Path $outDir_tmp -ItemType Directory | Out-Null
    }

    # tar �R�}���h�œW�J�i-x: �W�J, -j: bzip2, -f: �t�@�C���w��, -C: �o�͐�j
    tar -xjf $bz2Path -C $outDir_tmp
    $outDir_tmp += "\avr"
    try {
        Copy-Item -Recurse $outDir_tmp $outDir
    } catch {
        Write-Output "[!] $outDir �̍쐬�Ɏ��s���܂����B"
    }
    Write-Host "���@�C���X�g�[�����������܂����B"
}
Function InstallArduinoSTL() {
    #note ���؂��ʓ|�Ȃ̂Ŏ��т̂���o�[�W�����Ŏ���
    $url = "https://github.com/mike-matera/ArduinoSTL/archive/refs/tags/v${ArduinoSTL_ver}.zip"
    $zipPath = "$env:TEMP\ArduinoSTL-${ArduinoSTL_ver}.zip"
    $libDir = "${Arduino_Path}\libraries\ArduinoSTL"
    Write-Host "Arduino STL (Ver:${ArduinoSTL_ver})���C���X�g�[�����܂��B"
    if (Test-Path $libDir) {
        Write-Host "���@���Ƀt�H���_���쐬����Ă��邽�߁A�ȍ~�̏������X�L�b�v���܂��B"
    	return
    }
    Invoke-WebRequest $url -OutFile $zipPath

    Expand-Archive $zipPath -DestinationPath $env:TEMP
    Move-Item "$env:TEMP\ArduinoSTL-${ArduinoSTL_ver}" $libDir
    Write-Host "���@�C���X�g�[�����������܂����B"
}

Function ReplaceVIDandPID() {
    $txtfile="$env:USERPROFILE\AppData\Local\Arduino15\packages\arduino\hardware\avr\${ArduinoAVRboards_ver}\boards.txt"
    $copyfile="$env:USERPROFILE\AppData\Local\Arduino15\packages\arduino\hardware\avr\${ArduinoAVRboards_ver}\boards.txt.bak"
    # �u���}�b�s���O�i�������� = �V������j
    $replacements = @{
        'leonardo\.vid\.1=0x[A-Fa-f0-9]+' = 'leonardo.vid.1='+${VID_VALUE}
        'leonardo\.pid\.1=0x[A-Fa-f0-9]+' = 'leonardo.pid.1='+${PID_VALUE}
        'leonardo\.build\.vid=0x[A-Fa-f0-9]+' = 'leonardo.build.vid='+${VID_VALUE}
        'leonardo\.build\.pid=0x[A-Fa-f0-9]+' = 'leonardo.build.pid='+${PID_VALUE}
    }
    if (-not (Test-Path $copyfile)) {
        Copy-Item -Path $txtfile -Destination $copyfile -Force
    } else {
        Write-Host "���@boards.txt�̃o�b�N�A�b�v�t�@�C�������ɑ��݂��܂��B"
    }
    # �t�@�C���S�̂�ǂݍ��݁iRaw �ňꕶ����j
    $content = [System.IO.File]::ReadAllText($txtfile)

    # �n�b�V���e�[�u�������[�v���� .Replace() ��A���K�p
    foreach ($old in $replacements.Keys) {
        $content = [regex]::Replace($content,$old, $replacements[$old])
    }

    # �㏑���ۑ��i�K�v�Ȃ� -Encoding �w��j
    [System.IO.File]::WriteAllText($txtfile, $content)
    Write-Host VID/PID�̏㏑���������������܂����B
}

Function Replacepreferencestxt() {
    # �u���Ώۃt�@�C��
    $txtfile = "$env:USERPROFILE\AppData\Local\Arduino15\preferences.txt"
    # �u���}�b�s���O�i�������� = �V������j
    $replacements = @{
        "board=uno" = "board=leonardo"
        "sketchbook.path=$env:USERPROFILE\OneDrive\�h�L�������g\Arduino" = "sketchbook.path=${Arduino_sketchesPath}"
    }

    if (-not (Test-Path $txtfile)) {
        Write-Host "preferences.txt��������܂���BArduino IDE���N�����Đ������܂��B"
        # Arduino IDE�𗧂��グ���Ƃ���preferences.txt����������邽�߁Aexe�����グ�Đ��������܂őҋ@
        $proc = Start-Process -FilePath "${Arduino_Path}\arduino.exe" -PassThru
        Write-Host "Arduino IDE���N�����܂����Bpreferences.txt�̐�����ҋ@���Ă��܂�..."
        while (!(Test-Path $txtfile)) {
            sleep -m 100
        }
        sleep -m 1000
        Write-Host "preferences.txt���쐬����܂����Bexe���I�����A�u���������s���܂��B"
        # ��: �^�C�g���� "Arduino" ���܂ރE�B���h�E�������I��
        Get-Process | Where-Object { $_.MainWindowTitle -like "*Arduino ${Arduino_ver}" } | Stop-Process -Force
    } else {
        Write-Host "preferences.txt��������܂����B�u���������s���܂��B"
    }


    # �t�@�C���S�̂�ǂݍ��݁iRaw �ňꕶ����j
    $content = [System.IO.File]::ReadAllText($txtfile)

    # �n�b�V���e�[�u�������[�v���� .Replace() ��A���K�p
    foreach ($old in $replacements.Keys) {
        $content = $content.Replace($old, $replacements[$old])
    }

    # �㏑���ۑ��i�K�v�Ȃ� -Encoding �w��j
    [System.IO.File]::WriteAllText($txtfile, $content)
    Write-Host preferences.txt�̏㏑���������������܂����B
}

Function Main($aryArgs) {
    if (Test-Path $settings_ini_Path) {
        CheckSettings
    } else {
        # ini�t�@�C�����Ȃ���΃e���v���[�g���e�ŐV�K�쐬
        $iniTemplate = @"
Arduino_Path=C:\\ArduinoIDE
VID_VALUE=0x2341
PID_VALUE=0x8036
"@
        # �W�J��t�H���_���Ȃ���΍쐬
        $outDir_tmp = Split-Path $settings_ini_Path -Parent
        if (-not (Test-Path $outDir_tmp)) {
            New-Item -Path $outDir_tmp -ItemType Directory | Out-Null
        }
        # ini�t�@�C�����쐬
        Set-Content -Path $settings_ini_Path -Value $iniTemplate -Encoding UTF8
        Write-Host "�ݒ�t�@�C����������܂���B`nleonardo�̏���VID/PID�ɐݒ肷�邽�߂�ini�t�@�C�����쐬���܂����B:$settings_ini_Path"
        Write-Host "ini�t�@�C����ݒ��A�ēx���̃X�N���v�g�����s���Ă��������B"
        # ini�t�@�C��������̃G�f�B�^�ŊJ��
        Start-Process $settings_ini_Path
        pause
        return
    }
    
    if (($VID_VALUE -eq $null) -or ($VID_VALUE -eq '') -or ($PID_VALUE -eq $null) -or ($PID_VALUE -eq '')){
        Write-Host "VID/PID���ݒ肳��Ă��܂���B`nini�t�@�C����ҏW���Ă��������B:$settings_ini_Path"
        Start-Process $settings_ini_Path
        pause
        return
    } else {
        Write-Host "���L�̐ݒ�Ŋ��\�z���s���܂��B"
        Write-Host "�C���X�g�[����:$Arduino_Path"
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

    Write-Host "���\�z���������܂����BArduino IDE���N�����܂��B"
    Start-Process -FilePath "${Arduino_Path}\arduino.exe"
    pause
}

Main $Args
