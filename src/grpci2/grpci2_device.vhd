library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;
library gaisler;
use gaisler.pci.all;
library grlib;
use grlib.amba.all;

entity grpci2_device is
	generic (
	    memtech     : integer := DEFMEMTECH;
		tbmemtech   : integer := DEFMEMTECH;  -- For trace buffers
		oepol       : integer range 0 to 1 := 1;
		hmindex     : integer range 0 to 15 := 0;           -- AHB Master ID
		hdmindex    : integer range 0 to 15 := 0;           -- DMA AHB Master ID
		hsindex     : integer range 0 to 15 := 0;           -- AHB Slave ID
		haddr       : integer range 0 to 4095 := 0;         -- AHB MEM BAR Address[31:19] base
		hmask       : integer range 0 to 4095 := 0;         -- AHB BAR Address[31:19] mask
		ioaddr      : integer range 0 to 4095 := 16#FFF#;         -- AHB IO BAR Address
		pindex      : integer := 0;           -- APB slave ID
		paddr       : integer := 0;           -- APB slave address base
		pmask       : integer := 0;           -- APB slave address mask
		irq         : integer := 0;           -- AHB interrupt line
		irqmode     : integer range 0 to 3 := 0;
		master      : integer range 0 to 1 := 1;  -- Enable master
		target      : integer range 0 to 1 := 1;  -- Enable target
		dma         : integer range 0 to 1 := 0;  -- Enable DMA
		tracebuffer : integer range 0 to 16384 := 0;
		confspace   : integer range 0 to 1 := 1;
		vendorid    : integer := 16#10EE#;
		deviceid    : integer := 16#0701#;
		classcode   : integer := 16#000000#;
		revisionid  : integer := 16#00#;
		cap_pointer : integer := 16#40#;
		ext_cap_pointer : integer := 16#00#;
		iobase      : integer := 16#FFF#;
		extcfg      : integer := 16#FFFE000#;
		bar0        : integer range 0 to 31 := 16; -- Size in address bits
		bar1        : integer range 0 to 31 := 0;
		bar2        : integer range 0 to 31 := 0;
		bar3        : integer range 0 to 31 := 0;
		bar4        : integer range 0 to 31 := 0;
		bar5        : integer range 0 to 31 := 0;
		bar0_map    : integer := 16#000000#; -- AHB address mapping
		bar1_map    : integer := 16#000000#;
		bar2_map    : integer := 16#000000#;
		bar3_map    : integer := 16#000000#;
		bar4_map    : integer := 16#000000#;
		bar5_map    : integer := 16#000000#;
		bartype     : integer range 0 to 65535 := 16#0000#; -- [5:0]: Prefetch, [13:8]: Type
		barminsize  : integer range 5 to 31 := 9; -- barminsize >= 2+fifo_depth
		fifo_depth  : integer range 3 to 7 := 7;
		fifo_count  : integer range 2 to 4 := 2;
		conv_endian : integer range 0 to 1 := 1; -- 1: little (PCI) <~> big (AHB), 0: big (PCI) <=> big (AHB)   
		deviceirq   : integer range 0 to 1 := 1; -- Enable AHB to PCI interrupt relay
		deviceirqmask : integer range 0 to 15 := 16#F#; -- dirq mask
		hostirq     : integer range 0 to 1 := 0; -- Enable PCI to AHB interrupt relay
		hostirqmask : integer range 0 to 15 := 16#0#;   -- host interrupt mask
		nsync       : integer range 0 to 2 := 2; -- with nsync = 0, wrfst needed on syncram...
		hostrst     : integer range 0 to 2 := 0; -- 0: PCI reset is never driven, 1: PCI reset is driven from AHB reset if host, 2: PCI reset is always driven from AHB reset
		bypass      : integer range 0 to 1 := 1;
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
		mf1_deviceid        : integer := 16#0701#;
		mf1_classcode       : integer := 16#000000#;
		mf1_revisionid      : integer := 16#00#;
		mf1_bar0            : integer range 0 to 31 := 16;
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
		mf1_extcfg          : integer := 16#FFFF000#;
		mf1_masters         : integer := 16#0000#;
		iotest              : integer := 0
	);
	port (
		pci_rst	    : in std_logic;
		pci_clk	    : in std_logic;
		pci_gnt     : in std_logic;
		pci_idsel   : in std_logic; 
		pci_lock_i  : in std_logic;
		pci_lock_o  : out std_logic;
		pci_lock_oe : out std_logic;
		pci_ad_i    : in std_logic_vector(31 downto 0);
		pci_ad_o    : out std_logic_vector(31 downto 0);
		pci_ad_oe   : out std_logic_vector(31 downto 0);
		pci_cbe_i   : in std_logic_vector(3 downto 0);
		pci_cbe_o   : out std_logic_vector(3 downto 0);
		pci_cbe_oe  : out std_logic_vector(3 downto 0);
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
	    pci_int_i   : in std_logic_vector ( 3 downto 0 );
	    pci_int_o   : out std_logic_vector ( 3 downto 0 );
	    pci_int_oe  : out std_logic_vector ( 3 downto 0 );
		pci_m66en: in std_logic;
		pci_pme_i   : in std_logic;
		pci_pme_o   : out std_logic;
		pci_pme_oe  : out std_logic;

		ahb_hclk 		: in std_logic;
		ahb_hresetn	    : in std_logic;

		ahb_mst_hgrant	    : in std_logic;                         -- bus grant
		ahb_mst_hready      : in std_logic;                         -- transfer done
		ahb_mst_hresp       : in std_logic_vector(1 downto 0);         -- response type
        ahb_mst_hrdata      : in std_logic_vector(31 downto 0);        -- read data bus
        ahb_mst_hbusreq     : out std_ulogic;                           -- bus request
		ahb_mst_hlock       : out std_ulogic;                           -- lock request
		ahb_mst_htrans      : out std_logic_vector(1 downto 0);         -- transfer type
		ahb_mst_haddr       : out std_logic_vector(31 downto 0);        -- address bus (byte)
		ahb_mst_hwrite      : out std_ulogic;                           -- read/write
		ahb_mst_hsize       : out std_logic_vector(2 downto 0);         -- transfer size
		ahb_mst_hburst      : out std_logic_vector(2 downto 0);         -- burst type
		ahb_mst_hprot       : out std_logic_vector(3 downto 0);         -- protection control
		ahb_mst_hwdata      : out std_logic_vector(31 downto 0);        -- write data bus

		ahb_slv_hsel        : in std_logic;                            -- slave select
		ahb_slv_haddr       : in std_logic_vector(31 downto 0);        -- address bus (byte)
		ahb_slv_hwrite      : in std_ulogic;                           -- read/write
		ahb_slv_htrans      : in std_logic_vector(1 downto 0);         -- transfer type
		ahb_slv_hsize       : in std_logic_vector(2 downto 0);         -- transfer size
		ahb_slv_hburst      : in std_logic_vector(2 downto 0);         -- burst type
		ahb_slv_hwdata      : in std_logic_vector(31 downto 0);        -- write data bus
		ahb_slv_hprot       : in std_logic_vector(3 downto 0);         -- protection control
		ahb_slv_hmaster     : in std_logic_vector(3 downto 0);         -- current master
		ahb_slv_hmastlock   : in std_ulogic;                           -- locked access
		ahb_slv_hready_i    : in std_ulogic;                          -- transfer done
		ahb_slv_hready_o    : out std_ulogic;                          -- transfer done
		ahb_slv_hresp       : out std_logic_vector(1 downto 0);        -- response type
		ahb_slv_hrdata      : out std_logic_vector(31 downto 0);       -- read data bus
		ahb_slv_hsplit      : out std_logic_vector(15 downto 0);       -- split completion

		intr_req            : in std_logic_vector ( 3 downto 0 )           -- Interrupt request
	);
end grpci2_device;

architecture rtl of grpci2_device is

	signal pcii : pci_in_type;
	signal pcio : pci_out_type;
	signal ahbsi : ahb_slv_in_type;
	signal ahbso : ahb_slv_out_type;
	signal ahbmi : ahb_mst_in_type;
	signal ahbmo : ahb_mst_out_type;

begin

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
		ft           => 		0           ,
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
		rst        =>    ahb_hresetn, 
		clk        =>    ahb_hclk, 
		pciclk     =>    pci_clk, 
		dirq       =>    intr_req, 
		pcii       =>    pcii, 
		pcio       =>    pcio, 
		apbi       =>    apb_slv_in_none, -- NC
		apbo       =>    open,            -- NC
		ahbsi      =>    ahbsi, 
		ahbso      =>    ahbso, 
		ahbmi      =>    ahbmi,
		ahbmo      =>    ahbmo, 
		ahbdmi     =>    ahbm_in_none,    -- NC
	    ahbdmo     =>    open,            -- NC
	    ptarst     =>    open, 
		tbapbi     =>    open, 
		tbapbo     =>    open, 
		debugo     =>    open
	);

	pcii.rst <= pci_rst;
	pcii.gnt <= pci_gnt;
	pcii.idsel <= pci_idsel;
	pcii.ad <= pci_ad_i;
	pcii.cbe <= pci_cbe_i;
	pcii.frame <= pci_frame_i;
	pcii.irdy <= pci_irdy_i;
	pcii.trdy <= pci_trdy_i;
	pcii.devsel <= pci_devsel_i;
	pcii.stop <= pci_stop_i;
	pcii.lock <= pci_lock_i;
	pcii.perr <= pci_perr_i;
	pcii.serr <= pci_serr_i;
	pcii.par <= pci_par_i;
	pcii.host <= '1';
	pcii.pci66 <= pci_m66en;
	pcii.pme_status <= pci_pme_i;
	pcii.int <= (others => '1');

	pci_ad_o <= pcio.ad;
	pci_ad_oe <= pcio.vaden;

	pci_cbe_o <= pcio.cbe;
	pci_cbe_oe <= pcio.cbeen;

	pci_frame_o <= pcio.frame;
	pci_frame_oe <= pcio.frameen;

	pci_irdy_o <= pcio.irdy;
	pci_irdy_oe <= pcio.irdyen;

	pci_trdy_o <= pcio.trdy;
	pci_trdy_oe <= pcio.trdyen;

	pci_devsel_o <= pcio.devsel;
	pci_devsel_oe <= pcio.devselen;

	pci_stop_o <= pcio.stop;
	pci_stop_oe <= pcio.stopen;

	pci_perr_o <= pcio.perr;
	pci_perr_oe <= pcio.perren;

	pci_par_o <= pcio.par;
	pci_par_oe <= pcio.paren;

	pci_req_o <= pcio.req;
	pci_req_oe <= pcio.reqen;

	pci_lock_o <= pcio.lock;
	pci_lock_oe <= pcio.locken;

	pci_serr_o <= pcio.serr;
	pci_serr_oe <= pcio.serren;

	pci_int_o <= (others => '0');
	pci_int_oe <= pcio.vinten;

	pci_pme_o <= '0';
	pci_pme_oe <= pcio.pme_enable;

	ahbmi.hgrant(0) <= ahb_mst_hgrant;
	ahbmi.hgrant(1 to 15) <= (others => '0');

	ahbmi.hready <= ahb_mst_hready;
	ahbmi.hresp <= ahb_mst_hresp;
	--ahbmi.hrdata <= ahb_mst_hrdata;
	ahbmi.hrdata(7 downto 0) <= ahb_mst_hrdata(31 downto 24);
	ahbmi.hrdata(15 downto 8) <= ahb_mst_hrdata(23 downto 16);
	ahbmi.hrdata(23 downto 16) <= ahb_mst_hrdata(15 downto 8);
	ahbmi.hrdata(31 downto 24) <= ahb_mst_hrdata(7 downto 0);

	ahbmi.hirq <= (others => '0');
	ahbmi.testen <= '0';
	ahbmi.testrst <= '0';
	ahbmi.scanen <= '0';
	ahbmi.testoen <= '0';
	ahbmi.testin <= (others => '0');

	ahb_mst_hbusreq <= ahbmo.hbusreq;
	ahb_mst_hlock <= ahbmo.hlock;
	ahb_mst_htrans <= ahbmo.htrans;
	ahb_mst_haddr <= ahbmo.haddr;
	ahb_mst_hwrite <= ahbmo.hwrite;
	ahb_mst_hsize <= ahbmo.hsize;
	ahb_mst_hburst <= ahbmo.hburst;
	ahb_mst_hprot <= ahbmo.hprot;
	--ahb_mst_hwdata <= ahbmo.hwdata;
	ahb_mst_hwdata(7 downto 0) <= ahbmo.hwdata(31 downto 24);
	ahb_mst_hwdata(15 downto 8) <= ahbmo.hwdata(23 downto 16);
	ahb_mst_hwdata(23 downto 16) <= ahbmo.hwdata(15 downto 8);
	ahb_mst_hwdata(31 downto 24) <= ahbmo.hwdata(7 downto 0);

	ahbsi.hsel(0) <= ahb_slv_hsel;
	ahbsi.hsel(1 to 15) <= (others => '0');

	ahbsi.haddr <= ahb_slv_haddr;
	ahbsi.hwrite <= ahb_slv_hwrite;
	ahbsi.htrans <= ahb_slv_htrans;
	ahbsi.hsize <= ahb_slv_hsize;
	ahbsi.hburst <= ahb_slv_hburst;
	--ahbsi.hwdata <= ahb_slv_hwdata;
	ahbsi.hwdata(7 downto 0) <= ahb_slv_hwdata(31 downto 24);
	ahbsi.hwdata(15 downto 8) <= ahb_slv_hwdata(23 downto 16);
	ahbsi.hwdata(23 downto 16) <= ahb_slv_hwdata(15 downto 8);
	ahbsi.hwdata(31 downto 24) <= ahb_slv_hwdata(7 downto 0);

	ahbsi.hprot <= ahb_slv_hprot;
	ahbsi.hready <= ahb_slv_hready_i;
	ahbsi.hmaster <= ahb_slv_hmaster;
	ahbsi.hmastlock <= ahb_slv_hmastlock;
	ahbsi.hmbsel <= (others => '0');
	ahbsi.hirq <= (others => '0');
	ahbsi.testen <= '0';
	ahbsi.testrst <= '0';
	ahbsi.scanen <= '0';
	ahbsi.testoen <= '0';
	ahbsi.testin <= (others => '0');

	ahb_slv_hready_o <= ahbso.hready;
	ahb_slv_hresp <= ahbso.hresp;
	--ahb_slv_hrdata <= ahbso.hrdata;
	ahb_slv_hrdata(7 downto 0) <= ahbso.hrdata(31 downto 24);
	ahb_slv_hrdata(15 downto 8) <= ahbso.hrdata(23 downto 16);
	ahb_slv_hrdata(23 downto 16) <= ahbso.hrdata(15 downto 8);
	ahb_slv_hrdata(31 downto 24) <= ahbso.hrdata(7 downto 0);

	ahb_slv_hsplit <= ahbso.hsplit;

end rtl;
