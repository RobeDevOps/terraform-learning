# Authentication

## Create the service principal
```az ad sp create-for-rbac --name "<sp_name>" --role contributor --scopes "/subscriptions/<your_subscription>"```

Console output: 
```
{
  "appId": "<sp_ip>",
  "displayName": "terraform-sp",
  "password": "<sp_secret_password>",
  "tenant": "<tenant_id>" # you don't need this tenant_id, use the subscription tenant_id
}
```

## export these variables 
Based on the top variables.
```
$env:ARM_CLIENT_ID="<service_principal_app_id>"
$env:ARM_SUBSCRIPTION_ID="<azure_subscription_id>"
$env:ARM_TENANT_ID="<azure_subscription_tenant_id>"
# this is the password generated when the service principal was created
$env:ARM_CLIENT_SECRET="<service_principal_password>" 
```

Use the ```az account show``` to get the subscription_id and tenant_id.

Check the variables with the command ```gci env:ARM_*```

```
Name                           Value
----                           -----
ARM_CLIENT_SECRET              3LZ8Q~6b....FByvbaD84eyc3J
ARM_SUBSCRIPTION_ID            bc330597-...-85773e1c9fc8
ARM_TENANT_ID                  c989eca3-...-c28d06b7914a
ARM_CLIENT_ID                  a2d69af3-...-04ee319e04fe
```

## References
https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure-with-service-principle?tabs=azure-powershell
