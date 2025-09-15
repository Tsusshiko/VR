# Projeto de Virtualização de Redes


## Topologia
     h1   h2  h3
       \  | /
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
         h4

### Compilar P4
```bash
p4c-bm2-ss --std p4-16  p4/l3switch.p4 -o json/l3switch.json
p4c-bm2-ss --std p4-16  p4/l2switch.p4 -o json/l2switch.json
```

### Num terminal (executar mininet):
```bash
sudo python3 mininet/task3-topo.py --jsonR json/l3switch.json --jsonS json/l2switch.json
```

### Noutro terminal (regras flow dos dispositivos):
```bash
simple_switch_CLI --thrift-port 9090 < flows/r1-flows.txt
simple_switch_CLI --thrift-port 9091 < flows/r2-flows.txt
simple_switch_CLI --thrift-port 9092 < flows/r3-flows.txt
simple_switch_CLI --thrift-port 9093 < flows/r4-flows.txt
simple_switch_CLI --thrift-port 9094 < flows/r5-flows.txt
simple_switch_CLI --thrift-port 9095 < flows/r6-flows.txt
simple_switch_CLI --thrift-port 9096 < flows/s1-flows.txt
...
```

### Testar conetividade
```bash
mininet> h1 ping h4
```
