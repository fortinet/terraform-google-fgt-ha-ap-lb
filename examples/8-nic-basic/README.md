# Example: Multi-NIC FortiGate HA cluster

If chosing the multi-nic architecture for FortiGate NVAs in Google Cloud administrators need to connect multiple networks to the instances. While it is usually not the recommended approach you can use this module to deploy a multi-nic architecture. As an alternative to using dedicated NICs per VPC network administratos can try more flexible peered hub-and-spoke or NCC star topology architectures.

To deploy a multi-nic architecture use subnets variable to pass more subnet names and ha_port together with mgmt_port to select desired HA and dedicated management ports:

```
  subnets = [
    "external",
    "mgmt",
    "internal1",
    "internal2",
    "internal3",
    "internal4",
    "internal5",
    "internal6"
  ]
  ha_port   = "port2"
  mgmt_port = "port2"
```