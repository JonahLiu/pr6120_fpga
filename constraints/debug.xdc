
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

