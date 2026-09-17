BeforeAll {
    . "$PSScriptRoot\..\scripts\modules\Update-ExceptionHistory.ps1"
    . "$PSScriptRoot\..\scripts\modules\New-OwnershipExceptionEmail.ps1"
}
Describe 'Ownership exception evidence' {
    It 'creates stable exception keys and first-detected history' {
        $path=Join-Path $TestDrive 'history.csv'
        $input=@([pscustomobject]@{ExceptionKey='ACL-Finance-RW|OWNER_MISSING';Group='ACL-Finance-RW';Owner=$null;OwnerUPN=$null;OwnerSource=$null;OwnershipStatus='OWNER_MISSING';Detail='No owner'})
        $r=Update-ExceptionHistory -CurrentExceptions $input -HistoryPath $path
        $r.Current.Count | Should -Be 1
        $r.Current[0].State | Should -Be 'New'
        Test-Path $path | Should -BeTrue
    }
    It 'renders an exception email' {
        $template=Join-Path $PSScriptRoot '..\templates\Daily-Ownership-Exception-Email.html'
        $input=@([pscustomobject]@{Group='ACL-Finance-RW';Owner='';OwnershipStatus='OWNER_MISSING';FirstDetected='2026-09-17';AgeDays=0;Detail='No owner'})
        (New-OwnershipExceptionEmail -Exceptions $input -TemplatePath $template) | Should -Match 'ACL-Finance-RW'
    }
}
