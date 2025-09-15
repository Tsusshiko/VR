# Projeto de Virtualização de Redes

## Task Overview 
- Os tuneis são decididos por hash através dos endereços de IP de source e destino.
  - 0 representa túnel 1 (R1-R2-R3-R4)  ou  (R4-R2-R3-R1)
  - 1 representa túnel 2 (R1-R6-R5-R4)  ou  (R4-R5-R6-R1)
- Encaminhamento através de labels (MSLP).
  - R1 e R4 definem os túneis e colocam as labels para os saltos do túnel escolhido nos flows.
  - Todos os routers dão pop da label que se encontra no topo da stack e reencaminham conforme essa label removida.
  - R1 e R4 removem não só a label final como removem o número de labels e reencaminham o pacote para os hosts da subrede dele após alterar o pacote para o tipo IPV4 (voltando então o pacote ao estado original).
- Estrutura do pacote:
  |dstAdr|srcAdr|Type|NLabels|Label1| .... |IPV4|
  |------|------|----|-------|------|------|----|
  - dstAdr, srcAdr e Type fazem parte da header do Ethernet
  - Type:
    - 0x8000 - IPV4
    - 0x88B5 - MSLP
  - Nlabels, é o número de labels no pacote (8 bits).
  - A nível do código, as labels são representadas por uma stack de labels (Cada label tem tamanho de 16 bits).

- Os tunéis são bidirecionais, e todos os hosts podem pingar os outros.
  - h1 - h4 ---> Hash
  - h4 - h1 ---> túnel 2
  - h2 - h4 ---> Hash
  - h4 - h2 ---> túnel 1
  - h3 - h4 ---> Hash
  - h4 - h3 ---> túnel 1
    - R4 tem uma predefinição para os tunéis, a escolha é feita tendo em conta o ip destino das mensagens, para alterar a escolha é necessário alterar os flows dele.
  
- Não implementamos a firewall.

## Topologia
     h1   h2  h3
       \ | /
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

### Configuração da Rede

| Device   | Interface/Port        | MAC Address          | IP Address       | Labels |
|----------|-----------------------|----------------------|------------------|--------|
| h1       | h1-eth0              | aa:00:00:00:00:01   | 10.0.1.1/24        | 0x0010 |
| h2       | h2-eth0              | aa:00:00:00:00:02   | 10.0.1.2/24        | 0x0020 |
| h3       | h3-eth0              | aa:00:00:00:00:03   | 10.0.1.3/24        | 0x0030 |
| h4       | h4-eth0              | aa:00:00:00:00:04   | 10.0.2.1/24        | N/A    |
| s1       | s1-eth1 (to h1)      | cc:00:00:00:01:01   | N/A                | N/A    |
| s1       | s1-eth2 (to h2)      | cc:00:00:00:01:02   | N/A                | N/A    |
| s1       | s1-eth2 (to h3)      | cc:00:00:00:01:03   | N/A                | N/A    |
| s1       | s1-eth3 (to r1)      | cc:00:00:00:01:04   | N/A                | N/A    |
| r1       | r1-eth1 (to s1)      | aa:00:00:00:01:01   | 10.0.1.254/24      | 0x1010 |
| r1       | r1-eth2 (to r2)      | aa:00:00:00:01:02   | N/A                | 0x1020 |
| r1       | r1-eth3 (to r6)      | aa:00:00:00:01:03   | N/A                | 0x1030 |
| r2       | r2-eth1 (to r1)      | aa:00:00:00:02:01   | N/A                | 0x2010 |
| r2       | r2-eth2 (to r3)      | aa:00:00:00:02:02   | N/A                | 0x2020 |
| r3       | r3-eth1 (to r2)      | aa:00:00:00:03:01   | N/A                | 0x3010 |
| r3       | r3-eth2 (to r4)      | aa:00:00:00:03:02   | N/A                | 0x3020 |
| r4       | r4-eth1 (to h4)      | aa:00:00:00:04:01   | 10.0.2.254/24      | 0x4010 |
| r4       | r4-eth2 (to r5)      | aa:00:00:00:04:02   | N/A                | 0x4020 |
| r4       | r4-eth3 (to r3)      | aa:00:00:00:04:03   | N/A                | 0x4030 |
| r6       | r6-eth1 (to r1)      | aa:00:00:00:06:01   | N/A                | 0x6010 |
| r6       | r6-eth2 (to r5)      | aa:00:00:00:06:02   | N/A                | 0x6020 |
| r5       | r5-eth1 (to r6)      | aa:00:00:00:05:01   | N/A                | 0x5010 |
| r5       | r5-eth2 (to r4)      | aa:00:00:00:05:02   | N/A                | 0x5020 |

### Compilar P4 
```bash
p4c-bm2-ss --std p4-16  p4/l2switch.p4 -o json/l2switch.json
p4c-bm2-ss --std p4-16  p4/l3switchr1.p4 -o json/l3switchr1.json
p4c-bm2-ss --std p4-16  p4/l3switchrmeio.p4 -o json/l3switchrmeio.json
p4c-bm2-ss --std p4-16  p4/l3switchr4.p4 -o json/l3switchr4.json
```

### Executar
Num terminal:
```bash
sudo python3 mininet/topo.py --jsonr1 json/l3switchr1.json --jsonS json/l2switch.json --jsonr4 json/l3switchr4.json --jsonrmeio json/l3switchrmeio.json
```

Noutro terminal:
```bash
simple_switch_CLI --thrift-port 9090 < flows/r1-flows.txt
simple_switch_CLI --thrift-port 9091 < flows/r2-flows.txt
simple_switch_CLI --thrift-port 9092 < flows/r3-flows.txt
simple_switch_CLI --thrift-port 9093 < flows/r4-flows.txt
simple_switch_CLI --thrift-port 9094 < flows/r5-flows.txt
simple_switch_CLI --thrift-port 9095 < flows/r6-flows.txt
simple_switch_CLI --thrift-port 9096 < flows/s1-flows.txt 
```

### Testar
No wireshark é possível visualizar as labels a levarem pop.
```bash
mininet> h3 ping h4 -c 1
mininet> pingall
```

Para visualizar as entradas nas tabelas , as ações e outras componentes a serem executadas, podemos fazer o seguinte comando.
Por exemplo para o router 1  (Port 9090)
```bash
sudo ./tools/nanomsg_client.py --thrift-port 9090
```
