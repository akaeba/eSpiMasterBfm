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
-- @see:		
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
        -- SPI transceiver mode
		type tSpiXcvMode is 
			(
				SINGLE,		--! standard SPI mode, MISO, MOSI
				DUAL,		--! two bidirectional data lines
				QUAD		--! four bidirectional data lines used
			);
		
		-- Configures the BFM
		type tESpiBfm is record
			TSpiClk         : time;    		--! period of spi clk
			spiMode			: tSpiXcvMode;	--! SPI transceiver mode
			sigSkew         : time;    		--! defines Signal Skew to prevent timing errors in back-anno
		end record tESpiBfm;
	-----------------------------
	
	
    -----------------------------
    -- Procedures
		-- init
        procedure init	(variable this : inout tESpiBfm);		--! initializes bus functional model 
	
	
	-----------------------------



end package eSpiMasterBfm;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- eSpiMasterBfmPKG: eSPI Master Bus functional model package
package body eSpiMasterBfm is

    ----------------------------------------------
    -- Functions
    ----------------------------------------------
	
	----------------------------------------------
	
	
    ----------------------------------------------
    -- "init"
    ----------------------------------------------
        --***************************
        -- init
        procedure init (variable this : inout tESpiBfm) is
        begin   
            this.TSpiClk	:= 50 ns;	--! default clock is 20MHz
			this.spiMode	:= QUAD;	--! for lines for data transfer used
			this.sigSkew	:= 0 ns;	--! no skew between clock edge and data defined
			
			
			
			
        end procedure init;
        --***************************
	




end package body eSpiMasterBfm;
--------------------------------------------------------------------------
