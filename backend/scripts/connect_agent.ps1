# Connects the live TailorSync API (Azure App Service) to the Foundry agent.
# Run from the TailorSync folder after `az login`:
#   powershell -ExecutionPolicy Bypass -File backend\scripts\connect_agent.ps1

$ErrorActionPreference = "Stop"
$App      = "tailorsync-api-prod"
$AiName   = "tailorsync-ai-resource"
$Endpoint = "https://tailorsync-ai-resource.services.ai.azure.com/api/projects/tailorsync-ai"
$Agent    = "ts-ai-agent"

Write-Host "`n[1/5] Finding resources..." -ForegroundColor Cyan
$Rg   = az webapp list --query "[?name=='$App'].resourceGroup | [0]" -o tsv
$AiId = az cognitiveservices account list --query "[?name=='$AiName'].id | [0]" -o tsv
if (-not $Rg)   { throw "App Service '$App' not found in this subscription." }
if (-not $AiId) { throw "Foundry resource '$AiName' not found in this subscription." }
Write-Host "  App resource group: $Rg"

Write-Host "`n[2/5] Turning on the App Service managed identity..." -ForegroundColor Cyan
$PrincipalId = az webapp identity assign -g $Rg -n $App --query principalId -o tsv
Write-Host "  Identity: $PrincipalId"

Write-Host "`n[3/5] Giving it the 'Azure AI User' role on the Foundry resource..." -ForegroundColor Cyan
$existing = az role assignment list --assignee $PrincipalId --scope $AiId --role "Azure AI User" --query "[0].id" -o tsv
if ($existing) { Write-Host "  Already assigned." }
else {
  az role assignment create --assignee-object-id $PrincipalId --assignee-principal-type ServicePrincipal `
     --role "Azure AI User" --scope $AiId -o none
  Write-Host "  Assigned."
}

Write-Host "`n[4/5] Adding app settings..." -ForegroundColor Cyan
az webapp config appsettings set -g $Rg -n $App --settings `
   "FOUNDRY_PROJECT_ENDPOINT=$Endpoint" "FOUNDRY_AGENT_NAME=$Agent" -o none
Write-Host "  Done."

Write-Host "`n[5/5] Pushing the code (GitHub Actions will deploy it)..." -ForegroundColor Cyan
git add backend/app/services/foundry_client.py backend/requirements.txt backend/test_foundry_agent.py backend/scripts/connect_agent.ps1
git commit -m "feat: use Foundry agent ts-ai-agent for AI features"
git push origin main

Write-Host "`nAll set. When the GitHub Action is green (~6 min), restart the app with:" -ForegroundColor Green
Write-Host "  az webapp restart -g $Rg -n $App" -ForegroundColor Yellow
