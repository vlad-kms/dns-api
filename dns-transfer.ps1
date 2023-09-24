Param (
    [Parameter(ValueFromPipeline=$True, Position=0)]
    #[ValidateSet('selectel', 'mydns')]
    $Provider='selectel',
    [Parameter(Position=1)]
    [string] $FileIni='',
    [Parameter(Position=2)]
    [string] $Action='getInfo',
    [hashtable] $ExtParams=@{}
)

<###################################################
Импорт модуля или подключение (дот-сорсинг) файла
Очередность поиска и подключения:
1. Сначала пробуем подключить модуль;
    следующие шаги зависят от параметра $Sequence
2. Ищем файла в $Path;
3. Ищем файла в "$pwd\classes";
4. Ищем файла в "$Env:AVVPATHCLASSES";
Вход:
    [string]$Name="avvClasses"  - имя модуля
    [string]$Path=""            - путь для поиска файла
    [int32]$Sequence=1 (1 or 2) - очередность каталогов для поиска:
                                  = 1: 
                                        - 1. Ищем файла в $Path;
                                        - 2. Ищем файла в "$pwd\classes";
                                        - 3. Ищем файла в "$Env:AVVPATHCLASSES";
                                  = 2: 
                                        - 1. Ищем файла в $Path;
                                        - 2. Ищем файла в "$Env:AVVPATHCLASSES";
                                        - 3. Ищем файла в "$pwd\classes";
    [int32]$ModDot=1            -   
                                    = 1: сначала ищем модуль. Если нет модуля, то ищем файл
                                    = 2: ищем только модуль. Если нет, то Exception
                                    = 3: ищем только файл DotSourcing. Модуль вообще не ищем
Возврат:
    Hashtable
        What:
            1 - импортировали модуль
            2 - дот-сорсинг файла
        Path: имя модуля, или полный путь файла дот-сорсинга
####################################################>
function _findCommonModule {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,
        [string]$Path="",
        [ValidateSet(1, 2)]
        [int32]$Sequence=1,
        [ValidateSet(1, 2, 3)]
        [int32]$ModDot=1
    )
    if ($ModDot -eq 3) {
        $m=$null
    } else {
        $m=(Get-Module -ListAvailable -Name "$($Name)")
    }
    if  ($null -eq $m) {
            # нет модуля или ищем только файл DotSourcing
        if ($ModDot -eq 2) {
            throw "Не нашли требуемого модуля $($Name)"
        }
        $_fileName="$($Name).ps1"
        if ($Path) {
            $_pathModule=(Join-Path -Path $Path -ChildPath $_fileName)
        } else {
            $_pathModule='pojsajcfufioyuytry7435'
        }
        # пробуем найти файл в $Path
        if ( !(Test-Path -Path $_pathModule -PathType Leaf) ) {
            $_pmEnv=(Join-Path -Path "$Env:AVVPATHCLASSES" -ChildPath $_fileName)
            $_pmPwd=(Join-Path -Path (Get-Location) -ChildPath (Join-Path -Path "classes" -ChildPath $_fileName))
            if ($Sequence -eq 2) {
                    $_p1=$_pmEnv
                    $_p2=$_pmPwd
            } else {
                    $_p2=$_pmEnv
                    $_p1=$_pmPwd
            }
            if (!(Test-Path -Path $_p1  -PathType Leaf)) {
                if (!(Test-Path -Path $_p2  -PathType Leaf)) {
                    throw "Не нашли требуемых модуля $($Name) и(или) файла $($_fileName)"
                } else {
                    $_pathModule = $_p2
                }
            } else {
                $_pathModule = $_p1
            }
        }
        # включить файл
        . $_pathModule
        return @{'What'=2; 'Path'=$_pathModule}
    } else {
        # модуль есть, импортируем его. Сначала выгрузим, затем заново загрузим
        if ((Get-Module -Name "$($Name)")) { Remove-Module "$($Name)" }
        Import-Module "$($Name)" -Force -ErrorAction Stop
        return @{'What'=1; 'Path'=$Name}
    }
}
   
function existsFilesModules {
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string[]]$Name,
        [string]$Path=".\",
        [switch]$Partially
    )
    if ($Partially.ToBool()) {
        $flag=$False
    } else {
        $flag=$True
    }
    try {
        $result = $False;
        $Name | ForEach-Object {
            if ($Partially.ToBool()) {
                $flag = $flag -or (Test-Path -Path (Join-Path -Path $Path -ChildPath $_) -PathType Leaf)
            } else {
                $flag = $flag -and (Test-Path -Path (Join-Path -Path $Path -ChildPath $_) -PathType Leaf)
            }
        }
        $result = $flag;
    }
    catch {
        $result=$False
    }
    return $result
}

try {
    . .\commonVariable.ps1
}
catch {
    throw "Ошибка подключения commonVariable.ps1";
}
<#try {
    . .\includeModuleDotsourcing.ps1
}
catch {
    throw "Ошибка подключения includeModuleDotsourcing.ps1";
}#>

$_commonVariable.addProperties(@('IsImportModule', 'isDotSourcing', 'isDeb', 't1', 't2'), @($False, $False, $PSBoundParameters.Debug.IsPresent))

#$_commonVariable.IsImportModule=$False
try {
    $nameModule = 'avvClasses';
    $m=(Get-Module -ListAvailable -Name "$($nameModule)")
    if ($null -ne $m) {
        # модуль есть, импортируем его. Сначала выгрузим, затем заново загрузим
        if ((Get-Module -Name "$($nameModule)")) { Remove-Module "$($nameModule)" }
        Import-Module "$($nameModule)" -Force -ErrorAction Stop
        $_commonVariable.IsImportModule=$True
    }
} catch {
    $_commonVariable.IsImportModule=$False
}
if ( ! $_commonVariable.IsImportModule) {
    # Сначала подключаем модули из каталога .\classes\
    # Если их там нет, то пробуем найти модули в $Env:AVVPATHCLASSES
    $pathModules = '.\classes'
    $nameModules = @('avvBase.ps1', 'classCFG.ps1')
    if (existsFilesModules -Path $pathModules -Name $nameModules) {
        $isDotSourcing=$False
        try {
            $nameModules | ForEach-Object{
                . (Join-Path -Path $pathModules -ChildPath $_)
            }
            $isDotSourcing=$True
        }
        catch {
            $isDotSourcing=$False
        }
    }
    if (!$isDotSourcing) {
        $pathModules = $Env:AVVPATHCLASSES
        try {
            $nameModules | ForEach-Object{
                . (Join-Path -Path $pathModules -ChildPath $_)
            }
            $isDotSourcing=$True
        }
        catch {
            $isDotSourcing=$False
        }
    }
    $_commonVariable.isDotSourcing = $isDotSourcing
}

if ($_commonVariable.IsImportModule) {
    if ($_commonVariable.isDeb) {
        $global:ini=(Get-IniCFG -Filename $FileIni)
    } else{
        $ini=(Get-IniCFG -Filename $FileIni)
    }
} elseif ($_commonVariable.isDotSourcing) {
    if ($_commonVariable.isDeb) {
        $global:ini=[IniCFG]::New("E:\!my-configs\configs\src\dns-hostinger\dns-cli.ps1.ini")
    } else{
        $ini=[IniCFG]::New("E:\!my-configs\configs\src\dns-hostinger\dns-cli.ps1.ini")
    }
} else {
    throw "Ошибка при импорте $($nameModule) или dot-sourcing $($nameModules)"
}

if ($_commonVariable.isDeb) {
    $global:sectionData=$ini.getSectionValues("$($Provider)")
} else {
    $sectionData=$ini.getSectionValues("$($Provider)")
}

#if ($Debug.IsPresent)

$global:p=$PSBoundParameters
$global:cv=$_commonVariable
