if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Если нет, перезапускаем скрипт с правами администратора
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "powershell";
    $newProcess.Arguments = "& '" + $myInvocation.MyCommand.Definition + "'";
    $newProcess.Verb = "runas";
    [System.Diagnostics.Process]::Start($newProcess);
    exit;
}

#Порт на котором будет развёрнут сервер
$StartPort = "19"
#Название службы
$ServiceName = "1C:Enterprise 8.3 Server Agent (x86-64) $($StartPort)41"
#Путь к ragent нуженой версии платформы 1С
$Path = """C:\Program Files\1cv8\8.3.24.1667\bin\ragent.exe"""
#Путь для хранения серверного кеша и файлов конфигурации кластера
$ServiceInfo = """C:\Program Files\1cv8\srvinfo$($StartPort)41"""
#Выводимое имя службы
$ServiceDisplayName = "Агент сервера 1С:Предприятия 8.3 (x86-64) $($StartPort)41 1C_Buh_TZK"
#Путь для исполнения в службу
$BinaryPath = "$Path -srvc -agent -regport $($StartPort)41 -port $($StartPort)40 -range $($StartPort)60:$($StartPort)91 -d $ServiceInfo -debug"
#Создание службы
New-Service -Name $ServiceName -BinaryPathName $BinaryPath -DisplayName $ServiceDisplayName -StartupType Automatic
#Запуск службы
Start-Service -Name $ServiceName

#Поиск процессов которые связаны с этой службой и остановка их
foreach($process in (Get-WmiObject win32_process | Where-Object {($_.Name -eq 'rphost.exe' -or $_.Name -eq 'rmngr.exe') -and $_.CommandLine -like "$($StartPort)91*"}))
{
    Stop-Process $process
}
#Остановка службы
Stop-Service -Name $ServiceName
