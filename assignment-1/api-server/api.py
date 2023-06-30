import logging
import os
import uuid

from fastapi import FastAPI
from kubernetes import client, config

# Configure logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

app = FastAPI()

config.load_incluster_config()

@app.post("/api/job")
async def queue_job():
    job_id = str(uuid.uuid4())

    # Configure background job image uri here
    job_image_uri = os.getenv('JOB_IMAGE_URI')
    job_namespace = 'default'

    tolerations = [
    ]

    node_selector = {
        "worker-type": "batch-jobs",
    }

    pod_template = client.V1PodTemplateSpec(
        spec=client.V1PodSpec(
            restart_policy="Never",
            containers=[
                client.V1Container(
                    name="job",
                    image=job_image_uri,
                    env=[
                        client.V1EnvVar(name="JOB_ID", value=job_id),
                        client.V1EnvVar(name="JOB_DURATION_SECONDS", value="300"),
                        client.V1EnvVar(name="JOB_WORKERS", value="1"),
                    ],
                    resources=client.V1ResourceRequirements(
                        requests={"cpu": "1000m"}
                    ),
                )
            ],
            tolerations=tolerations,
            node_selector=node_selector,
        ),
    )

    job = client.V1Job(
        api_version="batch/v1",
        kind="Job",
        metadata=client.V1ObjectMeta(name=f"bg-job-{job_id}", labels={"job_id": job_id}),
        spec=client.V1JobSpec(
            backoff_limit=0,
            template=pod_template,
        )
    )

    batch_v1 = client.BatchV1Api()
    batch_v1.create_namespaced_job(body=job, namespace=job_namespace)

    return {"message": f"job {job_id} queued"}
