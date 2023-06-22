import logging
import os
import uvicorn

# Configure basic logging
logging.basicConfig()
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

if __name__ == '__main__':
    uvicorn.run("api:app", host="0.0.0.0", port=8888, reload=False, log_level="debug", workers=1)