
create_debug_core ila_pci ila
set_property port_width 1 [get_debug_ports ila_pci/clk]
connect_debug_port ila_pci/clk [get_nets -of_object [get_pins pci_mux_i/clk_ibufg_i/O]]
set_property port_width 55 [get_debug_ports ila_pci/probe0]
connect_debug_port ila_pci/probe0 {
	pci_mux_i/PCI_AD
	pci_mux_i/PCI_CBE
	pci_mux_i/PCI_FRAME
	pci_mux_i/PCI_IRDY
	pci_mux_i/PCI_TRDY
	pci_mux_i/PCI_STOP
	pci_mux_i/PCI_DEVSEL
	pci_mux_i/PCI_PAR
	pci_mux_i/PCI_PERR
	pci_mux_i/PCI_SERR
	pci_mux_i/PCI_REQ
	pci_mux_i/PCI_GNT
	pci_mux_i/PCI_INTA
	pci_mux_i/PCI_INTB
	pci_mux_i/PCI_INTC
	pci_mux_i/PCI_INTD
	pci_mux_i/PCI_RST
}

create_debug_core ila_nic ila
set_property port_width 1 [get_debug_ports ila_nic/clk]
connect_debug_port ila_nic/clk [get_nets -of_object [get_pins {nic_wrapper_i/nic_clk_gen_i/mmcm_adv_inst/CLKOUT0}]]
set_property port_width 151 [get_debug_ports ila_nic/probe0]
connect_debug_port ila_nic/probe0 {
    nic_wrapper_i/nic_s_awvalid
    nic_wrapper_i/nic_s_awready
    nic_wrapper_i/nic_s_awaddr
    nic_wrapper_i/nic_s_wvalid
    nic_wrapper_i/nic_s_wready
    nic_wrapper_i/nic_s_wdata
    nic_wrapper_i/nic_s_wstrb
    nic_wrapper_i/nic_s_bvalid
    nic_wrapper_i/nic_s_bready
    nic_wrapper_i/nic_s_bresp
    nic_wrapper_i/nic_s_arvalid
    nic_wrapper_i/nic_s_arready
    nic_wrapper_i/nic_s_araddr
    nic_wrapper_i/nic_s_aruser
    nic_wrapper_i/nic_s_rvalid
    nic_wrapper_i/nic_s_rready
    nic_wrapper_i/nic_s_rdata
    nic_wrapper_i/nic_s_rresp
    nic_wrapper_i/intr_request
}

create_debug_core ila_mpc ila
set_property port_width 1 [get_debug_ports ila_mpc/clk]
connect_debug_port ila_mpc/clk [get_nets -of_object [get_pins {mpc_wrapper_i/can_clk_gen_i/mmcm_adv_inst/CLKOUT0}]]
set_property port_width 151 [get_debug_ports ila_mpc/probe0]
connect_debug_port ila_mpc/probe0 {
    mpc_wrapper_i/mpc_s_awvalid
    mpc_wrapper_i/mpc_s_awready
    mpc_wrapper_i/mpc_s_awaddr
    mpc_wrapper_i/mpc_s_wvalid
    mpc_wrapper_i/mpc_s_wready
    mpc_wrapper_i/mpc_s_wdata
    mpc_wrapper_i/mpc_s_wstrb
    mpc_wrapper_i/mpc_s_bvalid
    mpc_wrapper_i/mpc_s_bready
    mpc_wrapper_i/mpc_s_bresp
    mpc_wrapper_i/mpc_s_arvalid
    mpc_wrapper_i/mpc_s_arready
    mpc_wrapper_i/mpc_s_araddr
    mpc_wrapper_i/mpc_s_aruser
    mpc_wrapper_i/mpc_s_rvalid
    mpc_wrapper_i/mpc_s_rready
    mpc_wrapper_i/mpc_s_rdata
    mpc_wrapper_i/mpc_s_rresp
    mpc_wrapper_i/intr_request
}

create_debug_core ila_mps ila
set_property port_width 1 [get_debug_ports ila_mps/clk]
connect_debug_port ila_mps/clk [get_nets -of_object [get_pins {mps_wrapper_i/uart_clk_gen_i/mmcm_adv_inst/CLKOUT0}]]
set_property port_width 151 [get_debug_ports ila_mps/probe0]
connect_debug_port ila_mps/probe0 {
    mps_wrapper_i/mps_s_awvalid
    mps_wrapper_i/mps_s_awready
    mps_wrapper_i/mps_s_awaddr
    mps_wrapper_i/mps_s_wvalid
    mps_wrapper_i/mps_s_wready
    mps_wrapper_i/mps_s_wdata
    mps_wrapper_i/mps_s_wstrb
    mps_wrapper_i/mps_s_bvalid
    mps_wrapper_i/mps_s_bready
    mps_wrapper_i/mps_s_bresp
    mps_wrapper_i/mps_s_arvalid
    mps_wrapper_i/mps_s_arready
    mps_wrapper_i/mps_s_araddr
    mps_wrapper_i/mps_s_aruser
    mps_wrapper_i/mps_s_rvalid
    mps_wrapper_i/mps_s_rready
    mps_wrapper_i/mps_s_rdata
    mps_wrapper_i/mps_s_rresp
    mps_wrapper_i/intr_request
}
