## Usage

### Prerequisites

- Kubernetes cluster
- `kubectl` configured to communicate with your cluster
- Docker (if you need to build custom images)
- `bash` shell

### Deployment Steps

1. Clone this repository:
   ```
   git clone [your-repo-url]
   cd [your-repo-directory]
   ```

2. Create a `.env` file in the root directory with your Elastic APM configuration:
   ```
   ELASTIC_APM_SERVICE_NAME: your-service-name
   ELASTIC_APM_SECRET_TOKEN: your-secret-token
   ELASTIC_APM_SERVER_URL: https://your-apm-server-url:443
   ```

3. Run the `replace_tokens.sh` script to update the Kubernetes deployment file:
   ```
   chmod +x replace_tokens.sh
   ./replace_tokens.sh
   ```

4. Apply the Kubernetes deployment:
   ```
   kubectl apply -f kubernetes-deployment.yaml
   ```

5. Verify the deployment:
   ```
   kubectl get pods -n ruby-prometheus-metrics
   ```

### Accessing the Application

Once deployed, you can access the application through the Ingress. If you're using a local Kubernetes cluster like Minikube, you may need to use port-forwarding:

```
kubectl port-forward service/ruby-app-service -n ruby-prometheus-metrics 8080:80
```

Then access the application at `http://localhost:8080`.

### Updating the Deployment

If you need to update the Elastic APM configuration:

1. Modify the `.env` file with new values.
2. Run the `replace_tokens.sh` script again.
3. Apply the updated deployment:
   ```
   kubectl apply -f kubernetes-deployment.yaml
   ```

### Cleaning Up

To remove the deployment from your cluster:

```
kubectl delete -f kubernetes-deployment.yaml
```

Note: This will delete all resources defined in the deployment file, including the namespace.
