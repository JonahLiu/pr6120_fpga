create_debug_core u_ila_0 ila

set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]

set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets pci_clk]

set_property port_width 55 [get_debug_ports u_ila_0/probe0]

#create_debug_port u_ila_0 probe
#set_property port_width 4 [get_debug_ports u_ila_0/probe1]
#connect_debug_port u_ila_0/probe1 [get_nets pci_mux_i/CBE[*]]
#
#create_debug_port u_ila_0 probe
#set_property port_width 4 [get_debug_ports u_ila_0/probe1]
#connect_debug_port u_ila_0/probe1 [get_nets pci_mux_i/CBE[*]]
#

connect_debug_port u_ila_0/probe0 {
	pci_mux_i/DBG_AD
	pci_mux_i/DBG_CBE
	pci_mux_i/DBG_FRAME
	pci_mux_i/DBG_IRDY
	pci_mux_i/DBG_TRDY
	pci_mux_i/DBG_STOP
	pci_mux_i/DBG_DEVSEL
	pci_mux_i/DBG_PAR
	pci_mux_i/DBG_PERR
	pci_mux_i/DBG_SERR
	pci_mux_i/DBG_REQ
	pci_mux_i/DBG_GNT
	pci_mux_i/DBG_INTA
	pci_mux_i/DBG_INTB
	pci_mux_i/DBG_INTC
	pci_mux_i/DBG_INTD
	pci_mux_i/DBG_PME
	pci_mux_i/DBG_RST
}

