# GVR: Task 3 - Fish Topology

## Task Overview
Define the Controler Rules for the following topology `flows/`


## Topology
     h1     h2
       \   /
        s1
         |
        r1
       /  \
     r6    r2
     |      |
     r5     r3
       \   /
         r4
         |
         h3


### Network Configuration
<span style="color: red;">just a suggestion you can do your own mapping</span>


| Device   | Interface/Port        | MAC Address          | IP Address       |
|----------|-----------------------|----------------------|------------------|
| h1       | h1-eth0              | aa:00:00:00:00:01   | 10.0.1.1/24      |
| h2       | h2-eth0              | aa:00:00:00:00:02   | 10.0.1.2/24      |
| h3       | h3-eth0              | aa:00:00:00:00:03   | 10.0.2.1/24      |
| s1       | s1-eth1 (to h1)      | cc:00:00:00:01:01   | N/A              |
| s1       | s1-eth2 (to h2)      | cc:00:00:00:01:02   | N/A              |
| s1       | s1-eth3 (to r1)      | cc:00:00:00:01:03   | N/A              |
| r1       | r1-eth1 (to s1)      | aa:00:00:00:01:01   | 10.0.1.254/24    |
| r1       | r1-eth2 (to r2)      | aa:00:00:00:01:02   | 10.0.12.2/24      |
| r1       | r1-eth3 (to r6)      | aa:00:00:00:01:03   | 10.0.16.3/24      |
| r2       | r2-eth1 (to r1)      | aa:00:00:00:02:01   | 10.0.12.1/24      |
| r2       | r2-eth2 (to r3)      | aa:00:00:00:02:02   | 10.0.23.2/24      |
| r3       | r3-eth1 (to r2)      | aa:00:00:00:03:01   | 10.0.23.1/24      |
| r3       | r3-eth2 (to r4)      | aa:00:00:00:03:02   | 10.0.34.2/24      |
| r4       | r4-eth1 (to h3)      | aa:00:00:00:04:01   | 10.0.2.254/24     |
| r4       | r4-eth2 (to r5)      | aa:00:00:00:04:02   | 10.0.45.2/24      |
| r4       | r4-eth3 (to r3)      | aa:00:00:00:04:03   | 10.0.43.3/24      |
| r6       | r6-eth1 (to r1)      | aa:00:00:00:06:01   | 10.0.16.1/24      |
| r6       | r6-eth2 (to r5)      | aa:00:00:00:06:02   | 10.0.56.2/24      |
| r5       | r5-eth1 (to r6)      | aa:00:00:00:05:01   | 10.0.56.1/24      |
| r5       | r5-eth2 (to r4)      | aa:00:00:00:05:02   | 10.0.45.3/24      |



## Key Notes
- **No P4 Code Changes Required:** The provided P4 programs `p4/l3switch.p4` and `p4/l2switch.p4` remains the same.
- **ARP Configuration:** ARP tables and default routes for hosts are pre-configured by the Mininet script.
- **Separate Flow Rules:** Each P4 device requires its own set of flow rules.

### Compile P4
```bash
p4c-bm2-ss --std p4-16  p4/l3switch.p4 -o json/l3switch.json
p4c-bm2-ss --std p4-16  p4/l2switch.p4 -o json/l2switch.json
```

### Run
```bash
sudo python3 mininet/task3-topo.py --jsonR json/l3switch.json --jsonS json/l2switch.json
```

### Load flow rules
```bash
simple_switch_CLI --thrift-port <r1_port> < flows/r1-flows.txt
simple_switch_CLI --thrift-port <r2_port> < flows/r2-flows.txt
...
```

### Test
```bash
mininet> h1 ping h3 -c 5
```

## Debugging Tips

Here are some useful commands to help troubleshoot and verify your topology:

### 1. **Wireshark (Packet Capture)**

### 2. **ARP Table Inspection**
   - **Command:** `arp -n`
   - **Usage:** Check the ARP table on any Mininet host to ensure proper IP-to-MAC Default gateway resolution.
   - Example:
     ```bash
     mininet> h1 arp -n
     ```

### 3. **Interface Information**
   - **Command:** `ip link`
   - **Usage:** Display the state and configuration of network interfaces for each host or router.
   - Example:
     ```bash
     mininet> r1 ip link
     ```

### 4. **P4 Runtime Client for Monitoring**
   - **Command:** `sudo ./tools/nanomsg_client.py --thrift-port <r1_port or r2_port>`
   - **Usage:** Interact with the P4 runtime to inspect flow tables and rules loaded on each router.
   - Example:
     ```bash
     sudo ./tools/nanomsg_client.py --thrift-port 9090
     ```

These commands will help you inspect network traffic, verify ARP entries, check interface states, and interact directly with the P4 routers.
