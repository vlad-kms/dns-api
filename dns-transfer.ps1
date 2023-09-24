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
������ ������ ��� ����������� (���-�������) �����
����������� ������ � �����������:
1. ������� ������� ���������� ������;
    ��������� ���� ������� �� ��������� $Sequence
2. ���� ����� � $Path;
3. ���� ����� � "$pwd\classes";
4. ���� ����� � "$Env:AVVPATHCLASSES";
����:
    [string]$Name="avvClasses"  - ��� ������
    [string]$Path=""            - ���� ��� ������ �����
    [int32]$Sequence=1 (1 or 2) - ����������� ��������� ��� ������:
                                  = 1: 
                                        - 1. ���� ����� � $Path;
                                        - 2. ���� ����� � "$pwd\classes";
                                        - 3. ���� ����� � "$Env:AVVPATHCLASSES";
                                  = 2: 
                                        - 1. ���� ����� � $Path;
                                        - 2. ���� ����� � "$Env:AVVPATHCLASSES";
                                        - 3. ���� ����� � "$pwd\classes";
    [int32]$ModDot=1            -   
                                    = 1: ������� ���� ������. ���� ��� ������, �� ���� ����
                                    = 2: ���� ������ ������. ���� ���, �� Exception
                                    = 3: ���� ������ ���� DotSourcing. ������ ������ �� ����
�������:
    Hashtable
        What:
            1 - ������������� ������
            2 - ���-������� �����
        Path: ��� ������, ��� ������ ���� ����� ���-��������
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
            # ��� ������ ��� ���� ������ ���� DotSourcing
        if ($ModDot -eq 2) {
            throw "�� ����� ���������� ������ $($Name)"
        }
        $_fileName="$($Name).ps1"
        if ($Path) {
            $_pathModule=(Join-Path -Path $Path -ChildPath $_fileName)
        } else {
            $_pathModule='pojsajcfufioyuytry7435'
        }
        # ������� ����� ���� � $Path
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
                    throw "�� ����� ��������� ������ $($Name) �(���) ����� $($_fileName)"
                } else {
                    $_pathModule = $_p2
                }
            } else {
                $_pathModule = $_p1
            }
        }
        # �������� ����
        . $_pathModule
        return @{'What'=2; 'Path'=$_pathModule}
    } else {
        # ������ ����, ����������� ���. ������� ��������, ����� ������ ��������
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
    throw "������ ����������� commonVariable.ps1";
}
<#try {
    . .\includeModuleDotsourcing.ps1
}
catch {
    throw "������ ����������� includeModuleDotsourcing.ps1";
}#>

$_commonVariable.addProperties(@('IsImportModule', 'isDotSourcing', 'isDeb', 't1', 't2'), @($False, $False, $PSBoundParameters.Debug.IsPresent))

#$_commonVariable.IsImportModule=$False
try {
    $nameModule = 'avvClasses';
    $m=(Get-Module -ListAvailable -Name "$($nameModule)")
    if ($null -ne $m) {
        # ������ ����, ����������� ���. ������� ��������, ����� ������ ��������
        if ((Get-Module -Name "$($nameModule)")) { Remove-Module "$($nameModule)" }
        Import-Module "$($nameModule)" -Force -ErrorAction Stop
        $_commonVariable.IsImportModule=$True
    }
} catch {
    $_commonVariable.IsImportModule=$False
}
if ( ! $_commonVariable.IsImportModule) {
    # ������� ���������� ������ �� �������� .\classes\
    # ���� �� ��� ���, �� ������� ����� ������ � $Env:AVVPATHCLASSES
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
    throw "������ ��� ������� $($nameModule) ��� dot-sourcing $($nameModules)"
}

if ($_commonVariable.isDeb) {
    $global:sectionData=$ini.getSectionValues("$($Provider)")
} else {
    $sectionData=$ini.getSectionValues("$($Provider)")
}

#if ($Debug.IsPresent)

$global:p=$PSBoundParameters
$global:cv=$_commonVariable
