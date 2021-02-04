function Run-gcloud {
    if ($args[0] -eq "c") {
    $drop, $keep = $args #https://stackoverflow.com/questions/24754822/powershell-remove-item-0-from-an-array
        if ($args[1] -eq "i") {
            $drop, $keep = $keep
            . gcloud compute instances $keep } else {
        . gcloud compute $keep }
    . gcloud $args
    }
}

Set-Alias g Run-gcloud
