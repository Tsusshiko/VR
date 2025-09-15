#!/usr/bin/env python3
# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
############################################################################
# RDS-TUT jfpereira - Read all comments from this point on !!!!!!
############################################################################
# This code is given in 
# https://github.com/p4lang/behavioral-model/blob/main/mininet/1sw_demo.py
# with minor adjustments to satisfy the requirements of RDS-TP3. 
# This script works for a topology with one P4Switch connected to 253 P4Hosts. 
# In this TP3, we only need 1 P4Switch and 2 P4Hosts.
# The P4Hosts are regular mininet Hosts with IPv6 suppression.
# The P4Switch it's a very different piece of software from other switches 
# in mininet like OVSSwitch, OVSKernelSwitch, UserSwitch, etc.
# You can see the definition of P4Host and P4Switch in p4_mininet.py
###########################################################################

from mininet.net import Mininet
from mininet.topo import Topo
from mininet.log import setLogLevel, info
from mininet.cli import CLI

from p4_mininet import P4Switch, P4Host

import argparse
from time import sleep

# If you look at this parser, it can identify 4 arguments
# --behavioral-exe, with the default value 'simple_switch'
## this indicates that the arch of our software switch is the 'simple_switch'
## and any p4 program made for this arch needs to be compiled against de 'v1model.p4'
# --thrift-port, with the default value of 9090, which is the default server port of
## a thrift server - the P4Switch instantiates a Thrift server that allows us
## to communicate our P4Switch (software switch) at runtime
# --num-hosts, with default value 2 indicates the number of hosts...
# --json, is the path to JSON config file - the output of your p4 program compilation
## this is the only argument that you will need to pass in orther to run the script
parser = argparse.ArgumentParser(description='Mininet demo')
parser.add_argument('--behavioral-exe', help='Path to behavioral executable',
                    type=str, action="store", default='simple_switch')
parser.add_argument('--thrift-port', help='Thrift server port for table updates',
                    type=int, action="store", default=9090)
parser.add_argument('--jsonr1', help='Path to JSON config file',
                    type=str, action="store", required=True)
parser.add_argument('--jsonr4', help='Path to JSON config file',
                    type=str, action="store", required=True)
parser.add_argument('--jsonrmeio', help='Path to JSON config file',
                    type=str, action="store", required=True)
parser.add_argument('--jsonS', help='Path to JSON config file',
                    type=str, action="store", required=True)                    
args = parser.parse_args()

class FishTopo(Topo):
    def __init__(self, sw_path, json_path_r1, json_path_r4, json_path_rmeio, json_path_S, thrift_port, **opts):
        # Initialize topology and default options
        Topo.__init__(self, **opts)
        # adding a P4Switch
        r1 = self.addSwitch('r1',
                                sw_path = sw_path,
                                json_path = json_path_r1,
                                thrift_port = thrift_port)
        r2 = self.addSwitch('r2',
                                sw_path = sw_path,
                                json_path = json_path_rmeio,
                                thrift_port = thrift_port+1)
        r3 = self.addSwitch('r3',
                                sw_path = sw_path,
                                json_path = json_path_rmeio,
                                thrift_port = thrift_port+2)
        r4 = self.addSwitch('r4',
                                sw_path = sw_path,
                                json_path = json_path_r4,
                                thrift_port = thrift_port+3)
        r5 = self.addSwitch('r5',
                                sw_path = sw_path,
                                json_path = json_path_rmeio,
                                thrift_port = thrift_port+4)
        r6 = self.addSwitch('r6',
                                sw_path = sw_path,
                                json_path = json_path_rmeio,
                                thrift_port = thrift_port+5)
        s1 = self.addSwitch('s1',
                                sw_path = sw_path,
                                json_path = json_path_S,
                                thrift_port = thrift_port+6)
        
        h1 = self.addHost('h1', ip="10.0.1.1/24", mac="aa:00:00:00:00:01")
        h2 = self.addHost('h2', ip="10.0.1.2/24", mac="aa:00:00:00:00:02")
        h3 = self.addHost('h3', ip="10.0.1.3/24", mac="aa:00:00:00:00:03") 
        h4 = self.addHost('h4', ip="10.0.2.1/24", mac="aa:00:00:00:00:04")
        

        #links hosts to S1
        self.addLink(h1, s1, port2=1, addr2="cc:00:00:00:01:01")
        self.addLink(h2, s1, port2=2, addr2="cc:00:00:00:01:02")
        self.addLink(h3, s1, port2=3, addr2="cc:00:00:00:01:03")
        #s1-r1
        # routers
        self.addLink(s1, r1, port1=4, port2=1, addr1="cc:00:00:00:01:04", addr2="aa:00:00:00:01:01")
        #r1-r2
        self.addLink(r1, r2, port1=2, port2=1, addr1="aa:00:00:00:01:02", addr2="aa:00:00:00:02:01")
        #r1-r6
        self.addLink(r1, r6, port1=3, port2=1, addr1="aa:00:00:00:01:03", addr2="aa:00:00:00:06:01")
        # r2 -r3
        self.addLink(r2, r3, port1=2, port2=1, addr1="aa:00:00:00:02:02", addr2="aa:00:00:00:03:01")
        # r3 - r4
        self.addLink(r3, r4, port1=2, port2=3, addr1="aa:00:00:00:03:02", addr2="aa:00:00:00:04:03")
        # r6-r5
        self.addLink(r6, r5, port1=2, port2=1, addr1="aa:00:00:00:06:02", addr2="aa:00:00:00:05:01")
        # r5-r4
        self.addLink(r5, r4, port1=2, port2=2, addr1="aa:00:00:00:05:02", addr2="aa:00:00:00:04:02")
        # host
        self.addLink(h4, r4, port2=1, addr2="aa:00:00:00:04:01")
        
def main():

    topo = FishTopo(args.behavioral_exe,
                            args.jsonr1,
                            args.jsonr4,
                            args.jsonrmeio,
                            args.jsonS,
                            args.thrift_port)

    # the host class is the P4Host
    # the switch class is the P4Switch
    net = Mininet(topo = topo,
                  host = P4Host,
                  switch = P4Switch,
                  controller = None)

    # Here, the mininet will use the constructor (__init__()) of the P4Switch class, 
    # with the arguments passed to the SingleSwitchTopo class in order to create 
    # our software switch.
    net.start()


    sleep(1)  # time for the host and switch confs to take effect
    for n in range(4):
        h = net.get('h%d' % (n + 1))
        h.describe()
        if n <= 2:
            h.setARP("10.0.1.254", "aa:00:00:00:01:01")
          #  h.setARP("10.0.2.254", "aa:00:00:00:01:01")
            h.setDefaultRoute("dev eth0 via 10.0.1.254")
        else:
            h.setARP("10.0.2.254", "aa:00:00:00:04:01")
            h.setDefaultRoute("dev eth0 via 10.0.2.254")

    print("Ready !")

    CLI( net )
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    main()
