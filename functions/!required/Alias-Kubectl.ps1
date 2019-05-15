function global:Run-kubectl {
    . kubectl $args
}
function Run-kubedescribe {
    . kubectl describe $args
}

function Run-kubedelete {
    . kubectl delete $args
}

Set-Alias k Run-kubectl
set-alias kd Run-kubedescribe
set-alias kdel Run-kubedelete