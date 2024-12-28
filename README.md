# wlp-demo

## Architecture diagram

## Use case
This use case demonstrates how Aviatrix transit can live with Azure Route Server + firewall in a peered vnet.
- With no BGP announcement from the firewall toward Aviatrix (via ARS) because we do not want to run BGP on firewalls
- Best design would be to have BGP peering between firewalls and ARS advertising spokes' CIDRs with a next-hop being ILB frontend IP.

## Facts
- We know we cannot exchange route between 2 hubs using ARS (as ARS has to be 65515). Loop prev. mechanism will kick in.
- We know we can only peer an Aviatrix transit to a single ARS, otherwise, we need to deploy second Aviatrix transit

## Potential designs

### ARS dual-homed design with direct peering between existing hub and new transit to get valid next hop

spoke <--> fw-hub <--> ars-hub <--> Aviatrix transit
              ^----------------------------^