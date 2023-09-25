class CommonVariable {
    [string]$scriptPath="";
    [string]$DS=[System.IO.Path]::DirectorySeparatorChar;
    #[bool]$IsImportModule=$False;
    #[bool]$isDotSourcing=$False

    CommonVariable([String]$scPath)
    {
        $this.scriptPath=$scPath;
    }

   [String] ToJson()
    {
        return ($this | ConvertTo-Json -Depth 1);
    }
    
    [void] addProperties([string[]]$Names, [object[]]$Values){
        $i=0
        $Names.ForEach({
            if ( $i -lt $Values.Count) {
                $v=$Values[$i]
            } else {
                $v=$null
            }
            $this.addProperty($_, $v)
            $i+=1
        })
    }

    [void] addProperty([string]$Name, $Value){
        if ( $global:PSVersionTable.PSVersion.Major -ge 3 ) {
            $this | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
        } else {
            $this | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
        }
    }
}

if ($global:PSVersionTable.BuildVersion.Major -ne 3) {
    $_commonVariable = [CommonVariable]::new($PSScriptRoot)
} else {
    #$_commonVariable = [CommonVariable]::new(($MyInvocation.MyCommand.Path | Split-Path -parent))
    $_commonVariable = [CommonVariable]::new(($PSCommandPath                | Split-Path -Parent));
}

if ($PSBoundParameters.Debug.IsPresent) {
    Write-Debug "_commonVariable:";
    Write-Debug $_commonVariable;
}

#function _debug {
#    param (
#        [String[]] $Msg
#    )
#} ### _debug
