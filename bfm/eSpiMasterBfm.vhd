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
-- @see:		https://github.com/akaeba/eSpiMM
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
    -- Data typs
        -- memory organization
		type tMemX08 is array (natural range <>) of std_logic_vector (7 downto 0);	--! Byte orientated memory array
		
		-- SPI transceiver mode
		type tSpiXcvMode is 
			(
				SINGLE,	--! standard SPI mode, MISO, MOSI
				DUAL,	--! two bidirectional data lines
				QUAD	--! four bidirectional data lines used
			);
			
		-- SPI Direction
		type tESpiRsp is 
			(
				ACCEPT,				--! Command was successfully received
				DEFER,				--! Only valid in response to a PUT_NP
				NON_FATAL_ERROR,	--! The received command had an error with nonfatal severity
				FATAL_ERROR,		--! The received command had a fatal error that prevented the transaction layer packet from being successfully processed
				WAIT_STATE,			--! Adds one byte-time of delay when responding to a transaction on the bus.
				NO_RESPONSE,		--! The response encoding of all 1’s is defined as no response
				NO_DECODE			--! not in eSPI Spec, no decoding possible
			);
			
		-- Configures the BFM
		type tESpiBfm is record
			TSpiClk		: time;    		--! period of spi clk
			crcSlvEna	: boolean;		--! CRC evaluation on Slave is enabled
			spiMode		: tSpiXcvMode;	--! SPI transceiver mode
			sigSkew		: time;    		--! defines Signal Skew to prevent timing errors in back-anno
			verbose		: natural;		--! message level; 0: no message, 1: errors, 2: error + warnings
		end record tESpiBfm;
	-----------------------------
	
	
    -----------------------------
    -- Functions (public)
		function crc8 ( msg : in tMemX08 ) return std_logic_vector;						--! crc8: 		calculate crc from a message
		function sts2str ( sts : in std_logic_vector(15 downto 0) ) return string;		--! sts2str:	convert slave status register into a human readable string
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
		
        -- RESET: apply reset sequence
		-- @see Figure 63: In-band RESET Command
		procedure RESET
			(
				variable this		: inout tESpiBfm; 
				signal CSn			: out std_logic; 
				signal SCK 			: out std_logic; 						--! shift clock
				signal DIO 			: inout std_logic_vector(3 downto 0)	--! bidirectional data
			);
			
		-- GET_CONFIGURATION:
		-- @see Figure 22: GET_CONFIGURATION Command
			-- w/ status
			procedure GET_CONFIGURATION 
				( 
					variable this		: inout tESpiBfm; 
					signal CSn			: out std_logic; 
					signal SCK			: out std_logic; 
					signal DIO			: inout std_logic_vector(3 downto 0);
					constant adr		: in std_logic_vector(15 downto 0);		--! config address
					variable config		: out std_logic_vector(31 downto 0);	--! config data
					variable status		: out std_logic_vector(15 downto 0);	--! status
					variable response	: out tESpiRsp;							--! slave response
					variable good		: inout boolean							--! procedure state
				);
			-- w/o status, response, regs, instead print to console
			procedure GET_CONFIGURATION 
				( 
					variable this	: inout tESpiBfm; 
					signal CSn		: out std_logic; 
					signal SCK		: out std_logic; 
					signal DIO		: inout std_logic_vector(3 downto 0);
					constant adr	: in std_logic_vector(15 downto 0);		--! config address
					variable config	: out std_logic_vector(31 downto 0);	--! config data
					variable good	: inout boolean							--! procedure state
				);
				
        -- GET_STATUS
		-- @see Figure 20: GET_STATUS Command
			-- w/o any print to console
			procedure GET_STATUS 
				(
					variable this		: inout tESpiBfm; 
					signal CSn			: out std_logic; 
					signal SCK			: out std_logic; 
					signal DIO			: inout std_logic_vector(3 downto 0);
					variable status 	: out std_logic_vector(15 downto 0);
					variable response	: out tESpiRsp;		
					variable good		: inout boolean
				);
			-- print to console only
			procedure GET_STATUS 
				(
					variable this	: inout tESpiBfm; 
					signal CSn		: out std_logic; 
					signal SCK		: out std_logic; 
					signal DIO		: inout std_logic_vector(3 downto 0);
					variable good	: inout boolean
				);
				
		-- MEMWR32
		--  @see Figure 35: Short Peripheral Memory or Short I/O Write Packet Format (Master Initiated only)
			-- arbitrary number of data bytes, response and status register
			procedure MEMWR32 
				(
					variable this		: inout tESpiBfm; 
					signal CSn			: out std_logic; 
					signal SCK			: out std_logic; 
					signal DIO			: inout std_logic_vector(3 downto 0);
					constant adr 		: in std_logic_vector(31 downto 0);		--! memory address
					constant data		: in tMemX08;							--! arbitrary number of data bytes
					variable status 	: out std_logic_vector(15 downto 0);	--! slave status
					variable response	: out tESpiRsp;							--! slave command response
					variable good		: inout boolean							--! successful? 
				);
			-- single data byte, w/o response and status register
			procedure MEMWR32 
				(
					variable this		: inout tESpiBfm; 
					signal CSn			: out std_logic; 
					signal SCK			: out std_logic; 
					signal DIO			: inout std_logic_vector(3 downto 0);
					constant adr 		: in std_logic_vector(31 downto 0);		--! memory address
					constant data		: in std_logic_vector(7 downto 0);		--! single data word
					variable good		: inout boolean							--! successful?
				);
			-- multiple data bytes, w/o response and status register
			procedure MEMWR32 
				(
					variable this		: inout tESpiBfm; 
					signal CSn			: out std_logic; 
					signal SCK			: out std_logic; 
					signal DIO			: inout std_logic_vector(3 downto 0);
					constant adr 		: in std_logic_vector(31 downto 0);		--! memory address
					constant data		: in tMemX08;							--! multiple data
					variable good		: inout boolean							--! successful 
				);
				
        -- MEMRD32
		--  @see Figure 37: Short Peripheral Memory or Short I/O Read Packet Format (Master Initiated only)
			-- arbitrary number of data bytes, response and status register
			procedure MEMRD32 
				(
					variable this		: inout tESpiBfm; 
					signal CSn			: out std_logic; 
					signal SCK			: out std_logic; 
					signal DIO			: inout std_logic_vector(3 downto 0);
					constant adr 		: in std_logic_vector(31 downto 0);		--! memory address
					variable data		: out tMemX08;							--! arbitrary number of data bytes
					variable status 	: out std_logic_vector(15 downto 0);	--! slave status
					variable response	: out tESpiRsp;							--! slave command response
					variable good		: inout boolean							--! successful? 
				);
			-- single data byte, w/o response and status register
			procedure MEMRD32 
				(
					variable this		: inout tESpiBfm; 
					signal CSn			: out std_logic; 
					signal SCK			: out std_logic; 
					signal DIO			: inout std_logic_vector(3 downto 0);
					constant adr 		: in std_logic_vector(31 downto 0);		--! memory address
					variable data		: out std_logic_vector(7 downto 0);		--! single data word
					variable good		: inout boolean							--! successful 
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
    -- Constant eSPI Handling
	----------------------------------------------
	
		--***************************
		-- Command Opcode Encodings (Table 3)
		constant C_PUT_PC				: std_logic_vector(7 downto 0) := "00000000";	--! Put a posted or completion header and optional data.
		constant C_PUT_NP				: std_logic_vector(7 downto 0) := "00000010";	--! Put a non-posted header and optional data.
		constant C_GET_PC				: std_logic_vector(7 downto 0) := "00000001";	--! Get a posted or completion header and optional data.
		constant C_GET_NP				: std_logic_vector(7 downto 0) := "00000011";	--! Get a non-posted header and optional data.
		constant C_PUT_IORD_SHORT		: std_logic_vector(7 downto 2) := "010000";		--! Put a short (1, 2 or 4 bytes) non-posted I/O Read packet.
		constant C_PUT_IOWR_SHORT 		: std_logic_vector(7 downto 2) := "010001";		--! Put a short (1, 2 or 4 bytes) non-posted I/O Write packet.
		constant C_PUT_MEMRD32_SHORT	: std_logic_vector(7 downto 2) := "010010";		--! Put a short (1, 2 or 4 bytes) non-posted Memory Read 32 packet.
		constant C_PUT_MEMWR32_SHORT	: std_logic_vector(7 downto 2) := "010011";		--! Put a short (1, 2 or 4 bytes) posted Memory Write 32 packet.
		constant C_PUT_VWIRE			: std_logic_vector(7 downto 0) := "00000100";	--! Put a Tunneled virtual wire packet.
		constant C_GET_VWIRE			: std_logic_vector(7 downto 0) := "00000101";	--! Get a Tunneled virtual wire packet.
		constant C_PUT_OOB				: std_logic_vector(7 downto 0) := "00000110";	--! Put an OOB (Tunneled SMBus) message.
		constant C_GET_OOB				: std_logic_vector(7 downto 0) := "00000111";	--! Get an OOB (Tunneled SMBus) message.
		constant C_PUT_FLASH_C			: std_logic_vector(7 downto 0) := "00001000";	--! Put a Flash Access completion.
		constant C_GET_FLASH_NP			: std_logic_vector(7 downto 0) := "00001001";	--! Get a non-posted Flash Access request.
		constant C_GET_STATUS			: std_logic_vector(7 downto 0) := "00100101";	--! Command initiated by the master to read the status register of the slave.
		constant C_SET_CONFIGURATION	: std_logic_vector(7 downto 0) := "00100010";	--! Command to set the capabilities of the slave as part of the initialization. This is typically done after the master discovers the capabilities of the slave.
		constant C_GET_CONFIGURATION	: std_logic_vector(7 downto 0) := "00100001";	--! Command to discover the capabilities of the slave as part of the initialization.
		constant C_RESET				: std_logic_vector(7 downto 0) := "11111111";	--! In-band RESET command.
		--***************************
		
		--***************************
		-- Config Register eSpi Slave, Table 20: Slave Registers
		constant C_DEV_IDENT	: std_logic_vector(15 downto 0)	:= x"0004";		--! Device Identification
		constant C_GEN_CAP_CFG	: std_logic_vector(15 downto 0)	:= x"0008";		--! General Capabilities and Configurations
		constant C_CH0_CAP_CFG	: std_logic_vector(15 downto 0)	:= x"0010";		--! Channel 0 Capabilities and Configurations
		constant C_CH1_CAP_CFG	: std_logic_vector(15 downto 0)	:= x"0020";		--! Channel 1 Capabilities and Configurations
		constant C_CH2_CAP_CFG	: std_logic_vector(15 downto 0)	:= x"0030";		--! Channel 2 Capabilities and Configurations
		constant C_CH3_CAP_CFG	: std_logic_vector(15 downto 0)	:= x"0040";		--! Channel 3 Capabilities and Configurations
		--***************************
		
		--***************************
		-- Response Fields, Table 4: Response Field Encodings
		constant C_ACCEPT			: std_logic_vector(5 downto 0)	:= "001000";	--! Command was successfully received
		constant C_DEFER			: std_logic_vector(7 downto 0)	:= "00000001";	--! Only valid in response to a PUT_NP
		constant C_NON_FATAL_ERROR	: std_logic_vector(7 downto 0)	:= "00000010";	--! The received command had an error with nonfatal severity
		constant C_FATAL_ERROR		: std_logic_vector(7 downto 0)	:= "00000011";	--! The received command had a fatal error that prevented the transaction layer packet from being successfully processed
		constant C_WAIT_STATE		: std_logic_vector(7 downto 0)	:= "00001111";	--! Adds one byte-time of delay when responding to a transaction on the bus.
		constant C_NO_RESPONSE		: std_logic_vector(7 downto 0)	:= "11111111";	--! The response encoding of all 1’s is defined as no response
		--***************************
		
		--***************************
		-- Cycle Type Encodings, Table 6: Cycle Types
		constant C_CT_MEMRD32		: std_logic_vector(7 downto 0)	:= "00000000";	--! 32 bit addressing Memory Read Request. LPC Memory Read and LPC Bus Master Memory Read requests are mapped to this cycle type.
		constant C_CT_MEMRD64		: std_logic_vector(7 downto 0)	:= "00000010";	--! 64 bit addressing Memory Read Request. Support of upstream Memory Read 64 is mandatory for eSPI slaves that are bus mastering capable.
		constant C_CT_MEMWR32		: std_logic_vector(7 downto 0)	:= "00000001";	--! 32 bit addressing Memory Write Request. LPC Memory Write and LPC Bus Master Memory Write requests are mapped to this cycle type.
		constant C_CT_MEMWR64		: std_logic_vector(7 downto 0)	:= "00000011";	--! 64 bit addressing Memory Write Request. Support of upstream Memory Write 64 is mandatory for eSPI slaves that are bus mastering capable.
		--***************************
		
	----------------------------------------------
		
		
    ----------------------------------------------
    -- Constant BFM Handling
	----------------------------------------------		
		
		--***************************
		-- Message Levels
		constant C_MSG_ERROR	: integer := 0;
		constant C_MSG_WARN		: integer := 1;
		constant C_MSG_INFO		: integer := 2;
		--***************************
		
	----------------------------------------------


    ----------------------------------------------
    -- Functions
    ----------------------------------------------
	
        --***************************
        -- calc crc    
        function crc8 ( msg : in tMemX08 ) return std_logic_vector is
			constant polynom	: std_logic_vector(7 downto 0) := x"07";
			variable remainder 	: std_logic_vector(7 downto 0); 
		begin
			-- init
			remainder := (others => '0');
			-- calculate crc
			-- SRC: https://barrgroup.com/embedded-systems/how-to/crc-calculation-c-code
			-- iterate over byte messages
			for i in msg'low to msg'high loop
				remainder := remainder xor msg(i);	--! add new message
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
                constant nus	: STRING := " ";
				constant ne     : INTEGER := (value'length+3)/4;
                variable pad    : STD_ULOGIC_VECTOR(0 to (ne*4 - value'length) - 1);
                variable ivalue : STD_ULOGIC_VECTOR(0 to ne*4 - 1);
                variable result : STRING(1 to ne);
                variable quad   : STD_ULOGIC_VECTOR(0 to 3);
            begin
                if value'length < 1 then
                    return nus;
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
		
		
        --***************************   
        -- hexStr
		--   converts byte array into hexadecimal string
		function hexStr ( msg : in tMemX08 ) return string is
			variable str	: string(1 to (msg'length+1)*5+1); 	--! 8bit per 
		begin
			-- init
			str := (others => NUL);
			-- build hex value
			for i in 0 to msg'length-1 loop
				str(i*5+1 to i*5+5) := "0x" & to_hstring(msg(i)) & " ";
			end loop;
			-- drop last blank
			str((msg'length)*5+5) := character(NUL);
			-- return
			return str;
		end function hexStr;
		--***************************
		
		
		--***************************   
        -- checkCRC
		--   calculates CRC from msglen-1 and compares with last byte of msg len
		function checkCRC ( this : in tESpiBfm; msg : in tMemX08 ) return boolean is
			variable ret : boolean := true;
		begin
			if ( this.crcSlvEna ) then
				if ( msg(msg'length-1) /= crc8(msg(0 to msg'length-2)) ) then
					ret := false;
					if ( this.verbose > 0 ) then
						Report "eSpiMasterBfm:checkCRC rcv=0x" & to_hstring(msg(msg'length-1)) & "; calc=0x" & to_hstring(crc8(msg(0 to msg'length-2))) & ";" severity error;
					end if;
				end if;
			end if;
			return ret;
		end function checkCRC;
		--*************************** 
		
		
		--***************************   
        -- decodeRsp
		--   decodes the responses from the slave
		function decodeRsp ( response : in std_logic_vector(7 downto 0) ) return tESpiRsp is
			variable ret : tESpiRsp;
		begin
			-- decode
			if ( C_ACCEPT = response(C_ACCEPT'range) ) then
				ret	:= ACCEPT;
			elsif ( C_DEFER = response(C_DEFER'range) ) then
				ret	:= DEFER;
			elsif ( C_NON_FATAL_ERROR = response(C_NON_FATAL_ERROR'range) ) then
				ret	:= NON_FATAL_ERROR;
			elsif ( C_FATAL_ERROR = response(C_FATAL_ERROR'range) ) then
				ret	:= FATAL_ERROR;
			elsif ( C_WAIT_STATE = response(C_WAIT_STATE'range) ) then
				ret	:= WAIT_STATE;
			elsif ( C_NO_RESPONSE = response(C_NO_RESPONSE'range) ) then
				ret	:= NO_RESPONSE;
			else
				ret := NO_DECODE;
			end if;
			-- return
			return ret;
		end function decodeRsp;
		--***************************
		
		
		--***************************   
        -- rsp2str
		--   print decoded response register to string in a human-readable way
		function rsp2str ( rsp : tESpiRsp ) return string is
			variable ret : string(1 to 16) := (others => character(NUL));	--! make empty
		begin
			-- convert
			case rsp is
				when ACCEPT 			=> ret(1 to 6)	:= "ACCEPT";
				when DEFER				=> ret(1 to 5)	:= "DEFER";
				when NON_FATAL_ERROR	=> ret(1 to 15)	:= "NON_FATAL_ERROR";
				when FATAL_ERROR		=> ret(1 to 11)	:= "FATAL_ERROR";
				when WAIT_STATE			=> ret(1 to 10)	:= "WAIT_STATE";
				when NO_RESPONSE		=> ret(1 to 11)	:= "NO_RESPONSE";
				when NO_DECODE			=> ret(1 to 9)	:= "NO_DECODE";
			end case;
			-- release
			return ret;
		end function rsp2str;
		--***************************
		
		
		--***************************   
        -- sts2str
		--   print status register to string in a human-readable way
		function sts2str ( sts : in std_logic_vector(15 downto 0) ) return string is
			variable ret : string(1 to 808);
		begin
			-- convert
			ret :=	character(LF) & 
					"     Status           : 0x"	& to_hstring(sts)																								& character(LF) & 
					"       PC_FREE        : " 		& integer'image(to_integer(unsigned(sts(00 downto 00)))) & "       Peripheral Posted/Completion Rx Queue Free" 	& character(LF) &  
					"       NP_FREE        : " 		& integer'image(to_integer(unsigned(sts(01 downto 01)))) & "       Peripheral Non-Posted Rx Queue Free" 		& character(LF) &  
					"       VWIRE_FREE     : " 		& integer'image(to_integer(unsigned(sts(02 downto 02)))) & "       Virtual Wire Rx Queue Free" 					& character(LF) &  
					"       OOB_FREE       : " 		& integer'image(to_integer(unsigned(sts(03 downto 03)))) & "       OOB Posted Rx Queue Free" 					& character(LF) &  
					"       PC_AVAIL       : " 		& integer'image(to_integer(unsigned(sts(04 downto 04)))) & "       Peripheral Posted/Completion Tx Queue Avail"	& character(LF) &  
					"       NP_AVAIL       : " 		& integer'image(to_integer(unsigned(sts(05 downto 05)))) & "       Peripheral Non-Posted Tx Queue Avail" 		& character(LF) &  
					"       VWIRE_AVAIL    : " 		& integer'image(to_integer(unsigned(sts(06 downto 06)))) & "       Virtual Wire Tx Queue Avail" 				& character(LF) &  
					"       OOB_AVAIL      : " 		& integer'image(to_integer(unsigned(sts(07 downto 07)))) & "       OOB Posted Tx Queue Avail" 					& character(LF) &  
					"       FLASH_C_FREE   : " 		& integer'image(to_integer(unsigned(sts(08 downto 08)))) & "       Flash Completion Rx Queue Free" 				& character(LF) &  
					"       FLASH_NP_FREE  : " 		& integer'image(to_integer(unsigned(sts(09 downto 09)))) & "       Flash Non-Posted Rx Queue Free" 				& character(LF) &  
					"       FLASH_C_AVAIL  : " 		& integer'image(to_integer(unsigned(sts(12 downto 12)))) & "       Flash Completion Tx Queue Avail" 			& character(LF) &  
					"       FLASH_NP_AVAIL : " 		& integer'image(to_integer(unsigned(sts(13 downto 13)))) & "       Flash Non-Posted Tx Queue Avail" 			& character(LF);  
			-- release
			return ret;
		end function sts2str;
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
			this.crcSlvEna	:= false;	--! out of reset is CRC disabled
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
				variable msg	: inout tMemX08;
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
						DIO(0)	<= msg(i)(j);	--! assign data
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
				variable msg	: inout tMemX08;
				signal SCK 		: out std_logic; 						--! shift clock
				signal DIO 		: inout std_logic_vector(3 downto 0)	--! bidirectional data
			) is
			variable slv1	: std_logic_vector(0 downto 0);
		begin
			-- iterate over message bytes
			for i in msg'low to msg'high loop
				-- iterate over bits in a single message byte
				for j in msg(i)'high downto msg(i)'low loop
					-- dispatch mode
					if ( DUAL = this.spiMode ) then		--! two bits per clock cycle are transfered
						if ( 0 = (j+1) mod 2 ) then		
							SCK 					<= '0';													--! falling edge
							wait for this.TSpiClk/2;														--! half clock cycle
							SCK 					<= '1';													--! rising edge
							msg(i)(j downto j-1)	:= std_logic_vector(TO_01(unsigned(DIO(1 downto 0))));	--! capture data from line
							wait for this.TSpiClk/2;														--! half clock cycle
						end if;
					elsif ( QUAD = this.spiMode ) then	--! four bits per clock cycle are transfered
						if ( 0 = (j+1) mod 4 ) then		
							SCK 					<= '0';													--! falling edge
							wait for this.TSpiClk/2;														--! half clock cycle
							SCK 					<= '1';													--! rising edge
							msg(i)(j downto j-3)	:= std_logic_vector(TO_01(unsigned(DIO(3 downto 0))));	--! capture data from line
							wait for this.TSpiClk/2;														--! half clock cycle
						end if;
					else								--! one bits per clock cycle are transfered
						SCK 		<= '0';															--! falling edge
						wait for this.TSpiClk/2;													--! half clock cycle
						SCK 				<= '1';													--! rising edge
						slv1(0 downto 0)	:= std_logic_vector(TO_01(unsigned(DIO(1 downto 1))));	--! help
						msg(i)(j)			:= slv1(0);												--! capture data from line
						wait for this.TSpiClk/2;													--! half clock cycle
					end if;
				end loop;
			end loop;
		end procedure spiRx;
		--***************************
		
		
        --***************************
        -- SPI Transceiver procedure
		--   sends command to eSPI slave and captures response
		--   the request is overwritten by the response
		procedure spiXcv
			(
				variable this		: inout tESpiBfm; 
				variable msg		: inout tMemX08;
				signal CSn			: out std_logic; 
				signal SCK 			: out std_logic; 						--! shift clock
				signal DIO 			: inout std_logic_vector(3 downto 0);	--! bidirectional data
				constant lenReq		: in integer;							--! request length of message in bytes
				constant lenRsp		: in integer;							--! response length in bytes
				variable good		: out boolean							--! signals something went wrong
			) is
			variable crcMsg		: tMemX08(0 to msg'length);	--! message with calculated CRC
			variable crcMsgLen	: integer;					--! length of CRC message
		begin
			-- Prepare
			good 					:= true;
			crcMsg(0 to lenReq-1) 	:= msg(0 to lenReq-1);			-- copy request
			crcMsg(lenReq)			:= crc8(crcMsg(0 to lenReq-1));	-- append CRC
			crcMsgLen				:= lenReq + 1;					-- set new message length
			-- print send message to console
			if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:spiXcv:Tx: " & hexStr(crcMsg(0 to crcMsgLen-1)); end if;
			-- start
			CSn	<= '0';											--! enable Slave
			spiTx(this, crcMsg(0 to crcMsgLen-1), SCK, DIO);	--! write to slave
			spiTar(this, SCK, DIO);								--! change direction (write-to-read), two cycles
			spiRx(this, crcMsg(0 to 0), SCK, DIO);				--! read only response field
			while ( WAIT_STATE = decodeRsp(crcMsg(0)) ) loop	--! response ready
				spiRx(this, crcMsg(0 to 0), SCK, DIO);			--! read from slave
			end loop;
			-- check response & fetch pending bytes
			if ( ACCEPT = decodeRsp(crcMsg(0)) ) then				--! command accepted?
				crcMsgLen := lenRsp + 1;							--! response message length
				spiRx(this, crcMsg(1 to crcMsgLen-1), SCK, DIO);	--! read from slave
				-- print receive message to console
				if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:spiXcv:Rx: " & hexStr(crcMsg(0 to crcMsgLen-1)); end if;
				-- copy message
				msg(0 to lenRsp-1) := crcMsg(0 to lenRsp-1);	--! drop CRC
				-- check CRC
				if (not checkCRC(this, crcMsg(0 to crcMsgLen-1))) then
					good := false;
					if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:spiXcv:Rx:CRC failed" severity error; end if;
				end if;
			else
				good 	:= false;
				msg(0)	:= crcMsg(0);
			end if;
			-- Terminate connection to slave
			SCK	<= '0';
			wait for this.TSpiClk/2;	--! half clock cycle
			CSn	<= '1';
			wait for this.TSpiClk;		--! limits CSn bandwidth to SCK
		end procedure spiXcv;
		--***************************
		
	----------------------------------------------
	
	
    ----------------------------------------------
    -- eSPI Slave Management
    ----------------------------------------------

        --***************************
        -- RESET: sends reset sequence to slave
		procedure RESET
			(
				variable this		: inout tESpiBfm; 
				signal CSn			: out std_logic; 
				signal SCK 			: out std_logic; 						--! shift clock
				signal DIO 			: inout std_logic_vector(3 downto 0)	--! bidirectional data
			) is
		begin
			-- user message
			if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:RESET"; end if;
			-- select slave
			CSn	<= '0';
			DIO	<= (others => '1');
			wait for this.TSpiClk/2;
			-- do reset sequence
			for i in 0 to 15 loop
				SCK	<= '1';
				wait for this.TSpiClk/2;
				SCK	<= '0';
				wait for this.TSpiClk/2;
			end loop;
			CSn	<= '1';
			DIO	<= (others => 'Z');
			wait for this.TSpiClk;	--! limits CSn bandwidth to SCK
		end procedure RESET;
		--***************************
	
	
        --***************************
        -- GET_CONFIGURATION w/ status
		--  @see Figure 22: GET_CONFIGURATION Command
		procedure GET_CONFIGURATION 
			( 
				variable this		: inout tESpiBfm; 
				signal CSn			: out std_logic; 
				signal SCK			: out std_logic; 
				signal DIO			: inout std_logic_vector(3 downto 0);
				constant adr		: in std_logic_vector(15 downto 0);
				variable config		: out std_logic_vector(31 downto 0);
				variable status		: out std_logic_vector(15 downto 0);
				variable response	: out tESpiRsp;
				variable good		: inout boolean
			) is
			variable msg	: tMemX08(0 to 6);										--! eSpi message buffer
			variable cfg	: std_logic_vector(config'range) := (others => '0');	--! internal buffer
			variable sts	: std_logic_vector(status'range) := (others => '0');	--! internal buffer
			variable fg		: boolean;												--! signals fail in SPI phy
		begin
			-- build command
			msg 	:= (others => (others => '0'));	--! clear
			msg(0)	:= C_GET_CONFIGURATION;			--! Command
			msg(1)	:= adr(15 downto 8);			--! high byte address
			msg(2)	:= adr(7 downto 0);				--! low byte address
			-- send and get response
				-- spiXcv(this, msg, CSn, SCK, DIO, lenReq, lenRsp, good)
			spiXcv(this, msg, CSn, SCK, DIO, 3, 7, fg);	--! CRC added and checked by transceiver procedure 
			-- process slaves response
			response := decodeRsp(msg(0));						--! signal response
			if ( fg ) then
				config := msg(4) & msg(3) & msg(2) & msg(1);	--! extract and assemble config
				status := msg(6) & msg(5);						--! status
			else
				good := false;
			end if;
		end procedure GET_CONFIGURATION;
		--***************************
		
		
        --***************************
        -- GET_CONFIGURATION w/o status, response
		--   @see Figure 22: GET_CONFIGURATION Command
		procedure GET_CONFIGURATION 
			( 
				variable this	: inout tESpiBfm; 
				signal CSn		: out std_logic; 
				signal SCK		: out std_logic; 
				signal DIO		: inout std_logic_vector(3 downto 0);
				constant adr	: in std_logic_vector(15 downto 0);
				variable config	: out std_logic_vector(31 downto 0);
				variable good	: inout boolean
			) is
			variable sts : std_logic_vector(15 downto 0);	--! wrapper variable for status
			variable rsp : tESpiRsp;
			variable fg	 : boolean := true;					--! state of function good
		begin
			-- get configuration
			GET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, sts, rsp, fg );
			-- in case of no output print to console
			if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;	--! INFO: print status
			-- Function is good?
			if ( not fg ) then
				good := false;
				if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:GET_CONFIGURATION:Slave " & rsp2str(rsp) severity error; end if;
			end if;
		end procedure GET_CONFIGURATION;
		--***************************
		
		
        --***************************
        -- GET_STATUS
		--  @see Figure 20: GET_STATUS Command
		procedure GET_STATUS 
			(
				variable this		: inout tESpiBfm; 
				signal CSn			: out std_logic; 
				signal SCK			: out std_logic; 
				signal DIO			: inout std_logic_vector(3 downto 0);
				variable status 	: out std_logic_vector(15 downto 0);
				variable response	: out tESpiRsp;		
				variable good		: inout boolean
			) is
			variable msg	: tMemX08(0 to 2);	--! eSpi message buffer
			variable fg		: boolean;			--! signals fail in SPI phy
		begin
			-- assemble command
			msg 	:= (others => (others => '0'));	--! clear
			msg(0)	:= C_GET_STATUS;
			-- send and get response
				-- spiXcv(this, msg, CSn, SCK, DIO, lenReq, lenRsp, good)
			spiXcv(this, msg, CSn, SCK, DIO, 1, 3, fg);	--! CRC added and checked by transceiver procedure 
			-- process slaves response
			response := decodeRsp(msg(0));	--! signal response
			if ( fg ) then
				status 	:= msg(2) & msg(1);	--! status
			else
				status	:= (others => '0');
				good 	:= false;
			end if;
		end procedure GET_STATUS;
		--***************************
		
		
        --***************************
        -- GET_STATUS w/o register, prints only to console
		--  @see Figure 20: GET_STATUS Command
		procedure GET_STATUS 
			(
				variable this	: inout tESpiBfm; 
				signal CSn		: out std_logic; 
				signal SCK		: out std_logic; 
				signal DIO		: inout std_logic_vector(3 downto 0);
				variable good	: inout boolean
			) is
			variable fg	 	: boolean := true;					--! state of function good
			variable sts	: std_logic_vector(15 downto 0);	--! needed for stucking
			variable rsp	: tESpiRsp;							--!
		begin
			-- acquire status
				-- GET_STATUS(this, CSn, SCK, DIO, status, response, good)
			GET_STATUS(this, CSn, SCK, DIO, sts, rsp, fg);
			-- in case of no output print to console
			if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;	--! INFO: print status
			-- Slave request good?
			if ( not fg ) then
				good := false;
				if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:GET_STATUS:Slave " & rsp2str(rsp) severity error; end if;
			end if;
		end procedure GET_STATUS;
		--***************************
	----------------------------------------------
	
	
	
    ----------------------------------------------
    -- Memory Read /Write Operation
    ----------------------------------------------
	
        --***************************
        -- Memory write (32bit)
		-- PUT_MEMWR32_SHORT / PUT_NP 
		--  @see Figure 35: Short Peripheral Memory or Short I/O Write Packet Format (Master Initiated only)
		procedure MEMWR32 
			(
				variable this		: inout tESpiBfm; 
				signal CSn			: out std_logic; 
				signal SCK			: out std_logic; 
				signal DIO			: inout std_logic_vector(3 downto 0);
				constant adr 		: in std_logic_vector(31 downto 0);
				constant data		: in tMemX08;		
				variable status 	: out std_logic_vector(15 downto 0);
				variable response	: out tESpiRsp;	
				variable good		: inout boolean
			) is
			variable fg	 		: boolean := true;					--! state of function good
			variable msg		: tMemX08(0 to data'length + 9);	--! 4Byte Address, Length 1Byte, Length/Tag 1Byte, Cycle Type 1Byte, CMD 1Byte, CRC 1Byte
			variable dLenSlv	: std_logic_vector(11 downto 0);	--! needed for 'PUT_MEMWR32_SHORT'
			variable msgLen		: natural := 0;
		begin
			-- prepare
			msg := (others => (others => '0'));											--! init message array
			-- determine instruction type
			if ( (1 = data'length) or (2 = data'length) or (4 = data'length ) ) then	--! PUT_MEMWR32_SHORT; Figure 35: Short Peripheral Memory or Short I/O Write Packet Format (Master Initiated only)
				-- user message
				if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:MEMWR32: PUT_MEMWR32_SHORT"; end if;
				-- build instruction
				dLenSlv	:= std_logic_vector(to_unsigned(data'length - 1, dLenSlv'length));	--! number of bytes
				msg(0)	:= C_PUT_MEMWR32_SHORT & dLenSlv(1 downto 0);
				msgLen	:= msgLen + 1;
			else																		--! PUT_NP; Figure 34: Peripheral Memory Write Packet Format
				-- user message
				if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:MEMWR32: PUT_PC"; end if;
				-- build instruction
				dLenSlv	:= std_logic_vector(to_unsigned(data'length, dLenSlv'length));	--! number of bytes
				msg(0)	:= C_PUT_PC;													--! Posted Completion Command
				msg(1)	:= C_CT_MEMWR32;												--! Memory write with 32Bit
				msg(2)	:= "0000" & dLenSlv(11 downto 8);								--! TAG and Len field
				msg(3)	:= dLenSlv(7 downto 0);											--! Len Field
				msgLen	:= msgLen + 4;
			end if;
			-- add address to message
			msg(msgLen + 0)	:= adr(31 downto 24);
			msg(msgLen + 1)	:= adr(23 downto 16);
			msg(msgLen + 2)	:= adr(15 downto 8);
			msg(msgLen + 3)	:= adr(7 downto 0);
			msgLen			:= msgLen + 4;
			-- fill in data
			msg(msgLen to data'length + msgLen - 1)	:= data;	--! copy data
			msgLen := msgLen + data'length;
			-- send and get response
				-- spiXcv(this, msg, CSn, SCK, DIO, lenReq, lenRsp, good)
			spiXcv(this, msg, CSn, SCK, DIO, msgLen, 3, fg);	--! CRC added and checked by transceiver procedure 
			-- process slaves response
			response := decodeRsp(msg(0));	--! slave response
			if ( fg ) then
				status 	:= msg(2) & msg(1);	--! status
			else
				status	:= (others => '0');
				good 	:= false;
			end if;
		end procedure MEMWR32;
		--***************************
		
		
        --***************************
        -- Memory write (32bit), w/o status/response register, prints it values to console, except only one data word
		-- PUT_MEMWR32_SHORT / PUT_NP 
		--  @see Figure 35: Short Peripheral Memory or Short I/O Write Packet Format (Master Initiated only)
		procedure MEMWR32 
			(
				variable this		: inout tESpiBfm; 
				signal CSn			: out std_logic; 
				signal SCK			: out std_logic; 
				signal DIO			: inout std_logic_vector(3 downto 0);
				constant adr 		: in std_logic_vector(31 downto 0);		--! memory address
				constant data		: in std_logic_vector(7 downto 0);		--! single data word
				variable good		: inout boolean							--! successful 
			) is
			variable dBuf	: tMemX08(0 to 0);
			variable fg	 	: boolean := true;					--! state of function good
			variable sts	: std_logic_vector(15 downto 0);	--! needed for stucking
			variable rsp	: tESpiRsp;							--! decoded slave response
		begin
			-- fill in data
			dBuf(0) := data;
				-- MEMWR32(this, CSn, SCK, DIO, adr, data, status, response, good)
			MEMWR32(this, CSn, SCK, DIO, adr, dBuf, sts, rsp, fg);
			-- Slave request good?
			if ( not fg ) then
				good := false;
				if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:MEMWR32:Slave " & rsp2str(rsp) severity error; end if;
			else
				-- in case of no output print to console
				if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;	--! INFO: print status
			end if;
		end procedure MEMWR32;
		--***************************
		
		
        --***************************
        -- Memory write (32bit), w/o status/response register, prints it values to console, except only one data word
		-- PUT_MEMWR32_SHORT / PUT_NP 
		--  @see Figure 35: Short Peripheral Memory or Short I/O Write Packet Format (Master Initiated only)
		procedure MEMWR32 
			(
				variable this		: inout tESpiBfm; 
				signal CSn			: out std_logic; 
				signal SCK			: out std_logic; 
				signal DIO			: inout std_logic_vector(3 downto 0);
				constant adr 		: in std_logic_vector(31 downto 0);		--! memory address
				constant data		: in tMemX08;							--! multiple data
				variable good		: inout boolean							--! successful 
			) is
			variable fg	 	: boolean := true;					--! state of function good
			variable sts	: std_logic_vector(15 downto 0);	--! needed for stucking
			variable rsp	: tESpiRsp;							--! decoded slave response
		begin
				-- MEMWR32(this, CSn, SCK, DIO, adr, data, status, response, good)
			MEMWR32(this, CSn, SCK, DIO, adr, data, sts, rsp, fg);
			-- Slave request good?
			if ( not fg ) then
				good := false;
				if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:MEMWR32:Slave " & rsp2str(rsp) severity error; end if;
			else
				-- in case of no output print to console
				if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;	--! INFO: print status
			end if;
		end procedure MEMWR32;
		--***************************
		
		
        --***************************
        -- Memory read (32bit)
		-- PUT_MEMRD32_SHORT / PUT_PC 
		--  @see Figure 37: Short Peripheral Memory or Short I/O Read Packet Format (Master Initiated only)
		procedure MEMRD32 
			(
				variable this		: inout tESpiBfm; 
				signal CSn			: out std_logic; 
				signal SCK			: out std_logic; 
				signal DIO			: inout std_logic_vector(3 downto 0);
				constant adr 		: in std_logic_vector(31 downto 0);
				variable data		: out tMemX08;		
				variable status 	: out std_logic_vector(15 downto 0);
				variable response	: out tESpiRsp;	
				variable good		: inout boolean
			) is
			variable fg	 		: boolean := true;					--! state of function good
			variable msg		: tMemX08(0 to data'length + 9);	--! 4Byte Address, Length 1Byte, Length/Tag 1Byte, Cycle Type 1Byte, CMD 1Byte, CRC 1Byte
			variable dataLenSlv	: std_logic_vector(11 downto 0);	--! needed for 'PUT_MEMWR32_SHORT'
			variable msgLen		: integer := 0;
		begin
			-- init
			msg := (others => (others => '0'));
			-- determine instruction type
			if ( (1 = data'length) or (2 = data'length) or (4 = data'length ) ) then	--! CMD: PUT_MEMWR32_SHORT
				-- user message
				if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:MEMRD32: PUT_MEMRD32_SHORT instruction"; end if;
				-- build instruction
				dataLenSlv	:= std_logic_vector(to_unsigned(data'length - 1, dataLenSlv'length));	--! number of bytes
				msg(0)		:= C_PUT_MEMRD32_SHORT & dataLenSlv(1 downto 0);						--! assemble command
				msgLen		:= msgLen + 1;
				msg(1)		:= adr(31 downto 24);
				msg(2)		:= adr(23 downto 16);
				msg(3)		:= adr(15 downto 8);
				msg(4)		:= adr(7 downto 0);
				msgLen		:= msgLen + 4;
			else																		--! CMD: PUT_NP
				--! TODO
			
			
			end if;
			-- send and get response
				-- spiXcv(this, msg, CSn, SCK, DIO, lenReq, lenRsp, good)
			spiXcv(this, msg, CSn, SCK, DIO, msgLen, data'length+3, fg);	--! xByte Data, +1Byte Response, +2Byte Status, CRC added and checked by transceiver procedure 
			-- process slaves response
			response := decodeRsp(msg(0));	--! slave response
			if ( fg ) then
				data 	:= msg(1 to data'length);					--! extract data from message
				status 	:= msg(data'length+2) & msg(data'length+1);	--! status
			else
				status	:= (others => '0');
				good 	:= false;
			end if;
		end procedure MEMRD32;
		--***************************
		
		
        --***************************
        -- Memory read (32bit)
		-- PUT_MEMRD32_SHORT / PUT_PC 
		--  @see Figure 37: Short Peripheral Memory or Short I/O Read Packet Format (Master Initiated only)
		procedure MEMRD32 
			(
				variable this		: inout tESpiBfm; 
				signal CSn			: out std_logic; 
				signal SCK			: out std_logic; 
				signal DIO			: inout std_logic_vector(3 downto 0);
				constant adr 		: in std_logic_vector(31 downto 0);		--! memory address
				variable data		: out std_logic_vector(7 downto 0);		--! single data word
				variable good		: inout boolean							--! successful 
			) is
			variable dBuf	: tMemX08(0 to 0);
			variable fg	 	: boolean := true;					--! state of function good
			variable sts	: std_logic_vector(15 downto 0);	--! needed for stucking
			variable rsp	: tESpiRsp;							--! decoded slave response
		begin
				-- MEMWR32(this, CSn, SCK, DIO, adr, data, status, response, good)
			MEMRD32(this, CSn, SCK, DIO, adr, dBuf, sts, rsp, fg);
			-- Slave request good?
			if ( not fg ) then
				good := false;
				if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:MEMRD32:Slave " & rsp2str(rsp) severity error; end if;
			else
				-- in case of no output print to console
				if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;	--! INFO: print status
			end if;
			-- fill in data
			data := dBuf(0);
		end procedure MEMRD32;
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
			variable msg : tMemX08(0 to 4);	--! eSpi Tx Packet has 5 Bytes for 1Byte data
		begin
			-- entry message
			if ( this.verbose > 1 ) then
				Report "eSpiMasterBfm:IOWR_SHORT";
			end if;
			-- status
			sts := (others => '0');		--! no ero
			-- build & send Command
			msg 	:= (others => (others => '0'));	--! clear
			msg(0)	:= C_PUT_IOWR_SHORT & "01";		--! CMD: short write with one byte
			msg(1)	:= adr(15 downto 8);
			msg(2)	:= adr(7 downto 0);
			msg(3)	:= data;
			msg(4)	:= crc8(msg(0 to 3));
			-- print send message to console
			if ( this.verbose > 1 ) then
				Report "eSpiMasterBfm:IOWR_SHORT:Tx " & hexStr(msg);
			end if;
			-- send command
			CSn	<= '0';
			spiTx(this, msg, SCK, DIO);	--! write to slave, CRC is auto appended
			spiTar(this, SCK, DIO);		--! change direction (write-to-read)
			-- read response
			--   Byte 0: 	Response
			--   Byte 1/2:	Status (STS)
			spiRx(this, msg(0 to 0), SCK, DIO);				--! read only response field
			while ( WAIT_STATE = decodeRsp(msg(0)) ) loop	--! response ready
				spiRx(this, msg(0 to 0), SCK, DIO);			--! read from slave
			end loop;
			-- command accepted
			if ( ACCEPT = decodeRsp(msg(0)) ) then
				spiRx(this, msg(1 to 3), SCK, DIO);	--! read from slave
				-- print receive message to console
				if ( this.verbose > 1 ) then
					Report "eSpiMasterBfm:IOWR_SHORT:Rx " & hexStr(msg(0 to 3));
				end if;
				-- check CRC and assign only in case of valid/disabled CRC
				if ( checkCRC(this, msg(0 to 2)) and (ACCEPT = decodeRsp(msg(0))) ) then
					sts := msg(2) & msg(1);		--! status
				end if;
			else
				if ( this.verbose > 0 ) then
					Report "eSpiMasterBfm:IOWR_SHORT: Command not accepted" severity error;
				end if;
			end if;
			-- decode response
			
			
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
