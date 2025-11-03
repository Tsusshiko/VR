Commandos teorica (incompleto)

Criar Namespace

ip netns add H1
ip netns add H2
ip netns add H3
ip netns add H4


Criar bridges

ovs-vsctl add-br SW1
ovs-vsctl add-br SW2


Adicionar ligações

H1:
ip link add h1-eth0 type veth peer name sw1-eth0
ip link set h1-eth0 netns H1
ovs-vsctl add-port SW1 sw1-eth0

H2:
ip link add h2-eth0 type veth peer name sw1-eth1
ip link set h2-eth0 netns H2
ovs-vsctl add-port SW1 sw1-eth1

H3:
ip link add h3-eth0 type veth peer name sw2-eth0
ip link set h3-eth0 netns H3
ovs-vsctl add-port SW2 sw2-eth0

H4:
ip link add h4-eth0 type veth peer name sw2-eth1
ip link set h4-eth0 netns H4
ovs-vsctl add-port SW2 sw2-eth1
