from datetime import datetime, timedelta
import os
import logging
from multiprocessing import Pool

# Configure basic logging
logging.basicConfig()
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

# The main entrypoint of the background job
def main(id: str, duration: int, num_workers: int):
    logger.info(f"Starting job {id}")

    with Pool(processes=num_workers) as pool:
        pool.starmap(process, [(wid, duration) for wid in range(1, num_workers + 1)])

    logger.info(f"Finished job {id}")

# This is the mock CPU-bound process, one process will pin a single core
def process(wid: int, duration: int):
    logger.info(f"Starting worker {wid}")
    end_time = datetime.now() + timedelta(seconds=duration)
    while datetime.now() < end_time:
        pass
    logger.info(f"Finished worker {wid}")

if __name__ == "__main__":
    # Initialise job parameters from environment
    id = os.getenv("JOB_ID")
    assert id, "JOB_ID must be set"
    duration = os.getenv("JOB_DURATION_SECONDS")
    assert duration and duration.isdigit() and int(duration) > 0, "JOB_DURATION_SECONDS must be a positive integer"
    workers = os.getenv("JOB_WORKERS")
    assert workers and workers.isdigit() and int(workers) > 0, "JOB_WORKERS must be a positive integer"

    # Kick off the job...
    main(id, int(duration), int(workers))
