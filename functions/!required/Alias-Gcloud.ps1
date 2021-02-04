function Run-gcloud {
if ($args[0] -eq "c") {
    if ($args[1] -eq "i") {
    . gcloud compute instances $args[2-$args[-1]] } else {
        . gcloud compute $args }
    . gcloud $args
}

Set-Alias g Run-gcloud
