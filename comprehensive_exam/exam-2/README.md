#### 部署方式
- 透過 terraform 部署 EKS
    - 初始化載入模組： `terraform init`
    - 部署應用： `terraform apply`
    - 安裝好 kubectl 後執行該指令下載叢集資訊於本地 configuration: `aws eks --region ap-east-1 update-kubeconfig --name $(terraform output -raw cluster_name)`
- 部署 k8s 服務
    - `kubectl apply -f k8s-manifest/namespace.yaml -f k8s-manifest/gp3-storage-class.yaml`
    - `kubectl apply -f k8s-manifest/mysql.yaml -f k8s-manifest/asiayo-web.yaml`