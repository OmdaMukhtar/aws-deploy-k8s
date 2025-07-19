# Deplpu LAMP Stacl on K8s(Kubernetes)



## Structure

```sh
lamp-on-aws/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── scripts/
│       ├── master.sh.tpl
│       ├── worker.sh.tpl
│       └── lamp-deploy.sh.tpl
├── kubernetes/
│   ├── apache/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── php/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── mysql/
│       ├── deployment.yaml
│       ├── service.yaml
│       └── pvc.yaml

```

## Variables values

```
terraform apply -var-file="prod.tfvars"
```

## Run

```sh
cd terraform
terraform init
terraform apply
```

## Fix common files issue between Windows and Ubuntu

- fix file issues for windows

```sh
dos2unix scripts/lamp-deploy.sh.tpl or sed -i 's/\r$//' scripts/lamp-deploy.sh.tpl
```

- be care when using file provision you must use without slash to  copy all folder inside the kubernets

```sh
  provisioner "file" {
    source      = "../kubernetes" # wrong "../kubernetes/"
    destination = "/home/ubuntu/kubernetes/"
  }
```
