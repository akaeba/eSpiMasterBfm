--************************************************************************
-- @author:  	Andreas Kaeberlein
-- @copyright:	Copyright 2020
-- @credits: 	AKAE
--
-- @license:  	BSDv3
-- @maintainer:	Andreas Kaeberlein
-- @email:		andreas.kaeberlein@web.de
--
-- @file:       eSpiMasterBfm.vhd
-- @note:       VHDL'93
-- @date:   	2020-01-04
--
-- @see:		https://www.intel.com/content/dam/support/us/en/documents/software/chipset-software/327432-004_espi_base_specification_rev1.0_cb.pdf
-- @brief:      bus functional model for enhanced SPI (eSPI)
--				provides function to interact with an eSPI 
--				slave
--************************************************************************



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
library std;
    use std.textio.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- eSpiMasterBfmPKG: eSPI Master Bus functional model package
package eSpiMasterBfm is

    -----------------------------
    -- Constant  
        -- parametrizes the address mapped data organization
            constant C_DWIDTH   : integer := 8;         --! data width
            constant C_SIZE     : integer := 2**16;     --! memory length
        
        -- Package internal Informations
            constant DEBUGMODE  : boolean := FALSE;
			
		-- Command Opcode Encodings (Table 3)
			constant CMD_PUT_PC				: std_logic_vector(7 downto 0) := "00000000";	--! Put a posted or completion header and optional data.
			constant CMD_PUT_NP				: std_logic_vector(7 downto 0) := "00000010";	--! Put a non-posted header and optional data.
			constant CMD_GET_PC				: std_logic_vector(7 downto 0) := "00000001";	--! Get a posted or completion header and optional data.
			constant CMD_GET_NP				: std_logic_vector(7 downto 0) := "00000011";	--! Get a non-posted header and optional data.
			constant CMD_PUT_IORD_SHORT		: std_logic_vector(7 downto 2) := "010000";		--! Put a short (1, 2 or 4 bytes) non-posted I/O Read packet.
			constant CMD_PUT_IOWR_SHORT 	: std_logic_vector(7 downto 2) := "010001";		--! Put a short (1, 2 or 4 bytes) non-posted I/O Write packet.
			constant CMD_PUT_MEMRD32_SHORT	: std_logic_vector(7 downto 2) := "010010";		--! Put a short (1, 2 or 4 bytes) non-posted Memory Read 32 packet.
			constant CMD_PUT_MEMWR32_SHORT	: std_logic_vector(7 downto 2) := "010011";		--! Put a short (1, 2 or 4 bytes) posted Memory Write 32 packet.
			constant CMD_PUT_VWIRE			: std_logic_vector(7 downto 0) := "00000100";	--! Put a Tunneled virtual wire packet.
			constant CMD_GET_VWIRE			: std_logic_vector(7 downto 0) := "00000101";	--! Get a Tunneled virtual wire packet.
			constant CMD_PUT_OOB			: std_logic_vector(7 downto 0) := "00000110";	--! Put an OOB (Tunneled SMBus) message.
			constant CMD_GET_OOB			: std_logic_vector(7 downto 0) := "00000111";	--! Get an OOB (Tunneled SMBus) message.
			constant CMD_PUT_FLASH_C		: std_logic_vector(7 downto 0) := "00001000";	--! Put a Flash Access completion.
			constant CMD_GET_FLASH_NP		: std_logic_vector(7 downto 0) := "00001001";	--! Get a non-posted Flash Access request.
			constant CMD_GET_STATUS			: std_logic_vector(7 downto 0) := "00100101";	--! Command initiated by the master to read the status register of the slave.
			constant CMD_SET_CONFIGURATION	: std_logic_vector(7 downto 0) := "00100010";	--! Command to set the capabilities of the slave as part of the initialization. This is typically done after the master discovers the capabilities of the slave.
			constant CMD_GET_CONFIGURATION	: std_logic_vector(7 downto 0) := "00100001";	--! Command to discover the capabilities of the slave as part of the initialization.
			constant CMD_RESET				: std_logic_vector(7 downto 0) := "11111111";	--! In-band RESET command.
    -----------------------------
	
	
    -----------------------------
    -- Data typs
        -- memory organization
		type tESpiMsg is array (natural range <>) of std_logic_vector (7 downto 0);	--! Espi data packet
		
		-- SPI transceiver mode
		type tSpiXcvMode is 
			(
				SINGLE,	--! standard SPI mode, MISO, MOSI
				DUAL,	--! two bidirectional data lines
				QUAD	--! four bidirectional data lines used
			);
			
		-- SPI Direction
		type tESpiDir is 
			(
				MOSI,	--! Master-out, Slave-in
				MISO	--! Master-in, Slave-out
			);
		
		-- Configures the BFM
		type tESpiBfm is record
			TSpiClk         : time;    		--! period of spi clk
			spiMode			: tSpiXcvMode;	--! SPI transceiver mode
			sigSkew         : time;    		--! defines Signal Skew to prevent timing errors in back-anno
		end record tESpiBfm;
	-----------------------------
	
	
    -----------------------------
    -- Functions
		-- calculate crc
		function crc8 ( msg : in tESpiMsg ) return std_logic_vector;
	-----------------------------
	
	
    -----------------------------
    -- Procedures
		-- init: initializes bus functional model
        procedure init
			( 
				variable this	: inout tESpiBfm;						--! common handle 
				signal CSn		: out std_logic; 						--! slave select
				signal SCK 		: out std_logic; 						--! shift clock
				signal DIO 		: inout std_logic_vector(3 downto 0)	--! bidirectional data	
			);

		-- IOWR_SHORT: Master Initiated Short Non-Posted Transaction
			procedure IOWR_SHORT (
				variable this	: inout tESpiBfm; 
				signal CSn		: out std_logic; 
				signal SCK		: out std_logic; 
				signal DIO		: inout std_logic_vector(3 downto 0);
				constant adr	: in std_logic_vector(15 downto 0);
				constant data	: in std_logic_vector(7 downto 0)
			);
		
	-----------------------------

end package eSpiMasterBfm;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- eSpiMasterBfmPKG: eSPI Master Bus functional model package
package body eSpiMasterBfm is

    ----------------------------------------------
    -- Functions
    ----------------------------------------------
	
        --***************************
        -- calc crc    
        function crc8 ( msg : in tESpiMsg ) return std_logic_vector is
			constant polynom	: std_logic_vector(7 downto 0) := x"07";
			variable remainder 	: std_logic_vector(7 downto 0); 
		begin
			-- init
			remainder := (others => '0');
			-- calc crc
			-- SRC: https://barrgroup.com/embedded-systems/how-to/crc-calculation-c-code
			-- iterate over byte messages
			for i in msg'low to msg'high loop
				remainder := remainder xor msg(i);	--! add new messeage
				-- iterate over bit in byte of message
				for j in msg(i)'high downto msg(i)'low loop
					if ( '1' = remainder(remainder'left) ) then	--! Topbit is one
						remainder := std_logic_vector(unsigned(remainder) sll 1) xor polynom;
					else
						remainder := std_logic_vector(unsigned(remainder) sll 1);
					end if;
				end loop;
			end loop;
			-- release
            return remainder;
        end function;
        --***************************
	
	----------------------------------------------
	
	
    ----------------------------------------------
    -- "init"
    ----------------------------------------------
        --***************************
        -- init
        procedure init 
			( 
				variable this	: inout tESpiBfm;						--! common handle 
				signal CSn		: out std_logic; 						--! slave select
				signal SCK 		: out std_logic; 						--! shift clock
				signal DIO 		: inout std_logic_vector(3 downto 0)	--! bidirectional data	
			) is
        begin   
            -- common handle
			this.TSpiClk	:= 50 ns;	--! default clock is 20MHz
			this.spiMode	:= SINGLE;	--! Default mode, out of reset
			this.sigSkew	:= 0 ns;	--! no skew between clock edge and data defined
			-- signals
			CSn	<= '1';
			SCK	<= '0';
			DIO	<= (others => 'Z');
        end procedure init;
        --***************************
	----------------------------------------------
	
	
    ----------------------------------------------
    -- SPI 
    ----------------------------------------------
        --***************************
        -- SPI Transceiver Procedure
		--   Single Mode
		--     * eSPI master drives the I/O[0] during command phase
		--	   * response from slave is driven on the I/O[1]
		--   @see: Figure 54: Single I/O Mode
		procedure spiTx
			(
				variable this	: inout tESpiBfm; 
				variable msg	: inout tESpiMsg;
				signal SCK 		: out std_logic; 						--! shift clock
				signal DIO 		: inout std_logic_vector(3 downto 0)	--! bidirectional data
			) is
		begin
			-- iterate over message bytes
			for i in msg'low to msg'high loop
				-- iterate over bits in a single message byte
				for j in msg(i)'high downto msg(i)'low loop
					-- dispatch mode
					if ( DUAL = this.spiMode ) then		-- add first data value
						if ( 0 = (j+1) mod 2 ) then		
							SCK 			<= '0';		--! falling edge
							DIO(1 downto 0)	<= msg(i)(j downto j-1);
							wait for this.TSpiClk/2;	--! half clock cycle
							SCK 			<= '1';		--! rising edge
							wait for this.TSpiClk/2;	--! half clock cycle
						end if;
					elsif ( QUAD = this.spiMode ) then
						if ( 0 = (j+1) mod 4 ) then		
							SCK 			<= '0';		--! falling edge
							DIO(3 downto 0)	<= msg(i)(j downto j-3);
							wait for this.TSpiClk/2;	--! half clock cycle
							SCK 			<= '1';		--! rising edge
							wait for this.TSpiClk/2;	--! half clock cycle
						end if;
					else
						SCK 	<= '0';				--! falling edge
						DIO(0)	<= msg(i)(j);		--! assign data
						wait for this.TSpiClk/2;	--! half clock cycle
						SCK 	<= '1';				--! rising edge
						wait for this.TSpiClk/2;	--! half clock cycle
					end if;
				end loop;
			end loop;
			SCK <= '0';				--! rising edge
			DIO <= (others => 'Z');	--! tristate
		end procedure spiTx;
		--***************************
		
	----------------------------------------------
	
	
    ----------------------------------------------
    -- IO Read / Write operation
    ----------------------------------------------
	
        --***************************
        -- IOWR_SHORT
		procedure IOWR_SHORT 
			( 
				variable this	: inout tESpiBfm; 
				signal CSn		: out std_logic; 
				signal SCK		: out std_logic; 
				signal DIO		: inout std_logic_vector(3 downto 0);
				constant adr	: in std_logic_vector(15 downto 0);
				constant data	: in std_logic_vector(7 downto 0)
			) is
			variable eSpiMsg : tESpiMsg(0 to 4);		--! eSpi Tx Packet has 5 Bytes for 1Byte data
		begin
			-- build & send Command
			eSpiMsg 	:= (others => (others => '0'));	--! init
			eSpiMsg(0)	:= CMD_PUT_IOWR_SHORT & "01";	--! CMD: short write with one byte
			eSpiMsg(1)	:= adr(15 downto 8);
			eSpiMsg(2)	:= adr(7 downto 0);
			eSpiMsg(3)	:= data;
			eSpiMsg(4)	:= crc8(eSpiMsg(0 to 3));		--! add message checksum
			-- send command
			CSn	<= '0';
			spiTx(this, eSpiMsg, SCK, DIO);		--! bring it to the line
			-- tar cycle
			
			-- get response response
			
			CSn	<= '1';
			
			
			
		
		
		end procedure IOWR_SHORT;
		--***************************
	
	----------------------------------------------



end package body eSpiMasterBfm;
--------------------------------------------------------------------------
