$myCredential = Get-AutomationPSCredential -Name 'AzureSubscriptionCredentials'
$subscriptionId =  Get-AutomationVariable -Name 'SubscriptionId'
$subscriptionName = Get-AutomationVariable -Name 'SubscriptionName'
$scope = "/subscriptions/"+$subscriptionId
$policyName = Get-AutomationVariable -Name 'PolicyName'

$from = Get-AutomationVariable -Name 'From'
$toAddress = Get-AutomationVariable -Name 'To'
$EmailSMTPServerName = Get-AutomationVariable -Name 'EmailSMTPServerName'
$EmailServerUserName = Get-AutomationVariable -Name 'EmailServerUserName'
$EmailServerPassword = Get-AutomationVariable -Name 'EmailServerPassword'

function SendEmail($message)
{
    Try {
            $PSTZone =  [System.TimeZoneInfo]::FindSystemTimeZoneById("Pacific Standard Time")
            $utcNow = (Get-Date).ToUniversalTime()
            $PSTNow = [System.TimeZoneInfo]::ConvertTimeFromUtc($utcNow, $PSTZone)

            $AlertTime = '<p>Alert Time: '+ $PSTNow.DateTime +'</p>'
            $body = '<htmL><head></head><body style="font_family:Verdana">'+ $AlertTime + $message + '</body></html>'

            $emailSubject = 'Azure Policy Enabled' + ' @ '+ $PSTNow.DateTime
            #[string[]] $toAddress="v-prave@microsoft.com", "v-prave@microsoft.com"
            
            $smtpServer = $EmailSMTPServerName
            $Username =$EmailServerUserName
            $Password = ConvertTo-SecureString $EmailServerPassword -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential $Username, $Password
                    
            Send-MailMessage -smtpServer $smtpServer -Credential $credential -Usessl -Port 587 -from $from -to $toAddress -subject $emailSubject -Body $body -BodyAsHtml
            
            return $true
    }
    catch{
            #[string]::Format("{0} : [ERROR] From-Method_SendEmail: Error occured while sending email.",(Get-Date)) | Add-Content $ErrorLog
            
            return $false
    }

}


Login-AzureRmAccount -Credential $myCredential
Set-AzureRmContext -SubscriptionId $subscriptionId

$result = "";

$result = Get-AzureRmPolicyAssignment -Name $policyName -Scope $scope -ErrorAction SilentlyContinue
$flag = $FALSE;

While ($result.Name -ne $policyName)
{
    $Policy = Get-AzureRmPolicyDefinition -Name $policyName
    
    $temp = "";
    $temp = New-AzureRmPolicyAssignment -Name $policyName -PolicyDefinition $Policy -Scope $scope -ErrorAction SilentlyContinue

    $result =Get-AzureRmPolicyAssignment -Name $temp.Name -Scope $scope
    $flag = $TRUE;    
}

if($flag -eq $TRUE)
{
    $msg = 'Azure Policy '+$policyName+' enabled on '+$subscriptionName+' Subscription scope.'

    SendEmail -message $msg

    "Success! Policy " +$result.Name+ " has been enabled on the Subscription scope."

}
else{
    
    "Policy already ON, no action is taken at this moment."
}


