# E2E tests for Huy's flows (Flashcard + Quiz)
$BaseUrl = "http://localhost:5082"
$results = @()

function Write-TestResult($name, $passed, $detail) {
    $script:results += [pscustomobject]@{ Test = $name; Passed = $passed; Detail = $detail }
    $icon = if ($passed) { "PASS" } else { "FAIL" }
    Write-Host "[$icon] $name - $detail"
}

function New-WebSessionWithToken {
    param([string]$Url)
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $resp = Invoke-WebRequest -Uri $Url -WebSession $session -UseBasicParsing
    $token = $null
    if ($resp.Content -match 'name="__RequestVerificationToken" type="hidden" value="([^"]+)"') {
        $token = $Matches[1]
    }
  return @{ Session = $session; Token = $token; Response = $resp }
}

# --- 1. SME Flashcard Index ---
try {
    $r = Invoke-WebRequest -Uri "$BaseUrl/Flashcard/Index?courseId=1" -UseBasicParsing
    $ok = $r.StatusCode -eq 200 -and $r.Content -match 'Flashcard'
    Write-TestResult "SME Flashcard Index" $ok "HTTP $($r.StatusCode)"
} catch { Write-TestResult "SME Flashcard Index" $false $_.Exception.Message }

# --- 2. SME Flashcard Editor (GET) ---
try {
    $r = Invoke-WebRequest -Uri "$BaseUrl/Flashcard/Editor?courseId=1" -UseBasicParsing
    $ok = $r.StatusCode -eq 200 -and $r.Content -match 'editorForm|Name'
    Write-TestResult "SME Flashcard Editor GET" $ok "HTTP $($r.StatusCode)"
} catch { Write-TestResult "SME Flashcard Editor GET" $false $_.Exception.Message }

# --- 3. SME Create + Publish Deck (POST) ---
try {
    $ctx = New-WebSessionWithToken "$BaseUrl/Flashcard/Editor?courseId=1"
    $body = @{
        __RequestVerificationToken = $ctx.Token
        DeckId = 0
        CourseId = 1
        Name = "E2E Test Deck $(Get-Date -Format 'HHmmss')"
        ModuleId = 1
        Category = "E2E"
        'Cards[0].FrontText' = 'Term 1'
        'Cards[0].BackText' = 'Def 1'
        'Cards[1].FrontText' = 'Term 2'
        'Cards[1].BackText' = 'Def 2'
        'Cards[2].FrontText' = 'Term 3'
        'Cards[2].BackText' = 'Def 3'
        'Cards[3].FrontText' = 'Term 4'
        'Cards[3].BackText' = 'Def 4'
        'Cards[4].FrontText' = 'Term 5'
        'Cards[4].BackText' = 'Def 5'
        action = 'publish'
    }
    $resp = Invoke-WebRequest -Uri "$BaseUrl/Flashcard/Editor" -Method POST -WebSession $ctx.Session -Body $body -MaximumRedirection 5 -UseBasicParsing
    $deckId = $null
    if ($resp.BaseResponse.ResponseUri.Query -match 'deckId=(\d+)') { $deckId = [int]$Matches[1] }
    elseif ($resp.Content -match 'deckId=(\d+)') { $deckId = [int]$Matches[1] }
    $ok = $resp.StatusCode -eq 200 -and $deckId -gt 0
    Write-TestResult "SME Create+Publish Deck" $ok "deckId=$deckId"
} catch { Write-TestResult "SME Create+Publish Deck" $false $_.Exception.Message; $deckId = $null }

# --- 4. SME AI Staging (GET) ---
try {
    $stagingDeckId = if ($deckId) { $deckId } else { 1 }
    $r = Invoke-WebRequest -Uri "$BaseUrl/Flashcard/Staging?deckId=$stagingDeckId" -UseBasicParsing
    $ok = $r.StatusCode -eq 200 -and $r.Content -match 'AI|Staging|Generate|sinh'
    Write-TestResult "SME AI Staging GET" $ok "deckId=$stagingDeckId HTTP $($r.StatusCode)"
} catch { Write-TestResult "SME AI Staging GET" $false $_.Exception.Message }

# --- 5. Student Flashcard Library ---
try {
    $r = Invoke-WebRequest -Uri "$BaseUrl/Flashcard/Library" -UseBasicParsing
    $ok = $r.StatusCode -eq 200
    $hasDecks = $r.Content -match 'Bo the|deck|Luyện|Practice|flashcard' -or $r.Content -match 'PUBLISHED'
    Write-TestResult "Student Flashcard Library" ($ok -and $hasDecks) "HTTP $($r.StatusCode)"
} catch { Write-TestResult "Student Flashcard Library" $false $_.Exception.Message }

# --- 6. Student Flashcard Practice ---
try {
    $practiceDeckId = 9  # PUBLISHED deck from seed
    $r = Invoke-WebRequest -Uri "$BaseUrl/Flashcard/Practice?deckId=$practiceDeckId" -UseBasicParsing
    $ok = $r.StatusCode -eq 200 -and ($r.Content -match 'Remember|Practice|flashcard|btn-forgot|btn-remember' -or $r.Content.Length -gt 500)
    Write-TestResult "Student Flashcard Practice GET" $ok "deckId=$practiceDeckId"
} catch { Write-TestResult "Student Flashcard Practice GET" $false $_.Exception.Message }

# --- 7. Record Review API ---
try {
    $cardId = (sqlcmd -S ".\SQLEXPRESS" -d EduNexus_New_02 -Q "SET NOCOUNT ON; SELECT TOP 1 id FROM flashcard WHERE deck_id=9 AND status='ACTIVE'" -h -1 -W 2>$null).Trim()
    if ($cardId) {
        $json = @{ deckId = 9; flashcardId = [int]$cardId; remembered = $true } | ConvertTo-Json
        $r = Invoke-WebRequest -Uri "$BaseUrl/Flashcard/RecordReview" -Method POST -Body $json -ContentType "application/json" -UseBasicParsing
        $ok = $r.StatusCode -eq 200
        Write-TestResult "Student RecordReview API" $ok "cardId=$cardId HTTP $($r.StatusCode)"
    } else {
        Write-TestResult "Student RecordReview API" $false "No active card found"
    }
} catch { Write-TestResult "Student RecordReview API" $false $_.Exception.Message }

# --- 8. Student New Quiz (GET) ---
try {
    $r = Invoke-WebRequest -Uri "$BaseUrl/Quiz/New" -UseBasicParsing
    $ok = $r.StatusCode -eq 200 -and $r.Content -match 'Quiz|quiz-form-card'
    Write-TestResult "Student New Quiz GET" $ok "HTTP $($r.StatusCode)"
} catch { Write-TestResult "Student New Quiz GET" $false $_.Exception.Message }

# --- 9. Create Practice Quiz + Taking ---
$attemptId = $null
try {
    $ctx = New-WebSessionWithToken "$BaseUrl/Quiz/New"
    $body = @{
        __RequestVerificationToken = $ctx.Token
        'Form.QuizName' = 'E2E Quiz Test'
        'Form.CourseId' = 13
        'Form.ModuleId' = ''
        'Form.Difficulty' = 'MEDIUM'
        'Form.QuestionCount' = 2
    }
    $resp = Invoke-WebRequest -Uri "$BaseUrl/Quiz/Create" -Method POST -WebSession $ctx.Session -Body $body -MaximumRedirection 5 -UseBasicParsing
    if ($resp.BaseResponse.ResponseUri -match 'attemptId=(\d+)') { $attemptId = [int]$Matches[1] }
    elseif ($resp.Content -match 'attemptId=(\d+)') { $attemptId = [int]$Matches[1] }
    $ok = $attemptId -gt 0
    Write-TestResult "Student Create Practice Quiz" $ok "attemptId=$attemptId"
} catch { Write-TestResult "Student Create Practice Quiz" $false $_.Exception.Message }

# --- 10. Quiz Taking ---
try {
    if (-not $attemptId) { throw "No attemptId from previous step" }
    $r = Invoke-WebRequest -Uri "$BaseUrl/Quiz/Taking?attemptId=$attemptId" -UseBasicParsing
    $ok = $r.StatusCode -eq 200 -and $r.Content -match 'quizForm|Submit'
    Write-TestResult "Student Quiz Taking GET" $ok "attemptId=$attemptId"
} catch { Write-TestResult "Student Quiz Taking GET" $false $_.Exception.Message }

# --- 11. Submit Quiz ---
try {
    if (-not $attemptId) { throw "No attemptId" }
    $ctx = New-WebSessionWithToken "$BaseUrl/Quiz/Taking?attemptId=$attemptId"
    # Extract question IDs from embedded JSON in page
    $qIds = [regex]::Matches($ctx.Response.Content, 'Answers\[(\d+)\]') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
    $body = @{
        __RequestVerificationToken = $ctx.Token
        AttemptId = $attemptId
    }
    foreach ($qid in $qIds) { $body["Answers[$qid]"] = 'A' }
    $resp = Invoke-WebRequest -Uri "$BaseUrl/Quiz/Submit" -Method POST -WebSession $ctx.Session -Body $body -MaximumRedirection 5 -UseBasicParsing
    $ok = $resp.StatusCode -eq 200 -and ($resp.Content -match 'Result|Score|quiz-result' -or $resp.BaseResponse.ResponseUri -match 'Result')
    Write-TestResult "Student Quiz Submit" $ok "questions=$($qIds.Count)"
} catch { Write-TestResult "Student Quiz Submit" $false $_.Exception.Message }

# --- 12. Quiz Result ---
try {
    if (-not $attemptId) { throw "No attemptId" }
    $r = Invoke-WebRequest -Uri "$BaseUrl/Quiz/Result?attemptId=$attemptId" -UseBasicParsing
    $ok = $r.StatusCode -eq 200
    Write-TestResult "Student Quiz Result" $ok "attemptId=$attemptId"
} catch { Write-TestResult "Student Quiz Result" $false $_.Exception.Message }

# --- 13. Quiz History ---
try {
    $r = Invoke-WebRequest -Uri "$BaseUrl/Quiz/History" -UseBasicParsing
    $ok = $r.StatusCode -eq 200
    Write-TestResult "Student Quiz History" $ok "HTTP $($r.StatusCode)"
} catch { Write-TestResult "Student Quiz History" $false $_.Exception.Message }

Write-Host "`n========== SUMMARY =========="
$passed = ($results | Where-Object Passed).Count
$total = $results.Count
Write-Host "Passed: $passed / $total"
$results | Format-Table -AutoSize
if ($passed -lt $total) { exit 1 }
