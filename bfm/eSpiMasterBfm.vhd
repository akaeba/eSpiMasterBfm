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
        -- Package internal Informations
			-- needed by to_hstring
            constant NUS	: STRING := " ";
			
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
			TSpiClk		: time;    		--! period of spi clk
			spiMode		: tSpiXcvMode;	--! SPI transceiver mode
			sigSkew		: time;    		--! defines Signal Skew to prevent timing errors in back-anno
			verbose		: natural;		--! message level; 0: no message, 1: errors, 2: error + warnings
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
			-- w/ status
			procedure IOWR_SHORT (
				variable this	: inout tESpiBfm; 
				signal CSn		: out std_logic; 
				signal SCK		: out std_logic; 
				signal DIO		: inout std_logic_vector(3 downto 0);
				constant adr	: in std_logic_vector(15 downto 0);		--! write address
				constant data	: in std_logic_vector(7 downto 0);		--! write data
				variable sts	: out std_logic_vector(15 downto 0)		--! status of write
			);
			-- w/o status
			procedure IOWR_SHORT ( 
				variable this	: inout tESpiBfm; 
				signal CSn		: out std_logic; 
				signal SCK		: out std_logic; 
				signal DIO		: inout std_logic_vector(3 downto 0);
				constant adr	: in std_logic_vector(15 downto 0);		--! write address
				constant data	: in std_logic_vector(7 downto 0)		--! write data
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
		
        --***************************   
        -- TO_HSTRING (STD_ULOGIC_VECTOR)
        -- SRC: http://www.eda-stds.org/vhdl-200x/vhdl-200x-ft/packages_old/std_logic_1164_additions.vhdl
            function to_hstring (value : STD_ULOGIC_VECTOR) return STRING is
                constant ne     : INTEGER := (value'length+3)/4;
                variable pad    : STD_ULOGIC_VECTOR(0 to (ne*4 - value'length) - 1);
                variable ivalue : STD_ULOGIC_VECTOR(0 to ne*4 - 1);
                variable result : STRING(1 to ne);
                variable quad   : STD_ULOGIC_VECTOR(0 to 3);
            begin
                if value'length < 1 then
                    return NUS;
                else
                    if value (value'left) = 'Z' then
                        pad := (others => 'Z');
                    else
                        pad := (others => '0');
                    end if;
                    ivalue := pad & value;
                    for i in 0 to ne-1 loop
                        quad := To_X01Z(ivalue(4*i to 4*i+3));
                        case quad is
                            when x"0"   => result(i+1) := '0';
                            when x"1"   => result(i+1) := '1';
                            when x"2"   => result(i+1) := '2';
                            when x"3"   => result(i+1) := '3';
                            when x"4"   => result(i+1) := '4';
                            when x"5"   => result(i+1) := '5';
                            when x"6"   => result(i+1) := '6';
                            when x"7"   => result(i+1) := '7';
                            when x"8"   => result(i+1) := '8';
                            when x"9"   => result(i+1) := '9';
                            when x"A"   => result(i+1) := 'A';
                            when x"B"   => result(i+1) := 'B';
                            when x"C"   => result(i+1) := 'C';
                            when x"D"   => result(i+1) := 'D';
                            when x"E"   => result(i+1) := 'E';
                            when x"F"   => result(i+1) := 'F';
                            when "ZZZZ" => result(i+1) := 'Z';
                            when others => result(i+1) := 'X';
                        end case;
                      end loop;
                    return result;
                end if;
            end function to_hstring;
        --***************************
		
        --***************************
        -- TO_HSTRING (STD_LOGIC_VECTOR)
        function to_hstring (value : STD_LOGIC_VECTOR) return STRING is
        begin
            return to_hstring(STD_ULOGIC_VECTOR(value));
        end function to_hstring;
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
			this.verbose	:= 0;		--! all messages disabled
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
        -- SPI Transmit
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
					if ( DUAL = this.spiMode ) then		--! two bits per clock cycle are transfered
						if ( 0 = (j+1) mod 2 ) then		
							SCK 			<= '0';		--! falling edge
							DIO(1 downto 0)	<= msg(i)(j downto j-1);
							wait for this.TSpiClk/2;	--! half clock cycle
							SCK 			<= '1';		--! rising edge
							wait for this.TSpiClk/2;	--! half clock cycle
						end if;
					elsif ( QUAD = this.spiMode ) then	--! four bits per clock cycle are transfered
						if ( 0 = (j+1) mod 4 ) then		
							SCK 			<= '0';		--! falling edge
							DIO(3 downto 0)	<= msg(i)(j downto j-3);
							wait for this.TSpiClk/2;	--! half clock cycle
							SCK 			<= '1';		--! rising edge
							wait for this.TSpiClk/2;	--! half clock cycle
						end if;
					else							--! one bits per clock cycle are transfered
						SCK 	<= '0';				--! falling edge
						DIO(0)	<= msg(i)(j);		--! assign data
						wait for this.TSpiClk/2;	--! half clock cycle
						SCK 	<= '1';				--! rising edge
						wait for this.TSpiClk/2;	--! half clock cycle
					end if;
				end loop;
			end loop;
		end procedure spiTx;
		--***************************
		
        --***************************
        -- SPI Turn-around (TAR)
		--   @see: Figure 14: Turn-Around Time (TAR = 2 clock)
		procedure spiTar
			(
				variable this	: inout tESpiBfm; 
				signal SCK 		: out std_logic; 						--! shift clock
				signal DIO 		: inout std_logic_vector(3 downto 0)	--! bidirectional data
			) is
		begin
			-- one clock cycle drive high
			SCK 	<= '0';						--! falling edge
			if ( DUAL = this.spiMode ) then		--! two bits per clock cycle are transfered
				DIO	<= (others => '1');
			elsif ( QUAD = this.spiMode ) then	--! four bits per clock cycle are transfered
				DIO(1 downto 0)	<= (others => '1');
			else								--! one bits per clock cycle are transfered
				DIO(0)	<= '1';
			end if;
			wait for this.TSpiClk/2;	--! half clock cycle
			SCK 	<= '1';				--! rising edge
			wait for this.TSpiClk/2;	--! half clock cycle
			-- one clock cycle tristate
			SCK 	<= '0';						--! falling edge
			if ( DUAL = this.spiMode ) then		--! two bits per clock cycle are transfered
				DIO	<= (others => 'Z');
			elsif ( QUAD = this.spiMode ) then	--! four bits per clock cycle are transfered
				DIO(1 downto 0)	<= (others => 'Z');
			else								--! one bits per clock cycle are transfered
				DIO(0)	<= 'Z';
			end if;
			wait for this.TSpiClk/2;	--! half clock cycle
			SCK 	<= '1';				--! rising edge
			wait for this.TSpiClk/2;	--! half clock cycle
		end procedure spiTar;
		--***************************
		
        --***************************
        -- SPI Receive
		--   Single Mode
		--     * eSPI master drives the I/O[0] during command phase
		--	   * response from slave is driven on the I/O[1]
		--   @see: Figure 54: Single I/O Mode
		procedure spiRx
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
					if ( DUAL = this.spiMode ) then		--! two bits per clock cycle are transfered
						if ( 0 = (j+1) mod 2 ) then		
							SCK 					<= '0';				--! falling edge
							wait for this.TSpiClk/2;					--! half clock cycle
							SCK 					<= '1';				--! rising edge
							msg(i)(j downto j-1)	:= DIO(1 downto 0);	--! capture data from line
							wait for this.TSpiClk/2;					--! half clock cycle
						end if;
					elsif ( QUAD = this.spiMode ) then	--! four bits per clock cycle are transfered
						if ( 0 = (j+1) mod 4 ) then		
							SCK 					<= '0';				--! falling edge
							wait for this.TSpiClk/2;					--! half clock cycle
							SCK 					<= '1';				--! rising edge
							msg(i)(j downto j-3)	:= DIO(3 downto 0);	--! capture data from line
							wait for this.TSpiClk/2;					--! half clock cycle
						end if;
					else							--! one bits per clock cycle are transfered
						SCK 		<= '0';			--! falling edge
						wait for this.TSpiClk/2;	--! half clock cycle
						SCK 		<= '1';			--! rising edge
						msg(i)(j)	:= DIO(1);		--! capture data from line
						wait for this.TSpiClk/2;	--! half clock cycle
					end if;
				end loop;
			end loop;
		end procedure spiRx;
		--***************************
		
	----------------------------------------------
	
	
    ----------------------------------------------
    -- IO Read / Write operation
    ----------------------------------------------
	
        --***************************
        -- IOWR_SHORT
		--   @see Figure 26: Master Initiated Short Non-Posted Transaction
		procedure IOWR_SHORT 
			( 
				variable this	: inout tESpiBfm; 
				signal CSn		: out std_logic; 
				signal SCK		: out std_logic; 
				signal DIO		: inout std_logic_vector(3 downto 0);
				constant adr	: in std_logic_vector(15 downto 0);
				constant data	: in std_logic_vector(7 downto 0);
				variable sts	: out std_logic_vector(15 downto 0)
			) is
			variable eSpiMsg : tESpiMsg(0 to 4);	--! eSpi Tx Packet has 5 Bytes for 1Byte data
		begin
			-- status
			sts := (others => '0');		--! no ero
			-- build & send Command
			eSpiMsg 	:= (others => (others => '0'));	--! clear
			eSpiMsg(0)	:= CMD_PUT_IOWR_SHORT & "01";	--! CMD: short write with one byte
			eSpiMsg(1)	:= adr(15 downto 8);
			eSpiMsg(2)	:= adr(7 downto 0);
			eSpiMsg(3)	:= data;
			eSpiMsg(4)	:= crc8(eSpiMsg(0 to 3));		--! add message checksum
			-- send command
			CSn	<= '0';
			spiTx(this, eSpiMsg, SCK, DIO);	--! write to slave
			-- tar cycle
			spiTar(this, SCK, DIO);	--! change direction (write-to-read)
			-- read response
			-- Byte 0: 		Response
			-- Byte 1/2:	Status (STS)
			-- Byte 3:		CRC
			eSpiMsg := (others => (others => '0'));	--! clear
			spiRx(this, eSpiMsg(0 to 3), SCK, DIO);	--! read from slave
			-- check CRC
			if ( eSpiMsg(3) /= crc8(eSpiMsg(0 to 2)) ) then
				if ( this.verbose > 0 ) then
					Report "eSpiMasterBfm:IOWR_SHORT:CRC rcv=0x" & to_hstring(eSpiMsg(3)) & "; calc=0x" & to_hstring(crc8(eSpiMsg(0 to 2))) & ";" severity error;
				end if;
			end if;
			
			
			
			-- Terminate connection to slave
			SCK	<= '0';
			wait for this.TSpiClk/2;	--! half clock cycle
			CSn	<= '1';
			wait for this.TSpiClk;		--! limits CSn bandwidth to SCK
		end procedure IOWR_SHORT;
		--***************************
		
        --***************************
        -- IOWR_SHORT w/o status
		--   @see Figure 26: Master Initiated Short Non-Posted Transaction
		procedure IOWR_SHORT 
			( 
				variable this	: inout tESpiBfm; 
				signal CSn		: out std_logic; 
				signal SCK		: out std_logic; 
				signal DIO		: inout std_logic_vector(3 downto 0);
				constant adr	: in std_logic_vector(15 downto 0);
				constant data	: in std_logic_vector(7 downto 0)
			) is
			variable sts : std_logic_vector(15 downto 0);	--! wrapper variable for status
		begin
			IOWR_SHORT( this, CSn, SCK, DIO, adr, data, sts );
		end procedure IOWR_SHORT;
		--***************************
		
		
		
		
	
	----------------------------------------------



end package body eSpiMasterBfm;
--------------------------------------------------------------------------
