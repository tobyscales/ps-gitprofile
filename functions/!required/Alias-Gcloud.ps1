function Run-gcloud {
    . gcloud $args
}
function Run-gcloudCompute {
    . gcloud compute $args
}

function Run-gcloudComputeInstances {
    . gcloud compute instances $args
}

Set-Alias g Run-gcloud
set-alias gc Run-gcloudCompute
set-alias gci Run-gcloudComputeInstances
