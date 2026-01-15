# Deciding network interfaces (NICs) for FortiGate HA cluster

This article describes available options for connecting network interfaces in various architectures of FortiGate HA deployments in Google Cloud. Keep in mind that changing network configuration of VM instances in GCP is not possible after deployment, so it is important to decide how many interfaces to use during deployment.

## NIC limitations in Google Cloud

VM instances in Google Cloud are limited regarding number of available network interfaces according to a simple formula:

NICs = max( 2, min( CPUs, 8 ))

which translates to "VM instances with 2 or more vCPUs can have at most as many NICs as vCPUs, but no more than 8; VM instances with less than 2 vCPUs can have at most 2 NICs".

### NICs and performance

Note that additional NICs do **NOT** increase the performance of a VM, but sometimes can decrease it. Network throughput limits are not enforced per network interface, but rather per instance therefore adding a NIC will not increase these limits. Performance can be degraded though due to the way how network queues are assigned between interfaces. It is a general good practice to not use more interfaces than needed.

## FortiGate HA and network interfaces

* FortiGate HA cluster (FGCP) requires dedicated NIC for HA sync and heartbeat as well as a dedicated management NIC. By default these two are separate but starting from version 7.0 administrator can use the same NIC for both functions.
* FortiGate best practices recommend having separate external and internal interfaces

The requirements mentioned above lead to the standard deployment with 4 NICs: 2 for traffic (external and internal) and 2 for HA (heartbeat and management). While not obligatory, most public cloud deployments of FortiGates use the same standard order of ports:
- port1: external traffic and default route
- port2: internal networks
- port3: FGCP heartbeat and synchronization
- port4: dedicated management

## FortiGate NICs and Interconnect

Interconnect is usually deployed into a separate VPC network, which requires additional NIC connected to FortiGate instances. If the performance requirements are met with a 4-vCPU instance the recommended solution is to deploy instances with 4 NICs: 
- port1: external, 
- port2: internal, 
- port3: interconnect,
- port4: heartbeat and management

## Multiple internal networks

For deployments where FortiGate is used for inspecting traffic between internal groups of resources in Google Cloud administrators have the following options:

1. peering-based hub-and-spoke - FortiGate uses one interface (port2) connected to *Internal* VPC network, all resources are located in other VPC networks peered with *Internal*. Custom static route (usually 0.0.0.0/0) in the *Internal* is exported to all peered networks using VPC peering options and causes packets exiting spoke VPCs to be sent to FortiGate port2. This solutions is limited to 25 spoke VPCs, FortiGate firewall policies for eas-west traffic will have source and destination interface set to *port2*, resources have no possibility to bypass FortiGate. This module does not deploy VPC peerings for this design, but includes custom static route.
1. Single VPC with policy-based routes (PBRs) - FortiGate uses one interface (port2) connected to *Internal* VPC network, all resources are deployed to the same VPC. Traffic between resources is redirected via FortiGate port2 using [policy-based routes](https://cloud.google.com/vpc/docs/policy-based-routes). Resources not included in PBRs can freely communicate bypassing FortiGates. This module does not deploy PBRs and you might want to remove the default custom static route by setting variable `routes` to empty object: `routes={}`.
1. Multi-nic - FortiGate uses multiple internal interfaces connected to multiple VPC networks, each VPC has it's own static custom route sending traffic to respective FortiGate interface. This setup resembles a deployment in a physical network with each VPC network available on different interface. Due to limitations of public cloud this setup is limited to 6 internal networks, requires larger instance types and interfaces cannot be modified without re-deployment of the solution.
1. (new) NCC Star topology - at the time of writing this solution was in preview and was not yet fully working due to missing routing solution in Google Cloud.