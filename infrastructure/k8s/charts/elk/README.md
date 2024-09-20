# ELK Stack Chart (Kibana excluded)

This Chart automates the deployment of `ElasticSearch`, `LogStash` and `FileBeat` to your Kubernetes cluster. Kibana was excluded because it tends to be problematic, so it's better installed using its own chart.





## How to Use this Chart

```sh
helm dependency build .

helm install elk . -n <designated_namespace>
```


> In the Values file, take note of:
> - ElasticSearch's `volumeClaimTemplate.storageClassName`: It should be empty (or set to something like "Standard" or "default") when testing locally and set to the correct storage class name when deploying to the cloud. You can also adjust the requested storage ad needed
> - For Logstash's `service.type`: ensure you set it to the correct type. Something like "LoadBalancer would not be suitable when working locally"
