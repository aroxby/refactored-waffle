from contextlib import contextmanager
import logging
import os
from time import time
import uuid

from fastapi import FastAPI, Response
import redis
from kubernetes import client, config

# Configure logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

app = FastAPI()

config.load_incluster_config()

MAX_CAPCACITY = 64
CAPCACITY_LOCK_NAME = 'batch-lock'
CAPCACITY_KEY_NAME = 'batch-capacity'
CAPCACITY_JOB_KEY_PREFIX = 'batch-job-'


def round(n: float) -> int:
    return int(n + 0.5)


class OverCapacityError(Exception):
    def __init__(delay: int):
        self.delay = delay
        super()


def _get_running_jobs(cache) -> list[dict]:
    keys = cache.scan_iter(match=CAPCACITY_JOB_KEY_PREFIX + '*')
    values = mget(keys)
    running_jobs = (json.loads(value) for value in values if value)
    return running_jobs


def _find_capacity(cache, capacity: int, used_capacity: int) -> int:
    running_jobs = sorted(
        _get_running_jobs(cache),
        key = lambda job_data: job_data['end']
    )
    available_capacity = MAX_CAPCACITY - used_capacity
    delay = None
    while available_capacity < capacity and running_jobs:
        next_job = running_jobs.pop()
        available_capacity += next_job['capacity']
        delay = next_job['end']
    return delay


def _acquire_capacity(cache, capacity: int, job_id: str, ttl: int) -> None:
    used_capcity = cache.get(CAPCACITY_KEY_NAME) or 0
    cache.set(CAPCACITY_KEY_NAME, used_capcity + capacity)
    job_data = {
        'id': job_id,
        'capacity': capacity,
        'end': round(time()) + ttl,
    }
    cache.set(CAPCACITY_JOB_KEY_PREFIX + job_id, json.dumps(job_id), ttl)


def _reset_capacity() -> None:
    cache = redis.Redis(host=os.environ['REDIS_HOST'])
    running_jobs = _get_running_jobs(cache)
    used_capacity = sum(job['capacity'] for job in running_jobs)
    cache.set(CAPCACITY_KEY_NAME, used_capcity)


@contextmanager
def _capactiy_additon(capacity: int, job_id: str, ttl: int) -> None:
    cache = redis.Redis(host=os.environ['REDIS_HOST'])
    with redis.lock.Lock(cache, CAPCACITY_LOCK_NAME):
        used_capcity = cache.get(CAPCACITY_KEY_NAME) or 0
        candidate_capacity = used_capcity + capacity
        if candidate_capacity > MAX_CAPCACITY:
            delay = _find_capacity(cache, capacity, used_capacity)
            raise OverCapacityError(delay)
        yield
        _acquire_capacity(cache, capacity, job_id, ttl)
        loop = asyncio.get_running_loop()
        loop.call_later(ttl, _reset_capacity)


@app.post("/api/job", status_code=200)
async def queue_job(response: Response):
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
                        client.V1EnvVar(name="JOB_DURATION_SECONDS", value="60"),
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

    try:
        with _capactiy_additon(32, job_id, 60):
            batch_v1 = client.BatchV1Api()
            batch_v1.create_namespaced_job(body=job, namespace=job_namespace)
    except OverCapacityError as exc:
        response.status_code = 429
        return {'expected_availability_in': exc.delay}

    return {"message": f"job {job_id} queued"}
