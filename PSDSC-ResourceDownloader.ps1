﻿$ModuleFile = (Join-Path -Path $PSScriptRoot -ChildPath 'PSDSC-ResourceDownloader.clixml')

if (-Not (Test-Path -Path $ModuleFile)) {
    $ModuleList = New-Object System.Collections.ArrayList

    $PageList = New-Object System.Collections.Stack
    $PageList.Push('https://gallery.technet.microsoft.com/scriptcenter/site/search?f%5B0%5D.Type=Tag&f%5B0%5D.Value=Windows%20PowerShell%20Desired%20State%20Configuration&f%5B0%5D.Text=Windows%20PowerShell%20Desired%20State%20Configuration&pageIndex=1')
    $PageBeenThere = New-Object System.Collections.ArrayList
    while ($PageList.Count -gt 0) {
        $url = $PageList.Pop()
        if (-Not $PageBeenThere.Contains($url)) {
            #'processing {0}' -f $url
            $PageBeenThere.Add($url) | Out-Null
            $page = Invoke-WebRequest $url

            $page.Links | where {$_.href -match 'pageIndex' -and $_.innerText -match '\d+'} | foreach {
                $url = $_.href
                $url = $url.Replace('about:', 'https://gallery.technet.microsoft.com')
                $url = $url.Replace('&amp;', '&')
                if (-Not $PageBeenThere.Contains($url)) {
                    $PageList.Push($url)
                }
            }

            $page.Links | where {$_.href -match '^about:/scriptcenter/(.+)-[a-z0-9]{8}$'} | foreach {
                $url = $_.href
                $url = $url.Replace('about:', 'https://gallery.technet.microsoft.com')
                $url = $url.Replace('&amp;', '&')
                $ModuleList.Push($url)
            }

            Start-Sleep -Seconds 5
        }
    }

    $ModuleList | Export-Clixml -Path $ModuleFile

} else {
    $ModuleList = Import-Clixml -Path $ModuleFile
}

Foreach ($ModuleUrl in $ModuleList) {
    $page = Invoke-WebRequest $ModuleUrl
    $page.Links | where {$_.href -match '^about:/scriptcenter/(.+-[a-z0-9]{8})/file/'} | select -First 1 | foreach {
        $ItemName = $Matches[1]
        $url = $_.href
        $url = $url.Replace('about:', 'https://gallery.technet.microsoft.com')
        $url = $url.Replace('&amp;', '&')
        $url -match '/([^/]+.zip$)' | Out-Null
        $FileName = $Matches[1]
        Invoke-WebRequest $url -OutFile (Join-Path -Path $PSScriptRoot -ChildPath ('\DSC-Modules\' + $FileName))
    }
}