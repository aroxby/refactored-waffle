import asyncio
from contextlib import contextmanager
import json
from time import time
import os

import redis

MAX_CAPCACITY = 64
CAPCACITY_LOCK_NAME = 'batch-lock'
CAPCACITY_KEY_NAME = 'batch-capacity'
CAPCACITY_JOB_KEY_PREFIX = 'batch-job-'


def round(n: float) -> int:
    return int(n + 0.5)


class OverCapacityError(Exception):
    def __init__(self, delay: int):
        self.delay = delay
        super()


def get_running_jobs() -> list[dict]:
    cache = redis.Redis(host=os.environ['REDIS_HOST'])
    return _get_running_jobs(cache)


def _get_running_jobs(cache) -> list[dict]:
    keys = cache.scan_iter(match=CAPCACITY_JOB_KEY_PREFIX + '*')
    values = cache.mget(keys)
    running_jobs = [json.loads(value) for value in values if value]
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
        delay = next_job['end'] - time()
    if delay is None:  # Integrity Error
        delay = 0
        _queue_reset_capacity(0)
    return delay


def _acquire_capacity(cache, capacity: int, job_id: str, ttl: int) -> None:
    used_capacity = cache.get(CAPCACITY_KEY_NAME) or 0
    used_capacity = int(used_capacity)
    cache.set(CAPCACITY_KEY_NAME, used_capacity + capacity)
    job_data = {
        'id': job_id,
        'capacity': capacity,
        'end': time() + ttl,
    }
    cache.set(CAPCACITY_JOB_KEY_PREFIX + job_id, json.dumps(job_data), ttl)


def _queue_reset_capacity(delay: int) -> None:
    loop = asyncio.get_running_loop()
    loop.call_later(delay, _reset_capacity)


def _reset_capacity() -> None:
    cache = redis.Redis(host=os.environ['REDIS_HOST'])
    with redis.lock.Lock(cache, CAPCACITY_LOCK_NAME):
        running_jobs = _get_running_jobs(cache)
        used_capacity = sum(job['capacity'] for job in running_jobs)
        cache.set(CAPCACITY_KEY_NAME, used_capacity)


@contextmanager
def capacity_usage(capacity: int, job_id: str, ttl: int) -> None:
    cache = redis.Redis(host=os.environ['REDIS_HOST'])
    with redis.lock.Lock(cache, CAPCACITY_LOCK_NAME):
        used_capacity = cache.get(CAPCACITY_KEY_NAME) or 0
        used_capacity = int(used_capacity)
        candidate_capacity = used_capacity + capacity
        if candidate_capacity > MAX_CAPCACITY:
            delay = _find_capacity(cache, capacity, used_capacity)
            raise OverCapacityError(round(delay))
        yield
        _acquire_capacity(cache, capacity, job_id, ttl)
        _queue_reset_capacity(ttl)
