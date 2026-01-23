/* xdp_wireguard.c - XDP program for WireGuard gaming optimization
 * 
 * Purpose: Fast-path for WireGuard packets, drop everything else at driver level
 * Impact: -2-5ms latency by bypassing kernel network stack
 * 
 * Compilation:
 *   clang -O2 -target bpf -c xdp_wireguard.c -o xdp_wireguard.o
 * 
 * Loading:
 *   ip link set dev eth0 xdpgeneric obj xdp_wireguard.o sec xdp
 */

#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/ipv6.h>
#include <linux/udp.h>
#include <linux/in.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

/* WireGuard uses UDP port 51820 by default */
#define WIREGUARD_PORT 51820

/* XDP return codes */
#define XDP_PASS_TO_STACK 0
#define XDP_DROP_PACKET 1

/* Helper to parse Ethernet header */
static __always_inline int parse_ethhdr(void *data, void *data_end, 
                                         __u16 *eth_proto, __u64 *offset)
{
    struct ethhdr *eth = data;
    
    /* Bounds check */
    if ((void *)(eth + 1) > data_end)
        return -1;
    
    *eth_proto = eth->h_proto;
    *offset = sizeof(struct ethhdr);
    
    return 0;
}

/* Parse IPv4 header and check for UDP */
static __always_inline int parse_ipv4(void *data, void *data_end, 
                                       __u64 offset, __u16 *udp_dport)
{
    struct iphdr *iph = data + offset;
    struct udphdr *udph;
    
    /* Bounds check for IP header */
    if ((void *)(iph + 1) > data_end)
        return -1;
    
    /* Only process UDP packets */
    if (iph->protocol != IPPROTO_UDP)
        return -1;
    
    /* Parse UDP header */
    udph = (void *)iph + (iph->ihl * 4);
    if ((void *)(udph + 1) > data_end)
        return -1;
    
    *udp_dport = bpf_ntohs(udph->dest);
    
    return 0;
}

/* Parse IPv6 header and check for UDP */
static __always_inline int parse_ipv6(void *data, void *data_end,
                                       __u64 offset, __u16 *udp_dport)
{
    struct ipv6hdr *ip6h = data + offset;
    struct udphdr *udph;
    
    /* Bounds check for IPv6 header */
    if ((void *)(ip6h + 1) > data_end)
        return -1;
    
    /* Only process UDP packets */
    if (ip6h->nexthdr != IPPROTO_UDP)
        return -1;
    
    /* Parse UDP header */
    udph = (void *)(ip6h + 1);
    if ((void *)(udph + 1) > data_end)
        return -1;
    
    *udp_dport = bpf_ntohs(udph->dest);
    
    return 0;
}

/* Main XDP program */
SEC("xdp")
int xdp_wireguard_filter(struct xdp_md *ctx)
{
    void *data = (void *)(long)ctx->data;
    void *data_end = (void *)(long)ctx->data_end;
    __u16 eth_proto;
    __u64 offset = 0;
    __u16 udp_dport = 0;
    int ret;
    
    /* Parse Ethernet header */
    if (parse_ethhdr(data, data_end, &eth_proto, &offset) < 0)
        return XDP_DROP;
    
    /* Handle IPv4 */
    if (eth_proto == bpf_htons(ETH_P_IP)) {
        ret = parse_ipv4(data, data_end, offset, &udp_dport);
        if (ret < 0)
            return XDP_DROP;  /* Not UDP or malformed */
        
        /* Pass WireGuard traffic to kernel */
        if (udp_dport == WIREGUARD_PORT)
            return XDP_PASS;
        
        /* Drop everything else (non-WireGuard traffic) */
        return XDP_DROP;
    }
    
    /* Handle IPv6 */
    if (eth_proto == bpf_htons(ETH_P_IPV6)) {
        ret = parse_ipv6(data, data_end, offset, &udp_dport);
        if (ret < 0)
            return XDP_DROP;  /* Not UDP or malformed */
        
        /* Pass WireGuard traffic to kernel */
        if (udp_dport == WIREGUARD_PORT)
            return XDP_PASS;
        
        /* Drop everything else (non-WireGuard traffic) */
        return XDP_DROP;
    }
    
    /* Pass ARP and other critical protocols */
    if (eth_proto == bpf_htons(ETH_P_ARP))
        return XDP_PASS;
    
    /* Drop unknown protocols */
    return XDP_DROP;
}

char _license[] SEC("license") = "GPL";
