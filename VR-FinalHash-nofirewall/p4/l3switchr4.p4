# -*- P4_16 -*-
#include <core.p4>
#include <v1model.p4>

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_MSLP = 0x88B5;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header mslp_t {
    //bit<8>   labelCount;
    bit<16> label;
    //bit<32>  labels;
    //bit<8>  ttl;
}

header nlabelsh_t {
	bit<8> nlabels;
}

struct metadata {
    macAddr_t nextHopMac;
    bit<1> tunnelSelect;
    //bit<1> sentido;
    bit<2> nhost;
}

struct headers {
    ethernet_t ethernet;
    ipv4_t ipv4;
    nlabelsh_t nlabelsh;
    mslp_t[3] mslp;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_MSLP: parse_mslp;
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_mslp {
	packet.extract(hdr.nlabelsh);
        packet.extract(hdr.mslp[0]);
	packet.extract(hdr.mslp[1]);
	packet.extract(hdr.mslp[2]);
        transition accept;
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }

}

/*************************************************************************
*********************** I N G R E S S  ***********************************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action drop() {
        mark_to_drop(standard_metadata);
    }
    
    action mslp_forward(bit<9> egressPort, macAddr_t nextHopMac) {
        standard_metadata.egress_spec = egressPort;
	meta.nextHopMac = nextHopMac;
        //hdr.mslp.ttl = hdr.mslp.ttl - 1;
    }

    action definetunnel(bit<1> tunnelSelect, bit<2> nhost, bit<9> egressPort, macAddr_t nextHopMac) {
	    hdr.mslp[0].setValid();
	    hdr.mslp[1].setValid();
	    hdr.mslp[2].setValid();
	    hdr.nlabelsh.setValid();
	    hdr.nlabelsh.nlabels = 4;
            if (tunnelSelect == 0) {
	       hdr.mslp[0].label = 0x3010;
               hdr.mslp[1].label = 0x2010;
            }if (tunnelSelect == 1) {
	       hdr.mslp[0].label = 0x5010;
               hdr.mslp[1].label = 0x6010;
            }if (nhost == 1){
	       hdr.mslp[2].label = 0x0010;
	    }if (nhost == 2){
	       hdr.mslp[2].label = 0x0020;
	    }if (nhost == 3){
	       hdr.mslp[2].label = 0x0030;
	    }
            hdr.ethernet.etherType = TYPE_MSLP;
	    standard_metadata.egress_spec = egressPort;
	    meta.nextHopMac = nextHopMac;
            //hdr.mslp.ttl = hdr.mslp.ttl - 1;
    }

    action rewriteMacs(macAddr_t srcMac) {
        hdr.ethernet.srcAddr = srcMac;
        hdr.ethernet.dstAddr = meta.nextHopMac;
    }

    table internalMacLookup{
        key = {standard_metadata.egress_spec: exact;}
        actions = { 
            rewriteMacs;
            drop;
        }
        size = 256;
        default_action = drop;
    }

    table tunnelSelection {
        key = { hdr.ipv4.dstAddr: lpm; }
        actions = { definetunnel; drop; }
        size = 256;
        default_action = drop;
    }
    
    table labelselect{
        key = { hdr.mslp[0].label: exact; }
	actions = { mslp_forward; drop; }
        size = 256;
        default_action = drop;
    }

    apply {
        if (hdr.mslp[0].isValid()) {
		labelselect.apply();
		internalMacLookup.apply();
	}else{
        if (hdr.ipv4.isValid()) {
	      tunnelSelection.apply();
              internalMacLookup.apply();
	 }
        }// else {
        //    drop();
        //}
    }
}

/*************************************************************************
*********************** E G R E S S  ***********************************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    action pop_mslp() {
    if (hdr.nlabelsh.nlabels > 1) {
        hdr.mslp[0].label = hdr.mslp[1].label;
	hdr.mslp[1].label = hdr.mslp[2].label;
        hdr.ethernet.etherType = TYPE_MSLP;
    }
}

    apply {
	if (hdr.nlabelsh.nlabels == 1) {
		hdr.nlabelsh.setInvalid();
		hdr.mslp[0].setInvalid();
		hdr.ethernet.etherType = TYPE_IPV4;
	}else{
        if (hdr.mslp[0].isValid()) {
	    if (hdr.nlabelsh.nlabels < 4 ){
            	pop_mslp();
		}
	    hdr.nlabelsh.nlabels = hdr.nlabelsh.nlabels - 1;
         }
        }
    }
}

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply { /* do nothing */  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
    /* The IPv4 Header was changed, it needs new checksum*/
    apply { 
        update_checksum(
	        hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	          hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16); }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
	packet.emit(hdr.nlabelsh);
	packet.emit(hdr.mslp[0]);
	packet.emit(hdr.mslp[1]);
	packet.emit(hdr.mslp[2]);
        packet.emit(hdr.ipv4);
        
    }
}
/*************************************************************************
*********************** S W I T C H  ***********************************
*************************************************************************/

V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;
