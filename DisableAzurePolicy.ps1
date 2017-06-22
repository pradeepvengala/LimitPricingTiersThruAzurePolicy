$myCredential = Get-AutomationPSCredential -Name 'AzureSubscriptionCredentials'
$subscriptionId =  Get-AutomationVariable -Name 'SubscriptionId'
$subscriptionName = Get-AutomationVariable -Name 'SubscriptionName'
$scope = "/subscriptions/"+$subscriptionId
$policyName = Get-AutomationVariable -Name 'PolicyName'

$from = Get-AutomationVariable -Name 'From'
$toAddress = Get-AutomationVariable -Name 'To'

function SendEmail($message)
{
    Try {
            $PSTZone =  [System.TimeZoneInfo]::FindSystemTimeZoneById("Pacific Standard Time")
            $utcNow = (Get-Date).ToUniversalTime()
            $PSTNow = [System.TimeZoneInfo]::ConvertTimeFromUtc($utcNow, $PSTZone)

            $AlertTime = '<p>Alert Time: '+ $PSTNow.DateTime +'</p>'
            $body = '<htmL><head></head><body style="font_family:Verdana">'+ $AlertTime + $message + '</body></html>'

            $emailSubject = 'Azure Policy Disabled' + ' @ '+ $PSTNow.DateTime
            #[string[]] $toAddress=
            
            $smtpServer = "smtp.sendgrid.net"
            $Username ="abc"
            $Password = ConvertTo-SecureString "abc" -AsPlainText -Force
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

While ($result.Name -eq $policyName)
{
    $temp = "";
    $temp = Remove-AzureRmPolicyAssignment -Name $policyName -Scope $scope -force

    $result = "";
    $result =Get-AzureRmPolicyAssignment -Name $policyName -Scope $scope -ErrorAction SilentlyContinue

    $flag = $TRUE;
}

if($flag -eq $TRUE)
{
    $msg = 'Azure Policy '+$policyName +' disabled on '+$subscriptionName+' Subscription scope.'
    SendEmail -message $msg

    "Success! Policy " +$result.Name+ " has been disabled on the Subscription scope."

}
else{
    
    "Policy already OFF, no action is taken at this moment."
}