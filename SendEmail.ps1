#Get List of all email receivers
Write-Host "List -> $env:mail_list"
$mailList = $env:mail_list.split(",")
Write-Host "$mailList"

$mailSubject = $env:mail_subject
$mailBody = $env:mail_body

Write-Host "Subject -> $mailSubject   Body ->$mailBody"

## Variables to send mail
$myorg = “debduttachatterjee09”
$myproj = “SendMail_Pipeline”
$sendmailto = $env:mail_list ## comma separated email ids of receivers


## Get tfsids of users whom to send mail
$recipients= $sendmailto-split “,”

$myurl =”https://dev.azure.com/${myorg}/_apis/projects/${myproj}/teams?api-version=5.1"
    $data = Invoke-RestMethod -Uri $myurl -Headers @{
      Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
    }
    $myteams = $data.value.id
    Write-Host "Teams -> $myteams"

##Get list of members in all teams

foreach($myteam in $myteams) {
    $usrurl = “https://dev.azure.com/${myorg}/_apis/projects/${myproj}/teams/"+$myteam+"/members?api-version=5.1"
    $userdata = Invoke-RestMethod -Uri $usrurl -Headers @{
      Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
  }
Write-Host $userdata
$users = $userdata.value


$user_record_array = @()
foreach ($user in $users )
{
  $userid = $user.identity.id
  $usermail = $user.identity.uniqueName
   $userrecord = $userid +”:”+$usermail 
    $user_record_array += $userrecord 
}

}
    Write-Host "Users array -> $user_record_array"
## filter unique users
    $user_record_unique_array = $user_record_array| sort -Unique
    Write-Host "Users unique -> $user_record_unique_array"

## create final hash of emails and tfsids
$usersMap = @{}
foreach ($uniqueUser in $user_record_unique_array)
{
   Write-Host "Unique -> $uniqueUser"
$user_id =$uniqueUser.split(“:”)[0].Trim()
Write-Host " Id: $user_id" 
$user_email=$uniqueUser.split(“:”)[1].replace("[0]","").Trim()
Write-Host "email: $user_email"
$usersMap.add($user_email,$user_id)
}


Write-Host "Map -> $usersMap"
Write-Host "Map size-> $usersMap.Count"

## create list of tfsid of recipients
$recipientsId=""
    foreach($recipient in $recipients) {
Write-Host "Recipient -> $recipient"
$recipientId=$usersMap[$recipient]
Write-Host "TFS ID-> $recipientId"

    $recipientsId= $recipientsId+’”’+$recipientId+’”,’
    }
    Write-Host "recipientsId-> $recipientsId"



##send mail
    $uri = "https://${myorg}.vsrm.visualstudio.com/${myproj}/_apis/Release/sendmail/$(RELEASE.RELEASEID)?api-version=3.2-preview.1"
    ##$uri = "https://dev.azure.com/${myorg}/${myproj}/_apis/wit/sendmail?api-version=7.1-preview.1"
    
Write-Host "URI ->  $uri "
    $requestBody =@”
    {
    “senderType”:1,
    “to”:{“tfsIds”:[${recipientsId}]},
    “body”:”${mailBody}”,
    “subject”:”${mailSubject}”
    }
“@




Write-Host $requestBody

    Try {
    $data =Invoke-RestMethod -Uri $uri -Body $requestBody -Method POST -Headers @{
      Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
    } -ContentType “application/json”

    Write-Host "data $data"
#Write-Host "content $data.Content"
    }
    
    Catch {
    $_.Exception
    }
