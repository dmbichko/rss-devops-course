kubectl create namespace jenkins
kubectl apply -f jenkins-sa.yaml
kubectl apply -f jenkins-pv.yaml
helm repo add jenkinsci https://charts.jenkins.io
helm repo update
chart=jenkinsci/jenkins
helm install jenkins -n jenkins -f jenkins-values.yaml $chart
kubectl get all -n Jenkins
kubectl describe pod jenkins-0 -n jenkins
helm upgrade --install jenkins -n jenkins -f jenkins-values.yaml jenkinsci/jenkins