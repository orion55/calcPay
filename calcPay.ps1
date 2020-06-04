#Программа конвертации подготовки файлов для OpenWay
#(c) Гребенёв О.Е. 04.06.2020

[string]$curDir = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$lib = "$curDir\lib"
$curDate = Get-Date -Format "ddMMyyyy"
[string]$logName = $curDir + "\log\" + $curDate + "_calc.log"
[string]$dostowin = "$lib\dostowin.exe"
Set-Location $curDir

[string]$inPath = "$curDir\in"
[string]$outPath = "$curDir\out"
[string]$tmpPath = "$curDir\tmp"

. $curDir/config.ps1
. $lib/PSMultiLog.ps1
. $lib/libs.ps1

function calculation {
    param (
        $fileName
    )
    
    $count = 0
    $sum = 0

    $fileContent = Get-Content $fileName
    foreach ($curLine in $fileContent) {
        if ($curLine -ne '') {
            $arr = $curLine.split(",")            
            $sum += $arr[2]
            $count++
        }
    }

    return @{
        count   = $count
        sum     = $sum
        content = $fileContent
    }
}

function saveData {
    param (
        $data,
        $out,
        $counter
    )
    
    $curDate = Get-Date -Format "ddMMyyyy"
    $count = "{0:00}" -f $counter    
    $fileName = $outPath + "\" + $curDate + "-" + $count + ".txt"    
           
    $str = "RUR," + $data.count + "," + $data.sum + ","
    Write-Log -EntryType Information -Message $str
    Write-Log -EntryType Information -Message "Сохраняем результат в файл $fileName"
    
    $str | Out-File $fileName -Encoding OEM
    $data.content | Out-File $fileName -Encoding OEM -Append    
}

Clear-Host

Start-HostLog -LogLevel Information
Start-FileLog -LogLevel Information -FilePath $logName -Append

#проверяем существуют ли нужные пути и файлы
testDir(@($inPath))
createDir(@($tmpPath, $outPath))
Remove-Item "$tmpPath\*.*" -recurse | Where-Object { ! $_.PSIsContainer }
testFiles(@($dostowin))

Write-Log -EntryType Information -Message "Начало работы calcPay"
$txtFiles = Get-ChildItem "$inPath\*.txt"

if (($txtFiles | Measure-Object).count -eq 0) {
    Write-Log -EntryType Error -Message "Txt-файлы в $inPath не найдены!"
    exit
}

Copy-Item $txtFiles $tmpPath

$txtTmpFiles = Get-ChildItem "$tmpPath\*.txt"

if ($encoding -eq 866) {
    ForEach ($file in $txtTmpFiles) {
        Write-Log -EntryType Information -Message "Конвертируем dos -> win $($file.Name)" 
        ./lib/dostowin.exe $file     
    }
}

$i = 1
ForEach ($file in $txtTmpFiles) {
    $result = calculation -fileName $file
    saveData -data $result -out $outPath -counter $i
    $i++
}

Write-Log -EntryType Information -Message "Конец работы calcPay"

Stop-FileLog
Stop-HostLog