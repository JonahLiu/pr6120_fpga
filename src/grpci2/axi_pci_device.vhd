library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;
library gaisler;
use gaisler.pci.all;

entity axi_pci_device is
	generic (
	    memtech     : integer := DEFMEMTECH;
		tbmemtech   : integer := DEFMEMTECH;  -- For trace buffers
		oepol       : integer := 0;
		hmindex     : integer := 0;
		hdmindex    : integer := 0;
		hsindex     : integer := 0;
		haddr       : integer := 0;
		hmask       : integer := 0;
		ioaddr      : integer := 0;
		pindex      : integer := 0;
		paddr       : integer := 0;
		pmask       : integer := 16#FFF#;
		irq         : integer := 0;
		irqmode     : integer range 0 to 3 := 0;
		master      : integer range 0 to 1 := 1;
		target      : integer range 0 to 1 := 1;
		dma         : integer range 0 to 1 := 0;
		tracebuffer : integer range 0 to 16384 := 0;
		confspace   : integer range 0 to 1 := 1;
		vendorid    : integer := 16#0000#;
		deviceid    : integer := 16#0000#;
		classcode   : integer := 16#000000#;
		revisionid  : integer := 16#00#;
		cap_pointer : integer := 16#40#;
		ext_cap_pointer : integer := 16#00#;
		iobase      : integer := 16#FFF#;
		extcfg      : integer := 16#0000000#;
		bar0        : integer range 0 to 31 := 28;
		bar1        : integer range 0 to 31 := 0;
		bar2        : integer range 0 to 31 := 0;
		bar3        : integer range 0 to 31 := 0;
		bar4        : integer range 0 to 31 := 0;
		bar5        : integer range 0 to 31 := 0;
		bar0_map    : integer := 16#000000#;
		bar1_map    : integer := 16#000000#;
		bar2_map    : integer := 16#000000#;
		bar3_map    : integer := 16#000000#;
		bar4_map    : integer := 16#000000#;
		bar5_map    : integer := 16#000000#;
		bartype     : integer range 0 to 65535 := 16#0000#;
		barminsize  : integer range 5 to 31 := 12;
		fifo_depth  : integer range 3 to 7 := 3;
		fifo_count  : integer range 2 to 4 := 2;
		conv_endian : integer range 0 to 1 := 1; -- 1: little (PCI) <~> big (AHB), 0: big (PCI) <=> big (AHB)   
		deviceirq   : integer range 0 to 1 := 1;
		deviceirqmask : integer range 0 to 15 := 16#0#;
		hostirq     : integer range 0 to 1 := 1;
		hostirqmask : integer range 0 to 15 := 16#0#;
		nsync       : integer range 0 to 2 := 2; -- with nsync = 0, wrfst needed on syncram...
		hostrst     : integer range 0 to 2 := 0; -- 0: PCI reset is never driven, 1: PCI reset is driven from AHB reset if host, 2: PCI reset is always driven from AHB reset
		bypass      : integer range 0 to 1 := 1;
		ft          : integer range 0 to 1 := 0;
		scantest    : integer range 0 to 1 := 0;
		debug       : integer range 0 to 1 := 0;
		tbapben     : integer range 0 to 1 := 0;
		tbpindex    : integer := 0;
		tbpaddr     : integer := 0;
		tbpmask     : integer := 16#F00#;
		netlist     : integer range 0 to 1 := 0;  -- Use PHY netlist
		
		multifunc   : integer range 0 to 1 := 0; -- Enables Multi-function support
		multiint    : integer range 0 to 1 := 0;
		masters     : integer := 16#FFFF#;
		mf1_deviceid        : integer := 16#0000#;
		mf1_classcode       : integer := 16#000000#;
		mf1_revisionid      : integer := 16#00#;
		mf1_bar0            : integer range 0 to 31 := 0;
		mf1_bar1            : integer range 0 to 31 := 0;
		mf1_bar2            : integer range 0 to 31 := 0;
		mf1_bar3            : integer range 0 to 31 := 0;
		mf1_bar4            : integer range 0 to 31 := 0;
		mf1_bar5            : integer range 0 to 31 := 0;
		mf1_bartype         : integer range 0 to 65535 := 16#0000#;
		mf1_bar0_map        : integer := 16#000000#;
		mf1_bar1_map        : integer := 16#000000#;
		mf1_bar2_map        : integer := 16#000000#;
		mf1_bar3_map        : integer := 16#000000#;
		mf1_bar4_map        : integer := 16#000000#;
		mf1_bar5_map        : integer := 16#000000#;
		mf1_cap_pointer     : integer := 16#40#;
		mf1_ext_cap_pointer : integer := 16#00#;
		mf1_extcfg          : integer := 16#0000000#;
		mf1_masters         : integer := 16#0000#;
		iotest              : integer := 0
	);
	port (
		 pci_rst	: in std_logic;
		 pci_clk	: in std_logic;
		 pci_gnt     : in std_logic;
		 pci_idsel   : in std_logic; 
		 pci_lock_i  : in std_logic;
		 pci_lock_o  : out std_logic;
		 pci_lock_oe : out std_logic;
		 pci_ad_i    : in std_logic_vector(31 downto 0);
		 pci_ad_o    : out std_logic_vector(31 downto 0);
		 pci_ad_oe   : out std_logic;
		 pci_cbe_i   : in std_logic_vector(3 downto 0);
		 pci_cbe_o   : out std_logic_vector(3 downto 0);
		 pci_cbe_oe  : out std_logic;
		 pci_frame_i : in std_logic;
		 pci_frame_o : out std_logic;
		 pci_frame_oe: out std_logic;
		 pci_irdy_i  : in std_logic;
		 pci_irdy_o  : out std_logic;
		 pci_irdy_oe : out std_logic;
		 pci_trdy_i  : in std_logic;
		 pci_trdy_o  : out std_logic;
		 pci_trdy_oe : out std_logic;
		 pci_devsel_i: in std_logic;
		 pci_devsel_o: out std_logic;
		 pci_devsel_oe : out std_logic;
		 pci_stop_i  : in std_logic;
		 pci_stop_o  : out std_logic;
		 pci_stop_oe : out std_logic;
		 pci_perr_i  : in std_logic;
		 pci_perr_o  : out std_logic;
		 pci_perr_oe : out std_logic;
		 pci_par_i   : in std_logic;    
		 pci_par_o   : out std_logic;    
		 pci_par_oe  : out std_logic;    
		 pci_req_o   : out std_logic;
		 pci_req_oe  : out std_logic;
		 pci_serr_i  : in std_logic;
		 pci_serr_o  : out std_logic;
		 pci_serr_oe : out std_logic;

		axi_aclk 		: in  std_logic;
		axi_aresetn	    : in  std_logic;

		m_axi_araddr   : out std_logic_vector ( 31 downto 0 );
		m_axi_arburst  : out std_logic_vector ( 1 downto 0 );
		m_axi_arcache  : out std_logic_vector ( 3 downto 0 );
		m_axi_arid     : out std_logic_vector ( 3 downto 0 );
		m_axi_arlen    : out std_logic_vector ( 7 downto 0 );
		m_axi_arlock   : out std_logic_vector (1 downto 0);
		m_axi_arprot   : out std_logic_vector ( 2 downto 0 );
		m_axi_arqos    : out std_logic_vector ( 3 downto 0 );
		m_axi_arready  : in  std_logic;
		m_axi_arsize   : out std_logic_vector ( 2 downto 0 );
		m_axi_arvalid  : out std_logic;
		m_axi_awaddr   : out std_logic_vector ( 31 downto 0 );
		m_axi_awburst  : out std_logic_vector ( 1 downto 0 );
		m_axi_awcache  : out std_logic_vector ( 3 downto 0 );
		m_axi_awid     : out std_logic_vector ( 3 downto 0 );
		m_axi_awlen    : out std_logic_vector ( 7 downto 0 );
		m_axi_awlock   : out std_logic_vector (1 downto 0);
		m_axi_awprot   : out std_logic_vector ( 2 downto 0 );
		m_axi_awqos    : out std_logic_vector ( 3 downto 0 );
		m_axi_awready  : in  std_logic;
		m_axi_awsize   : out std_logic_vector ( 2 downto 0 );
		m_axi_awvalid  : out std_logic;
		m_axi_bid      : in  std_logic_vector ( 3 downto 0 );
		m_axi_bready   : out std_logic;
		m_axi_bresp    : in  std_logic_vector ( 1 downto 0 );
		m_axi_bvalid   : in  std_logic;
		m_axi_rdata    : in  std_logic_vector ( 31 downto 0 );
		m_axi_rid      : in  std_logic_vector ( 3 downto 0 );
		m_axi_rlast    : in  std_logic;
		m_axi_rready   : out std_logic;
		m_axi_rresp    : in  std_logic_vector ( 1 downto 0 );
		m_axi_rvalid   : in  std_logic;
		m_axi_wdata    : out std_logic_vector ( 31 downto 0 );
		m_axi_wid      : out std_logic_vector ( 3 downto 0 );
		m_axi_wlast    : out std_logic;
		m_axi_wready   : in  std_logic;
		m_axi_wstrb    : out std_logic_vector ( 3 downto 0 );
		m_axi_wvalid   : out std_logic;

		s_axi_araddr    : in  std_logic_vector ( 31 downto 0 );
		s_axi_arburst   : in  std_logic_vector ( 1 downto 0 );
		s_axi_arcache   : in  std_logic_vector ( 3 downto 0 );
		s_axi_arid      : in  std_logic_vector ( 3 downto 0 );
		s_axi_arlen     : in  std_logic_vector ( 7 downto 0 );
		s_axi_arlock    : in  std_logic_vector (1 downto 0);
		s_axi_arprot    : in  std_logic_vector ( 2 downto 0 );
		s_axi_arqos     : in  std_logic_vector ( 3 downto 0 );
		s_axi_arready   : out std_logic;
		s_axi_arsize    : in  std_logic_vector ( 2 downto 0 );
		s_axi_arvalid   : in  std_logic;
		s_axi_awaddr    : in  std_logic_vector ( 31 downto 0 );
		s_axi_awburst   : in  std_logic_vector ( 1 downto 0 );
		s_axi_awcache   : in  std_logic_vector ( 3 downto 0 );
		s_axi_awid      : in  std_logic_vector ( 3 downto 0 );
		s_axi_awlen     : in  std_logic_vector ( 7 downto 0 );
		s_axi_awlock    : in  std_logic_vector (1 downto 0);
		s_axi_awprot    : in  std_logic_vector ( 2 downto 0 );
		s_axi_awqos     : in  std_logic_vector ( 3 downto 0 );
		s_axi_awready   : out std_logic;
		s_axi_awsize    : in  std_logic_vector ( 2 downto 0 );
		s_axi_awvalid   : in  std_logic;
		s_axi_bid       : out std_logic_vector ( 3 downto 0 );
		s_axi_bready    : in  std_logic;
		s_axi_bresp     : out std_logic_vector ( 1 downto 0 );
		s_axi_bvalid    : out std_logic;
		s_axi_rdata     : out std_logic_vector ( 31 downto 0 );
		s_axi_rid       : out std_logic_vector ( 3 downto 0 );
		s_axi_rlast     : out std_logic;
		s_axi_rready    : in  std_logic;
		s_axi_rresp     : out std_logic_vector ( 1 downto 0 );
		s_axi_rvalid    : out std_logic;
		s_axi_wdata     : in  std_logic_vector ( 31 downto 0 );
		s_axi_wid       : in  std_logic_vector ( 3 downto 0 );
		s_axi_wlast     : in  std_logic;
		s_axi_wready    : out std_logic;
		s_axi_wstrb     : in  std_logic_vector ( 3 downto 0 );
		s_axi_wvalid    : in  std_logic
	);
end;

architecture rtl of axi_pci_device is

	signal rstn, clkm, pciclk : std_logic;
	signal pci_dirq : std_logic_vector(3 downto 0);

	signal pcii : pci_in_type;
	signal pcio : pci_out_type;
	signal apbi  : apb_slv_in_type;
	signal apbo  : apb_slv_out_type;
	signal ahbsi : ahb_slv_in_type;
	signal ahbso : ahb_slv_out_type;
	signal ahbmi : ahb_mst_in_type;
	signal ahbmo : ahb_mst_out_type;
	signal ahbdmi : ahb_mst_in_type;

	grpci2_0 : grpci2 
	generic map (
	    memtech      => 	    memtech     ,
		tbmemtech    => 		tbmemtech   ,
		oepol        => 		oepol       ,
		hmindex      => 		hmindex     ,
		hdmindex     => 		hdmindex    ,
		hsindex      => 		hsindex     ,
		haddr        => 		haddr       ,
		hmask        => 		hmask       ,
		ioaddr       => 		ioaddr      ,
		pindex       => 		pindex      ,
		paddr        => 		paddr       ,
		pmask        => 		pmask       ,
		irq          => 		irq         ,
		irqmode      => 		irqmode     ,
		master       => 		master      ,
		target       => 		target      ,
		dma          => 		dma         ,
		tracebuffer  => 		tracebuffer ,
		confspace    => 		confspace   ,
		vendorid     => 		vendorid    ,
		deviceid     => 		deviceid    ,
		classcode    => 		classcode   ,
		revisionid   => 		revisionid  ,
		cap_pointer  => 		cap_pointer ,
		ext_cap_pointer  => 		ext_cap_pointer ,
		iobase       => 		iobase      ,
		extcfg       => 		extcfg      ,
		bar0         => 		bar0        ,
		bar1         => 		bar1        ,
		bar2         => 		bar2        ,
		bar3         => 		bar3        ,
		bar4         => 		bar4        ,
		bar5         => 		bar5        ,
		bar0_map     => 		bar0_map    ,
		bar1_map     => 		bar1_map    ,
		bar2_map     => 		bar2_map    ,
		bar3_map     => 		bar3_map    ,
		bar4_map     => 		bar4_map    ,
		bar5_map     => 		bar5_map    ,
		bartype      => 		bartype     ,
		barminsize   => 		barminsize  ,
		fifo_depth   => 		fifo_depth  ,
		fifo_count   => 		fifo_count  ,
		conv_endian  => 		conv_endian ,
		deviceirq    => 		deviceirq   ,
		deviceirqmask  => 		deviceirqmask ,
		hostirq      => 		hostirq     ,
		hostirqmask  => 		hostirqmask ,
		nsync        => 		nsync       ,
		hostrst      => 		hostrst     ,
		bypass       => 		bypass      ,
		ft           => 		ft          ,
		scantest     => 		scantest    ,
		debug        => 		debug       ,
		tbapben      => 		tbapben     ,
		tbpindex     => 		tbpindex    ,
		tbpaddr      => 		tbpaddr     ,
		tbpmask      => 		tbpmask     ,
		netlist      => 		netlist     ,
		
		multifunc    => 		multifunc   ,
		multiint     => 		multiint    ,
		masters      => 		masters     ,
		mf1_deviceid         => 		mf1_deviceid        ,
		mf1_classcode        => 		mf1_classcode       ,
		mf1_revisionid       => 		mf1_revisionid      ,
		mf1_bar0             => 		mf1_bar0            ,
		mf1_bar1             => 		mf1_bar1            ,
		mf1_bar2             => 		mf1_bar2            ,
		mf1_bar3             => 		mf1_bar3            ,
		mf1_bar4             => 		mf1_bar4            ,
		mf1_bar5             => 		mf1_bar5            ,
		mf1_bartype          => 		mf1_bartype         ,
		mf1_bar0_map         => 		mf1_bar0_map        ,
		mf1_bar1_map         => 		mf1_bar1_map        ,
		mf1_bar2_map         => 		mf1_bar2_map        ,
		mf1_bar3_map         => 		mf1_bar3_map        ,
		mf1_bar4_map         => 		mf1_bar4_map        ,
		mf1_bar5_map         => 		mf1_bar5_map        ,
		mf1_cap_pointer      => 		mf1_cap_pointer     ,
		mf1_ext_cap_pointer  => 		mf1_ext_cap_pointer ,
		mf1_extcfg           => 		mf1_extcfg          ,
		mf1_masters          => 		mf1_masters         ,
		iotest               => 		iotest             
	)
	port map (
		rst        =>    rstn, 
		clk        =>    clkm, 
		pciclk     =>    pciclk, 
		dirq       =>    pci_dirq, 
		pcii       =>    pcii, 
		pcio       =>    pcio, 
		apbi       =>    apbi, 
		apbo       =>    apbo, 
		ahbsi      =>    ahbsi, 
		ahbso      =>    ahbso, 
		ahbmi      =>    ahbmi,
		ahbmo      =>    ahbmo, 
		ahbdmi     =>    ahbdmi, 
	    ahbdmo     =>    open,
	    ptarst     =>    open, 
		tbapbi     =>    open, 
		tbapbo     =>    open, 
		debugo     =>    open
	);

	axi2ahb_0 : axi2ahb
	generic map (
		hindex     =>    0,
	    idsize     =>    4,
	    lensize    =>    8,
	    fifo_depth =>    256
	)
	port map(
	    ahb_clk    =>    clkm,
		axi_clk    =>    clkm,
		resetn     =>    rstn,
		ahbi       =>    ahbso,
		ahbo       =>    ahbsi,
		s_axi_araddr    => 		s_axi_araddr   ,
		s_axi_arburst   => 		s_axi_arburst  ,
		s_axi_arcache   => 		s_axi_arcache  ,
		s_axi_arid      => 		s_axi_arid     ,
		s_axi_arlen     => 		s_axi_arlen    ,
		s_axi_arlock    => 		s_axi_arlock   ,
		s_axi_arprot    => 		s_axi_arprot   ,
		s_axi_arqos     => 		s_axi_arqos    ,
		s_axi_arready   => 		s_axi_arready  ,
		s_axi_arsize    => 		s_axi_arsize   ,
		s_axi_arvalid   => 		s_axi_arvalid  ,
		s_axi_awaddr    => 		s_axi_awaddr   ,
		s_axi_awburst   => 		s_axi_awburst  ,
		s_axi_awcache   => 		s_axi_awcache  ,
		s_axi_awid      => 		s_axi_awid     ,
		s_axi_awlen     => 		s_axi_awlen    ,
		s_axi_awlock    => 		s_axi_awlock   ,
		s_axi_awprot    => 		s_axi_awprot   ,
		s_axi_awqos     => 		s_axi_awqos    ,
		s_axi_awready   => 		s_axi_awready  ,
		s_axi_awsize    => 		s_axi_awsize   ,
		s_axi_awvalid   => 		s_axi_awvalid  ,
		s_axi_bid       => 		s_axi_bid      ,
		s_axi_bready    => 		s_axi_bready   ,
		s_axi_bresp     => 		s_axi_bresp    ,
		s_axi_bvalid    => 		s_axi_bvalid   ,
		s_axi_rdata     => 		s_axi_rdata    ,
		s_axi_rid       => 		s_axi_rid      ,
		s_axi_rlast     => 		s_axi_rlast    ,
		s_axi_rready    => 		s_axi_rready   ,
		s_axi_rresp     => 		s_axi_rresp    ,
		s_axi_rvalid    => 		s_axi_rvalid   ,
		s_axi_wdata     => 		s_axi_wdata    ,
		s_axi_wid       => 		s_axi_wid      ,
		s_axi_wlast     => 		s_axi_wlast    ,
		s_axi_wready    => 		s_axi_wready   ,
		s_axi_wstrb     => 		s_axi_wstrb    ,
		s_axi_wvalid    => 		s_axi_wvalid   
	);

	ahb2axi_0 : ahb2axi
	generic map (
		hindex		=>	0;
		haddr		=>	0;
		hmask		=>	16#f00#;
		pindex		=>	0;
		paddr		=>	0;
		pmask		=>	16#fff#;
		cidsz		=>	4;
		clensz		=>	8
	)
	port map (
		rstn		=>	rstn,
		clk			=>	clkm,
		ahbsi		=>	ahbmo,
		ahbso		=>	ahbmi,
		apbi		=>	open,
		apbo		=>	open,
		m_axi_araddr    => 		m_axi_araddr   ,
		m_axi_arburst   => 		m_axi_arburst  ,
		m_axi_arcache   => 		m_axi_arcache  ,
		m_axi_arid      => 		m_axi_arid     ,
		m_axi_arlen     => 		m_axi_arlen    ,
		m_axi_arlock    => 		m_axi_arlock   ,
		m_axi_arprot    => 		m_axi_arprot   ,
		m_axi_arqos     => 		m_axi_arqos    ,
		m_axi_arready   => 		m_axi_arready  ,
		m_axi_arsize    => 		m_axi_arsize   ,
		m_axi_arvalid   => 		m_axi_arvalid  ,
		m_axi_awaddr    => 		m_axi_awaddr   ,
		m_axi_awburst   => 		m_axi_awburst  ,
		m_axi_awcache   => 		m_axi_awcache  ,
		m_axi_awid      => 		m_axi_awid     ,
		m_axi_awlen     => 		m_axi_awlen    ,
		m_axi_awlock    => 		m_axi_awlock   ,
		m_axi_awprot    => 		m_axi_awprot   ,
		m_axi_awqos     => 		m_axi_awqos    ,
		m_axi_awready   => 		m_axi_awready  ,
		m_axi_awsize    => 		m_axi_awsize   ,
		m_axi_awvalid   => 		m_axi_awvalid  ,
		m_axi_bid       => 		m_axi_bid      ,
		m_axi_bready    => 		m_axi_bready   ,
		m_axi_bresp     => 		m_axi_bresp    ,
		m_axi_bvalid    => 		m_axi_bvalid   ,
		m_axi_rdata     => 		m_axi_rdata    ,
		m_axi_rid       => 		m_axi_rid      ,
		m_axi_rlast     => 		m_axi_rlast    ,
		m_axi_rready    => 		m_axi_rready   ,
		m_axi_rresp     => 		m_axi_rresp    ,
		m_axi_rvalid    => 		m_axi_rvalid   ,
		m_axi_wdata     => 		m_axi_wdata    ,
		m_axi_wid       => 		m_axi_wid      ,
		m_axi_wlast     => 		m_axi_wlast    ,
		m_axi_wready    => 		m_axi_wready   ,
		m_axi_wstrb     => 		m_axi_wstrb    ,
		m_axi_wvalid    => 		m_axi_wvalid   
	);

end;
