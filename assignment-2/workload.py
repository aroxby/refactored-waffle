import logging
import sys
import asyncio  
import aiohttp
import os
from urllib.parse import urlparse

# Configure logger
logger = logging.getLogger(__name__)
logger.addHandler(logging.StreamHandler(sys.stdout))
logger.setLevel(logging.DEBUG)

async def test_workload(server_url):
  """
  Represents a workload of 16 concurrent jobs needing 4 workers each, followed by a 10 second wait, and then 1 job needing 4 workers.
  """
  logger.info(f"Test workload: starting 🚧")  
  
  async with aiohttp.ClientSession(headers={'Content-Type': 'application/json'}) as client:
    for i in range(16):
      url = urlparse(f"{server_url}/api/job").geturl()      
      async with client.post(url=url, json={"workers": 4, "duration": 100}) as resp:
        await resp.json()
        assert resp.status == 200, "Failed to add job"
    
    await asyncio.sleep(10)
    
    async with client.post(url=url, json={"workers": 4, "duration": 100}) as resp:
      json = await resp.json()
      assert resp.status == 429, "Failed to get rate limited response"
      assert json["expected_availability_in"] > 0, "Expected available at to be greater than 0"
  
  logger.info(f"Test workload: passed ✅")

if __name__ == "__main__":
  server_url = os.getenv("SERVER_URL")
  assert server_url, "SERVER_URL must be specified(e.g http://localhost:8888)"
    
  asyncio.run(test_workload(server_url=server_url))