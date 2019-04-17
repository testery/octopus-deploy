echo "Performing test run in Testery..."
echo "  Git Owner: ${TesteryGitOwner}"
echo "  Git Repo: ${TesteryGitRepo}"
echo "  Git Ref: ${TesteryGitReference}"
echo "  Testery User: ${TesteryApiUser}"
echo "  Testery API URL: ${TesteryApiUrl}"
echo "  Testery Feature Path: ${TesteryFeaturePath}"
echo "  Testery Environment: ${TesteryEnvironment}"

# Parameters
$baseUrl = $TesteryApiUrl

# Authenticate
$pair = "${TesteryApiUser}:${TesteryApiPassword}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"

$jsonHeaders = @{ 
  Authorization = $basicAuthValue;
  "accept"="application/json";
}
    
# Create a test run.
$request = "{`"owner`":`"${TesteryGitOwner}`",`"repository`":`"${TesteryGitRepo}`",`"ref`":`"${TesteryGitReference}`",`"project`":`"${TesteryProjectName}`",`"environment`":`"${TesteryEnvironment}`",`"buildId`":`"${TesteryBuildId}`"}"
echo $request
$testRun = Invoke-WebRequest `
	-UseBasicParsing `
	-Uri "${baseUrl}/test-run-requests-build" `
	-Method "POST" `
	-Headers $jsonHeaders `
	-ContentType "application/json" `
	-Body ${request} | ConvertFrom-Json

$testRunId = $testRun.id

echo "Started test run: ${testRunId}"
$status = $testRun.status
write-output "Status: ${status}";

# Wait for results.
$testRun = Invoke-WebRequest -Headers $jsonHeaders -UseBasicParsing "${baseUrl}/test-run-results/${testRunId}" | ConvertFrom-Json

while(!(($testRun.status -eq "PASS") -or ($testRun.status -eq "FAIL"))) 
{
	sleep 5
	write-output "Polling ${baseUrl}/test-run-results/${testRunId}"
	$testRun = Invoke-WebRequest -Headers $jsonHeaders -UseBasicParsing "${baseUrl}/test-run-results/${testRunId}" | ConvertFrom-Json
	write-output $testRun.status
}

write-output "Test run complete."