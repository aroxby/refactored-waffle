from contextlib import contextmanager
import logging
import os
import uuid

from fastapi import Body, FastAPI, Response
from kubernetes import client, config

from capacity import capacity_usage, get_running_jobs, OverCapacityError

# Configure logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

app = FastAPI()

config.load_incluster_config()


@app.get("/api/jobs", status_code=200)
async def get_jobs():
    jobs = get_running_jobs()
    return jobs



@app.post("/api/job", status_code=200)
async def queue_job(response: Response, job_data: dict = Body()):
    # TODO: Use a model to detect ints so that we raise a 4XX instead of 5XX
    job_duration = int(job_data.get('duration', 60))
    job_workers = int(job_data.get('workers', 4))

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
                        client.V1EnvVar(name="JOB_DURATION_SECONDS", value=str(job_duration)),
                        client.V1EnvVar(name="JOB_WORKERS", value=str(job_workers)),
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

    try:
        with capacity_usage(job_workers, job_id, job_duration):
            batch_v1 = client.BatchV1Api()
            batch_v1.create_namespaced_job(body=job, namespace=job_namespace)
    except OverCapacityError as exc:
        response.status_code = 429
        return {'expected_availability_in': exc.delay}

    return {"message": f"job {job_id} queued"}
