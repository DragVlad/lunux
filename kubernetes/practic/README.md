sudo cat /etc/kubernetes/admin.conf

kubectl get nodes
kubectl get ns
kubectl apply -f test.yaml
kubectl create ns test
kubectl get pods -n test
kubectl describe pod my-pod -n test
kubectl get pod my-pod -n test -o yaml | less
kubectl -n test logs nginx
kubectl -n test logs nginx -c init-service
kubectl -n test delete pod nginx

kubectl -n work get all
kubectl -n work rollout restart deployment my-firts-deployment

kubectl -n work get EndpointSlice
kubectl -n work port-forward svc/my-first-service 8080:80