# zib-airflow

**Airflow on ECS Fargate/EC2**

This uses's the [puckel/docker-airflow docker](https://github.com/puckel/docker-airflow) implementation but extended to run on ECS via Fargate or EC2.  

Airflow
-
* Implementation runs default with LocalExecutor. Dependencies within AWS
    1. Aurora (Airflow logging)
    2. AWS S3 (Object Store Logging)
    3. Cloudwatch (Monitoring)
    4. Route53 (DNS/Alias)
    5. Application Load Balancer (Needed because ECS runs in private subnets)

Forked
    https://github.com/polyglotDataNerd/docker-airflow
    
Sample Docker Commands:
    
    Local: 
        docker run -d -p 8080:8080 airflow-development
        docker run --rm -ti airflow-development bash   
    
    
    
    