$myCredential = Get-AutomationPSCredential -Name 'AzureSubscriptionCredentials'
$subscriptionId =  Get-AutomationVariable -Name 'SubscriptionId'
$policyName = Get-AutomationVariable -Name 'PolicyName'

Login-AzureRmAccount -Credential $myCredential
Set-AzureRmContext -SubscriptionId $subscriptionId

$policyJson = '{
      "if": {
        "anyOf": [
          {
            "allOf": [
              {
                "field": "type",
                "equals": "Microsoft.Web/serverFarms"
              },
              {
                "not": {
                  "field": "Microsoft.Web/serverFarms/sku.name",
                  "in": [
                    "F1",
                    "D1",
                    "B1",
                    "S1"
                  ]
                }
              }
            ]
          },
          {
            "allOf": [
              {
                "field": "type",
                "equals": "Microsoft.Sql/servers/databases"
              },
              {
                "not": {
                  "field": "Microsoft.Sql/servers/databases/requestedServiceObjectiveId",
                  "in": [
                    "dd6d99bb-f193-4ec1-86f2-43d3bccbc49c",
                    "f1173c43-91bd-4aaa-973c-54e79e15235b"
                  ]
                }
              }
            ]
          },
          {
            "allOf": [
              {
                "field": "type",
                "equals": "Microsoft.Storage/storageAccounts"
              },
              {
                "not": {
                  "field": "Microsoft.Storage/storageAccounts/sku.name",
                  "in": [
                    "Standard_LRS",
                    "Standard_GRS"
                  ]
                }
              }
            ]
          },
          {
            "allOf": [
              {
                "field": "type",
                "equals": "Microsoft.Compute/virtualMachines"
              },
              {
                "not": {
                  "field": "Microsoft.Compute/virtualMachines/sku.name",
                  "in": [
                    "Standard_F1s"
                  ]
                }
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "deny"
      }
    
}
'
$result = "";

$result = Get-AzureRmPolicyDefinition -Name $policyName -ErrorAction SilentlyContinue
  

if($result.Name -ne $policyName)
{
    
    $temp = New-AzureRmPolicyDefinition -Name $policyName -DisplayName $policyName -Description 'Policy for limiting Azure resource pricing Tiers' -Policy $policyJson -ErrorAction SilentlyContinue
    
    "Success! Policy " +$policyName+ " has been added to the Subscription."        
}
else
{
    $temp = Set-AzureRmPolicyDefinition -Name $policyName -Policy $policyJson -ErrorAction SilentlyContinue
    
    "Success! Policy " +$policyName+ " has been updated in the Subscription."    
}
