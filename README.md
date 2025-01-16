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

This design allows multiple hubs with 3P firewalls to exchange traffic with Aviatrix dataplane
It allows for single transite / ars along with multiple hubs.

## Caveats
- Prod to Dev would need direct peering to communicate (or maybe deeper investigation)
- Routing between different regions would require some static route announcement on BGPoLAN to ARS as, in the case of multiple ARS, we would have duplicate 65515 ASN thus being rejected by each other (loop prevention mechanism)