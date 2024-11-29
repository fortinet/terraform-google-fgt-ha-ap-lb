# Example: API token

This example will create on FortiGates an API user account and will assign it a 'prof_admin' role and a random token generated during terraform deployment. The token will be stored in GCP Secret Manager and in module outputs. Access will be restricted to 10.0.0.0/24 subnet.

Creating an API user during deployment can be helpful for multi-phase deployments where FortiGate configuration will be automated after it is already deployed.

Note: token will be visible to anyone having access to terraform state file, it is also included in VM instance metadata.

Note2: API user will be created **only** if variable api_accprofile is set. Variable `api_token_secret_name` is optional, if set to null (default) API token will not be saved to Secret Manager.