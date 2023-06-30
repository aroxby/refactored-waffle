Assignment 2: Limited capacity background job processor
================================================

This is a take home assignment where you will build following functionality over the top of your solution from assignment 1. 

Assuming the kubernetes cluster has a maximum total CPU capacity of 64 (excluding api server requirements), the API endpoint should either accept the job or return "expected_availability_in" (in seconds) from the time of request. The API endpoint should additionally accept two parameters in request body.
  - "duration": specifies the amount of time for which the background job should run
  - "workers": specifies the number of CPU cores the background job requires
For exact request/response structures, you can refer to the attached Open API Spec.

We expect the following characteristics of the solution you provide:
 - The API endpoint should follow the OpenAPI spec for request & response structures.
 - The sample workload attached should pass. This can be run using `SERVER_URL={ADD_SERVER_URL_HERE} python3 workload.py`. Install dependencies listed in `requirements.txt`.

Your solution will be tested against more workloads and assessed on the correctness of response and code quality of your solution.

All code and scripts must be put in a public GitHub repository. Include a README.md with instructions for running the service and any other information you feel is relevant.