function Run-kubectl {
    . kubectl $args
}
function Run-kubedescribe {
    . kubectl describe $args
}

function Run-KubeDelete {
    . kubectl delete $args
}

function Run-TerraformPlan {
    . terraform plan $args
}

function Run-TerraformApply {
    . terraform apply -auto-approve $args
}


Set-Alias k Run-kubectl
set-alias kd Run-kubedescribe
set-alias kdel Run-KubeDelete

Set-Alias tfp Run-TerraformPlan
Set-Alias tfa Run-TerraformApply
