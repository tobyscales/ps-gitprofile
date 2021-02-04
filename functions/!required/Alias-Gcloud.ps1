#using & because gcloud on Windows actually calls gcloud.ps1
function Run-gcloud {
    if ($args[0] -eq "c") {
    $drop, $keep = $args #https://stackoverflow.com/questions/24754822/powershell-remove-item-0-from-an-array
        if ($args[1] -eq "i") {
            $drop, $keep = $keep
            iex "gcloud compute instances $keep" } else {
        iex "gcloud compute $keep" }
    } else {
    iex "gcloud $args"
    }
}

Set-Alias g Run-gcloud
