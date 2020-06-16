--************************************************************************
-- @author:     Andreas Kaeberlein
-- @copyright:  Copyright 2020
-- @credits:    AKAE
--
-- @license:    BSDv3
-- @maintainer: Andreas Kaeberlein
-- @email:      andreas.kaeberlein@web.de
--
-- @file:       eSpiMasterBfm.vhd
-- @note:       VHDL'93
-- @date:       2020-01-04
--
-- @see:        https://www.intel.com/content/dam/support/us/en/documents/software/chipset-software/327432-004_espi_base_specification_rev1.0_cb.pdf
-- @see:        https://github.com/akaeba/eSpiMM
-- @brief:      bus functional model for enhanced SPI (eSPI)
--              provides function to interact with an eSPI
--              slave
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
        type tMemX08 is array (natural range <>) of std_logic_vector (7 downto 0);  --! Byte orientated memory array

        -- SPI transceiver mode
        type tSpiXcvMode is
            (
                SINGLE, --! standard SPI mode, MISO, MOSI
                DUAL,   --! two bidirectional data lines
                QUAD    --! four bidirectional data lines used
            );

        -- SPI Direction
        type tESpiRsp is
            (
                ACCEPT,             --! Command was successfully received
                DEFER,              --! Only valid in response to a PUT_NP
                NON_FATAL_ERROR,    --! The received command had an error with nonfatal severity
                FATAL_ERROR,        --! The received command had a fatal error that prevented the transaction layer packet from being successfully processed
                WAIT_STATE,         --! Adds one byte-time of delay when responding to a transaction on the bus.
                NO_RESPONSE,        --! The response encoding of all 1’s is defined as no response
                NO_DECODE           --! not in eSPI Spec, no decoding possible
            );

        -- Configures the BFM
        type tESpiBfm is record
            TSpiClk     : time;         --! period of spi clk
            crcSlvEna   : boolean;      --! CRC evaluation on Slave is enabled
            spiMode     : tSpiXcvMode;  --! SPI transceiver mode
            sigSkew     : time;         --! defines Signal Skew to prevent timing errors in back-anno
            verbose     : natural;      --! message level; 0: no message, 1: errors, 2: error + warnings
            tiout       : time;         --! time out when master give up an interaction
        end record tESpiBfm;
    -----------------------------


    -----------------------------
    -- Functions (public)
        function crc8 ( msg : in tMemX08 ) return std_logic_vector;                     --! crc8:       calculate crc from a message
        function sts2str ( sts : in std_logic_vector(15 downto 0) ) return string;      --! sts2str:    convert slave status register into a human readable string
    -----------------------------


    -----------------------------
    -- Procedures
        -- init: initializes bus functional model
        procedure init
            (
                variable this   : inout tESpiBfm;                       --! common handle
                signal CSn      : out std_logic;                        --! slave select
                signal SCK      : out std_logic;                        --! shift clock
                signal DIO      : inout std_logic_vector(3 downto 0)    --! bidirectional data
            );

        -- RESET: apply reset sequence
        -- @see Figure 63: In-band RESET Command
        procedure RESET
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0)    --! bidirectional data
            );

        -- GET_CONFIGURATION:
        -- @see Figure 22: GET_CONFIGURATION Command
            -- w/ status
            procedure GET_CONFIGURATION
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;
                    signal SCK          : out std_logic;
                    signal DIO          : inout std_logic_vector(3 downto 0);
                    constant adr        : in std_logic_vector(15 downto 0);     --! config address
                    variable config     : out std_logic_vector(31 downto 0);    --! config data
                    variable status     : out std_logic_vector(15 downto 0);    --! status
                    variable response   : out tESpiRsp                          --! slave response
                );
            -- w/o status, response, regs, instead print to console
            procedure GET_CONFIGURATION
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    constant adr    : in std_logic_vector(15 downto 0);     --! config address
                    variable config : out std_logic_vector(31 downto 0);    --! config data
                    variable good   : inout boolean                         --! procedure state
                );

        -- SET_CONFIGURATION:
        -- @see Figure 23: SET_CONFIGURATION Command
            -- w/ status
            procedure SET_CONFIGURATION
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;
                    signal SCK          : out std_logic;
                    signal DIO          : inout std_logic_vector(3 downto 0);
                    constant adr        : in std_logic_vector(15 downto 0);
                    constant config     : in std_logic_vector(31 downto 0);
                    variable status     : out std_logic_vector(15 downto 0);
                    variable response   : out tESpiRsp
                );
            -- w/o status, response, regs, instead print to console
            procedure SET_CONFIGURATION
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    constant adr    : in std_logic_vector(15 downto 0);
                    constant config : in std_logic_vector(31 downto 0);
                    variable good   : inout boolean
                );

        -- GET_STATUS
        -- @see Figure 20: GET_STATUS Command
            -- w/o any print to console
            procedure GET_STATUS
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;
                    signal SCK          : out std_logic;
                    signal DIO          : inout std_logic_vector(3 downto 0);
                    variable status     : out std_logic_vector(15 downto 0);
                    variable response   : out tESpiRsp
                );
            -- print to console only
            procedure GET_STATUS
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    variable good   : inout boolean
                );

        -- MEMWR32
        --  @see Figure 35: Short Peripheral Memory or Short I/O Write Packet Format (Master Initiated only)
            -- arbitrary number of data bytes, response and status register
            procedure MEMWR32
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;
                    signal SCK          : out std_logic;
                    signal DIO          : inout std_logic_vector(3 downto 0);
                    constant adr        : in std_logic_vector(31 downto 0);     --! memory address
                    constant data       : in tMemX08;                           --! arbitrary number of data bytes
                    variable status     : out std_logic_vector(15 downto 0);    --! slave status
                    variable response   : out tESpiRsp                          --! slave command response
                );
            -- single data byte, w/o response and status register
            procedure MEMWR32
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;
                    signal SCK          : out std_logic;
                    signal DIO          : inout std_logic_vector(3 downto 0);
                    constant adr        : in std_logic_vector(31 downto 0);     --! memory address
                    constant data       : in std_logic_vector(7 downto 0);      --! single data word
                    variable good       : inout boolean                         --! successful?
                );
            -- multiple data bytes, w/o response and status register
            procedure MEMWR32
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;
                    signal SCK          : out std_logic;
                    signal DIO          : inout std_logic_vector(3 downto 0);
                    constant adr        : in std_logic_vector(31 downto 0);     --! memory address
                    constant data       : in tMemX08;                           --! multiple data
                    variable good       : inout boolean                         --! successful
                );

        -- MEMRD32
        --  @see Figure 37: Short Peripheral Memory or Short I/O Read Packet Format (Master Initiated only)
            -- arbitrary number of data bytes, response and status register
            procedure MEMRD32
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;
                    signal SCK          : out std_logic;
                    signal DIO          : inout std_logic_vector(3 downto 0);
                    constant adr        : in std_logic_vector(31 downto 0);     --! memory address
                    variable data       : out tMemX08;                          --! arbitrary number of data bytes
                    variable status     : out std_logic_vector(15 downto 0);    --! slave status
                    variable response   : out tESpiRsp                          --! slave command response
                );
            -- single data byte, w/o response and status register
            procedure MEMRD32
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;
                    signal SCK          : out std_logic;
                    signal DIO          : inout std_logic_vector(3 downto 0);
                    constant adr        : in std_logic_vector(31 downto 0);     --! memory address
                    variable data       : out std_logic_vector(7 downto 0);     --! single data word
                    variable good       : inout boolean                         --! successful
                );

        -- IOWR
        --  @see Figure 26: Master Initiated Short Non-Posted Transaction
            -- arbitrary number (1/2/4 bytes) of data, response and status register
            procedure IOWR
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;
                    signal SCK          : out std_logic;
                    signal DIO          : inout std_logic_vector(3 downto 0);
                    constant adr        : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                    constant data       : in tMemX08;                           --! write data, 1/2/4 Bytes supported
                    variable status     : out std_logic_vector(15 downto 0);    --! slave status
                    variable response   : out tESpiRsp                          --! command response
                );
            -- single data byte, w/o response and status register
            procedure IOWR
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                    constant data   : in std_logic_vector(7 downto 0);      --! single data word
                    variable good   : inout boolean                         --! successful?
                );

        -- IORD
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
            -- arbitrary number (1/2/4 bytes) of data, response and status register
            procedure IORD
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;
                    signal SCK          : out std_logic;
                    signal DIO          : inout std_logic_vector(3 downto 0);
                    signal ALERTn       : in std_logic;                         --! SLAVE requestes service
                    constant adr        : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                    variable data       : out tMemX08;                          --! read data, 1/2/4 Bytes supported
                    variable status     : out std_logic_vector(15 downto 0);    --! slave status
                    variable response   : out tESpiRsp                          --! command response
                );
            -- single data byte, w/o response and status register
            procedure IORD
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    signal ALERTn   : in std_logic;                         --! SLAVE requestes service
                    constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                    variable data   : out std_logic_vector(7 downto 0);     --! single data word
                    variable good   : inout boolean                         --! successful?
                );

        -- VWIREWR
        --  @see Figure 41: Virtual Wire Packet Format, Master Initiated Virtual Wire Transfer
            -- arbitrary number (<64) of vwire data, response and status register
            procedure VWIREWR
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;                        --! slave select
                    signal SCK          : out std_logic;                        --! shift clock
                    signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                    constant vwireIdx   : in tMemX08;                           --! virtual wire index, @see Table 9: Virtual Wire Index Definition
                    constant vwireData  : in tMemX08;                           --! virtual wire data
                    variable status     : out std_logic_vector(15 downto 0);    --! slave status
                    variable response   : out tESpiRsp                          --! slave response to command
                );
            -- single vwire instruction, response and status register
            procedure VWIREWR
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;                        --! slave select
                    signal SCK          : out std_logic;                        --! shift clock
                    signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                    constant vwireIdx   : in std_logic_vector(7 downto 0);      --! virtual wire index, @see Table 9: Virtual Wire Index Definition
                    constant vwireData  : in std_logic_vector(7 downto 0);      --! virtual wire data
                    variable status     : out std_logic_vector(15 downto 0);    --! slave status
                    variable response   : out tESpiRsp                          --! slave response to command
                );
            -- single vwire instruction, w/o response and status register
            procedure VWIREWR
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;                        --! slave select
                    signal SCK          : out std_logic;                        --! shift clock
                    signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                    constant vwireIdx   : in std_logic_vector(7 downto 0);      --! virtual wire index, @see Table 9: Virtual Wire Index Definition
                    constant vwireData  : in std_logic_vector(7 downto 0);      --! virtual wire data
                    variable good       : inout boolean                         --! successful
                );

        -- System Event Virtual Wires
        -- Communication via "VWIREWR"
        --   @see Table 11: System Event Virtual Wires for Index=3
            -- PLTRST
            procedure VW_PLTRST
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;                        --! slave select
                    signal SCK          : out std_logic;                        --! shift clock
                    signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                    constant XPLTRST    : bit;                                  --! active low reset, assert/de-assert
                    variable good       : inout boolean                         --! successful
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
        constant C_PUT_PC               : std_logic_vector(7 downto 0) := "00000000";   --! Put a posted or completion header and optional data.
        constant C_PUT_NP               : std_logic_vector(7 downto 0) := "00000010";   --! Put a non-posted header and optional data.
        constant C_GET_PC               : std_logic_vector(7 downto 0) := "00000001";   --! Get a posted or completion header and optional data.
        constant C_GET_NP               : std_logic_vector(7 downto 0) := "00000011";   --! Get a non-posted header and optional data.
        constant C_PUT_IORD_SHORT       : std_logic_vector(7 downto 2) := "010000";     --! Put a short (1, 2 or 4 bytes) non-posted I/O Read packet.
        constant C_PUT_IOWR_SHORT       : std_logic_vector(7 downto 2) := "010001";     --! Put a short (1, 2 or 4 bytes) non-posted I/O Write packet.
        constant C_PUT_MEMRD32_SHORT    : std_logic_vector(7 downto 2) := "010010";     --! Put a short (1, 2 or 4 bytes) non-posted Memory Read 32 packet.
        constant C_PUT_MEMWR32_SHORT    : std_logic_vector(7 downto 2) := "010011";     --! Put a short (1, 2 or 4 bytes) posted Memory Write 32 packet.
        constant C_PUT_VWIRE            : std_logic_vector(7 downto 0) := "00000100";   --! Put a Tunneled virtual wire packet.
        constant C_GET_VWIRE            : std_logic_vector(7 downto 0) := "00000101";   --! Get a Tunneled virtual wire packet.
        constant C_PUT_OOB              : std_logic_vector(7 downto 0) := "00000110";   --! Put an OOB (Tunneled SMBus) message.
        constant C_GET_OOB              : std_logic_vector(7 downto 0) := "00000111";   --! Get an OOB (Tunneled SMBus) message.
        constant C_PUT_FLASH_C          : std_logic_vector(7 downto 0) := "00001000";   --! Put a Flash Access completion.
        constant C_GET_FLASH_NP         : std_logic_vector(7 downto 0) := "00001001";   --! Get a non-posted Flash Access request.
        constant C_GET_STATUS           : std_logic_vector(7 downto 0) := "00100101";   --! Command initiated by the master to read the status register of the slave.
        constant C_SET_CONFIGURATION    : std_logic_vector(7 downto 0) := "00100010";   --! Command to set the capabilities of the slave as part of the initialization. This is typically done after the master discovers the capabilities of the slave.
        constant C_GET_CONFIGURATION    : std_logic_vector(7 downto 0) := "00100001";   --! Command to discover the capabilities of the slave as part of the initialization.
        constant C_RESET                : std_logic_vector(7 downto 0) := "11111111";   --! In-band RESET command.
        --***************************

        --***************************
        -- Config Register eSpi Slave, Table 20: Slave Registers
        constant C_DEV_IDENT    : std_logic_vector(15 downto 0) := x"0004";     --! Device Identification
        constant C_GEN_CAP_CFG  : std_logic_vector(15 downto 0) := x"0008";     --! General Capabilities and Configurations
        constant C_CH0_CAP_CFG  : std_logic_vector(15 downto 0) := x"0010";     --! Channel 0 Capabilities and Configurations
        constant C_CH1_CAP_CFG  : std_logic_vector(15 downto 0) := x"0020";     --! Channel 1 Capabilities and Configurations
        constant C_CH2_CAP_CFG  : std_logic_vector(15 downto 0) := x"0030";     --! Channel 2 Capabilities and Configurations
        constant C_CH3_CAP_CFG  : std_logic_vector(15 downto 0) := x"0040";     --! Channel 3 Capabilities and Configurations
        --***************************

        --***************************
        -- Response Fields, Table 4: Response Field Encodings
        constant C_ACCEPT           : std_logic_vector(5 downto 0)  := "001000";    --! Command was successfully received
        constant C_DEFER            : std_logic_vector(7 downto 0)  := "00000001";  --! Only valid in response to a PUT_NP
        constant C_NON_FATAL_ERROR  : std_logic_vector(7 downto 0)  := "00000010";  --! The received command had an error with nonfatal severity
        constant C_FATAL_ERROR      : std_logic_vector(7 downto 0)  := "00000011";  --! The received command had a fatal error that prevented the transaction layer packet from being successfully processed
        constant C_WAIT_STATE       : std_logic_vector(7 downto 0)  := "00001111";  --! Adds one byte-time of delay when responding to a transaction on the bus.
        constant C_NO_RESPONSE      : std_logic_vector(7 downto 0)  := "11111111";  --! The response encoding of all 1’s is defined as no response
        --***************************

        --***************************
        -- Cycle Type Encodings, Table 6: Cycle Types
        constant C_CT_MEMRD32       : std_logic_vector(7 downto 0)  := "00000000";  --! 32 bit addressing Memory Read Request. LPC Memory Read and LPC Bus Master Memory Read requests are mapped to this cycle type.
        constant C_CT_MEMRD64       : std_logic_vector(7 downto 0)  := "00000010";  --! 64 bit addressing Memory Read Request. Support of upstream Memory Read 64 is mandatory for eSPI slaves that are bus mastering capable.
        constant C_CT_MEMWR32       : std_logic_vector(7 downto 0)  := "00000001";  --! 32 bit addressing Memory Write Request. LPC Memory Write and LPC Bus Master Memory Write requests are mapped to this cycle type.
        constant C_CT_MEMWR64       : std_logic_vector(7 downto 0)  := "00000011";  --! 64 bit addressing Memory Write Request. Support of upstream Memory Write 64 is mandatory for eSPI slaves that are bus mastering capable.
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Constant BFM Handling
    ----------------------------------------------

        --***************************
        -- Message Levels
        constant C_MSG_ERROR    : integer := 0;
        constant C_MSG_WARN     : integer := 1;
        constant C_MSG_INFO     : integer := 2;
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Functions
    ----------------------------------------------

        --***************************
        -- calc crc
        function crc8 ( msg : in tMemX08 ) return std_logic_vector is
            constant polynom    : std_logic_vector(7 downto 0) := x"07";
            variable remainder  : std_logic_vector(7 downto 0);
        begin
            -- init
            remainder := (others => '0');
            -- calculate crc
            -- SRC: https://barrgroup.com/embedded-systems/how-to/crc-calculation-c-code
            -- iterate over byte messages
            for i in msg'low to msg'high loop
                remainder := remainder xor msg(i);  --! add new message
                -- iterate over bit in byte of message
                for j in msg(i)'high downto msg(i)'low loop
                    if ( '1' = remainder(remainder'left) ) then --! Topbit is one
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
                constant nus    : STRING := " ";
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
            variable str    : string(1 to (msg'length+1)*5+1);  --! 8bit per
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
                    if ( this.verbose > C_MSG_ERROR ) then
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
                ret := ACCEPT;
            elsif ( C_DEFER = response(C_DEFER'range) ) then
                ret := DEFER;
            elsif ( C_NON_FATAL_ERROR = response(C_NON_FATAL_ERROR'range) ) then
                ret := NON_FATAL_ERROR;
            elsif ( C_FATAL_ERROR = response(C_FATAL_ERROR'range) ) then
                ret := FATAL_ERROR;
            elsif ( C_WAIT_STATE = response(C_WAIT_STATE'range) ) then
                ret := WAIT_STATE;
            elsif ( C_NO_RESPONSE = response(C_NO_RESPONSE'range) ) then
                ret := NO_RESPONSE;
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
            variable ret : string(1 to 16) := (others => character(NUL));   --! make empty
        begin
            -- convert
            case rsp is
                when ACCEPT             => ret(1 to 6)  := "ACCEPT";
                when DEFER              => ret(1 to 5)  := "DEFER";
                when NON_FATAL_ERROR    => ret(1 to 15) := "NON_FATAL_ERROR";
                when FATAL_ERROR        => ret(1 to 11) := "FATAL_ERROR";
                when WAIT_STATE         => ret(1 to 10) := "WAIT_STATE";
                when NO_RESPONSE        => ret(1 to 11) := "NO_RESPONSE";
                when NO_DECODE          => ret(1 to 9)  := "NO_DECODE";
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
            ret :=  character(LF) &
                    "     Status           : 0x"    & to_hstring(sts)                                                                                               & character(LF) &
                    "       PC_FREE        : "      & integer'image(to_integer(unsigned(sts(00 downto 00)))) & "       Peripheral Posted/Completion Rx Queue Free"  & character(LF) &
                    "       NP_FREE        : "      & integer'image(to_integer(unsigned(sts(01 downto 01)))) & "       Peripheral Non-Posted Rx Queue Free"         & character(LF) &
                    "       VWIRE_FREE     : "      & integer'image(to_integer(unsigned(sts(02 downto 02)))) & "       Virtual Wire Rx Queue Free"                  & character(LF) &
                    "       OOB_FREE       : "      & integer'image(to_integer(unsigned(sts(03 downto 03)))) & "       OOB Posted Rx Queue Free"                    & character(LF) &
                    "       PC_AVAIL       : "      & integer'image(to_integer(unsigned(sts(04 downto 04)))) & "       Peripheral Posted/Completion Tx Queue Avail" & character(LF) &
                    "       NP_AVAIL       : "      & integer'image(to_integer(unsigned(sts(05 downto 05)))) & "       Peripheral Non-Posted Tx Queue Avail"        & character(LF) &
                    "       VWIRE_AVAIL    : "      & integer'image(to_integer(unsigned(sts(06 downto 06)))) & "       Virtual Wire Tx Queue Avail"                 & character(LF) &
                    "       OOB_AVAIL      : "      & integer'image(to_integer(unsigned(sts(07 downto 07)))) & "       OOB Posted Tx Queue Avail"                   & character(LF) &
                    "       FLASH_C_FREE   : "      & integer'image(to_integer(unsigned(sts(08 downto 08)))) & "       Flash Completion Rx Queue Free"              & character(LF) &
                    "       FLASH_NP_FREE  : "      & integer'image(to_integer(unsigned(sts(09 downto 09)))) & "       Flash Non-Posted Rx Queue Free"              & character(LF) &
                    "       FLASH_C_AVAIL  : "      & integer'image(to_integer(unsigned(sts(12 downto 12)))) & "       Flash Completion Tx Queue Avail"             & character(LF) &
                    "       FLASH_NP_AVAIL : "      & integer'image(to_integer(unsigned(sts(13 downto 13)))) & "       Flash Non-Posted Tx Queue Avail"             & character(LF);
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
                variable this   : inout tESpiBfm;                       --! common handle
                signal CSn      : out std_logic;                        --! slave select
                signal SCK      : out std_logic;                        --! shift clock
                signal DIO      : inout std_logic_vector(3 downto 0)    --! bidirectional data
            ) is
        begin
            -- common handle
            this.TSpiClk    := 50 ns;   --! default clock is 20MHz
            this.crcSlvEna  := false;   --! out of reset is CRC disabled
            this.spiMode    := SINGLE;  --! Default mode, out of reset
            this.sigSkew    := 0 ns;    --! no skew between clock edge and data defined
            this.verbose    := 0;       --! all messages disabled
            this.tiout      := 100 us;  --! 100us master time out for wait
            -- signals
            CSn <= '1';
            SCK <= '0';
            DIO <= (others => 'Z');
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
        --     * response from slave is driven on the I/O[1]
        --   @see: Figure 54: Single I/O Mode
        procedure spiTx
            (
                variable this   : inout tESpiBfm;
                variable msg    : inout tMemX08;
                signal SCK      : out std_logic;                        --! shift clock
                signal DIO      : inout std_logic_vector(3 downto 0)    --! bidirectional data
            ) is
        begin
            -- iterate over message bytes
            for i in msg'low to msg'high loop
                -- iterate over bits in a single message byte
                for j in msg(i)'high downto msg(i)'low loop
                    -- dispatch mode
                    if ( DUAL = this.spiMode ) then     --! two bits per clock cycle are transfered
                        if ( 0 = (j+1) mod 2 ) then
                            SCK             <= '0';     --! falling edge
                            DIO(1 downto 0) <= msg(i)(j downto j-1);
                            wait for this.TSpiClk/2;    --! half clock cycle
                            SCK             <= '1';     --! rising edge
                            wait for this.TSpiClk/2;    --! half clock cycle
                        end if;
                    elsif ( QUAD = this.spiMode ) then  --! four bits per clock cycle are transfered
                        if ( 0 = (j+1) mod 4 ) then
                            SCK             <= '0';     --! falling edge
                            DIO(3 downto 0) <= msg(i)(j downto j-3);
                            wait for this.TSpiClk/2;    --! half clock cycle
                            SCK             <= '1';     --! rising edge
                            wait for this.TSpiClk/2;    --! half clock cycle
                        end if;
                    else                            --! one bits per clock cycle are transfered
                        SCK     <= '0';             --! falling edge
                        DIO(0)  <= msg(i)(j);   --! assign data
                        wait for this.TSpiClk/2;    --! half clock cycle
                        SCK     <= '1';             --! rising edge
                        wait for this.TSpiClk/2;    --! half clock cycle
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
                variable this   : inout tESpiBfm;
                signal SCK      : out std_logic;                        --! shift clock
                signal DIO      : inout std_logic_vector(3 downto 0)    --! bidirectional data
            ) is
        begin
            -- one clock cycle drive high
            SCK     <= '0';                     --! falling edge
            if ( DUAL = this.spiMode ) then     --! two bits per clock cycle are transfered
                DIO <= (others => '1');
            elsif ( QUAD = this.spiMode ) then  --! four bits per clock cycle are transfered
                DIO(1 downto 0) <= (others => '1');
            else                                --! one bits per clock cycle are transfered
                DIO(0)  <= '1';
            end if;
            wait for this.TSpiClk/2;    --! half clock cycle
            SCK     <= '1';             --! rising edge
            wait for this.TSpiClk/2;    --! half clock cycle
            -- one clock cycle tristate
            SCK     <= '0';                     --! falling edge
            if ( DUAL = this.spiMode ) then     --! two bits per clock cycle are transfered
                DIO <= (others => 'Z');
            elsif ( QUAD = this.spiMode ) then  --! four bits per clock cycle are transfered
                DIO(1 downto 0) <= (others => 'Z');
            else                                --! one bits per clock cycle are transfered
                DIO(0)  <= 'Z';
            end if;
            wait for this.TSpiClk/2;    --! half clock cycle
            SCK     <= '1';             --! rising edge
            wait for this.TSpiClk/2;    --! half clock cycle
        end procedure spiTar;
        --***************************


        --***************************
        -- SPI Receive
        --   Single Mode
        --     * eSPI master drives the I/O[0] during command phase
        --     * response from slave is driven on the I/O[1]
        --   @see: Figure 54: Single I/O Mode
        procedure spiRx
            (
                variable this   : inout tESpiBfm;
                variable msg    : inout tMemX08;
                signal SCK      : out std_logic;                        --! shift clock
                signal DIO      : inout std_logic_vector(3 downto 0)    --! bidirectional data
            ) is
            variable slv1   : std_logic_vector(0 downto 0);
        begin
            -- iterate over message bytes
            for i in msg'low to msg'high loop
                -- iterate over bits in a single message byte
                for j in msg(i)'high downto msg(i)'low loop
                    -- dispatch mode
                    if ( DUAL = this.spiMode ) then     --! two bits per clock cycle are transfered
                        if ( 0 = (j+1) mod 2 ) then
                            SCK                     <= '0';                                                 --! falling edge
                            wait for this.TSpiClk/2;                                                        --! half clock cycle
                            SCK                     <= '1';                                                 --! rising edge
                            msg(i)(j downto j-1)    := std_logic_vector(TO_01(unsigned(DIO(1 downto 0))));  --! capture data from line
                            wait for this.TSpiClk/2;                                                        --! half clock cycle
                        end if;
                    elsif ( QUAD = this.spiMode ) then  --! four bits per clock cycle are transfered
                        if ( 0 = (j+1) mod 4 ) then
                            SCK                     <= '0';                                                 --! falling edge
                            wait for this.TSpiClk/2;                                                        --! half clock cycle
                            SCK                     <= '1';                                                 --! rising edge
                            msg(i)(j downto j-3)    := std_logic_vector(TO_01(unsigned(DIO(3 downto 0))));  --! capture data from line
                            wait for this.TSpiClk/2;                                                        --! half clock cycle
                        end if;
                    else                                --! one bits per clock cycle are transfered
                        SCK         <= '0';                                                         --! falling edge
                        wait for this.TSpiClk/2;                                                    --! half clock cycle
                        SCK                 <= '1';                                                 --! rising edge
                        slv1(0 downto 0)    := std_logic_vector(TO_01(unsigned(DIO(1 downto 1))));  --! help
                        msg(i)(j)           := slv1(0);                                             --! capture data from line
                        wait for this.TSpiClk/2;                                                    --! half clock cycle
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
                variable this       : inout tESpiBfm;
                variable msg        : inout tMemX08;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! bidirectional data
                constant numTxByte  : in integer;                           --! request length of message in bytes
                constant numRxByte  : in integer;                           --! response length in bytes
                variable response   : out tESpiRsp                          --! Slaves response to performed request
            ) is
            variable crcMsg     : tMemX08(0 to msg'length); --! message with calculated CRC
            variable crcMsgLen  : integer;                  --! length of CRC message
            variable rsp        : tESpiRsp;                 --! decoded slave response
        begin
            -- Prepare
            crcMsg(0 to numTxByte-1)    := msg(0 to numTxByte-1);          -- copy request
            crcMsg(numTxByte)           := crc8(crcMsg(0 to numTxByte-1)); -- append CRC
            crcMsgLen                   := numTxByte + 1;                  -- set new message length
            -- print send message to console
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:spiXcv:Tx: " & hexStr(crcMsg(0 to crcMsgLen-1)); end if;
            -- start
            CSn <= '0';                                         --! enable Slave
            spiTx(this, crcMsg(0 to crcMsgLen-1), SCK, DIO);    --! write to slave
            spiTar(this, SCK, DIO);                             --! change direction (write-to-read), two cycles
            spiRx(this, crcMsg(0 to 0), SCK, DIO);              --! read only response field
            while ( WAIT_STATE = decodeRsp(crcMsg(0)) ) loop    --! wait for response ready
                spiRx(this, crcMsg(0 to 0), SCK, DIO);          --! read from slave
            end loop;
            rsp := decodeRsp(crcMsg(0));    --! decode response
            -- fetch all pending bytes
            if ( (ACCEPT = rsp) or (DEFER = rsp) ) then     --! command accepted?
                -- determine number of fetched bytes
                if ( ACCEPT = rsp ) then
                    crcMsgLen := numRxByte + 1; --! response message length
                else
                    crcMsgLen := 3 + 1;         --! in defer returns slave status (2Byte) and CRC (1 Byte)
                end if;
                -- fetch pending bytes
                spiRx(this, crcMsg(1 to crcMsgLen-1), SCK, DIO);    --! read from slave
                -- print receive message to console
                if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:spiXcv:Rx: " & hexStr(crcMsg(0 to crcMsgLen-1)); end if;
                -- copy message
                msg(0 to numRxByte-1) := crcMsg(0 to numRxByte-1);    --! drop CRC
                -- check CRC
                if (not checkCRC(this, crcMsg(0 to crcMsgLen-1))) then
                    rsp := NO_RESPONSE; --! Table 4: Response Field Encodings, It is also the default response when fatal CRC error is detected on the command packet; Here: also used for response
                    if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:spiXcv:Rx:CRC failed" severity error; end if;
                end if;
            end if;
            -- release final response
            response := rsp;
            -- Terminate connection to slave
            SCK <= '0';
            wait for this.TSpiClk/2;    --! half clock cycle
            CSn <= '1';
            wait for this.TSpiClk;      --! limits CSn bandwidth to SCK
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
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0)    --! bidirectional data
            ) is
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:RESET"; end if;
            -- select slave
            CSn <= '0';
            DIO <= (others => '1');
            wait for this.TSpiClk/2;
            -- do reset sequence
            for i in 0 to 15 loop
                SCK <= '1';
                wait for this.TSpiClk/2;
                SCK <= '0';
                wait for this.TSpiClk/2;
            end loop;
            CSn <= '1';
            DIO <= (others => 'Z');
            wait for this.TSpiClk;  --! limits CSn bandwidth to SCK
        end procedure RESET;
        --***************************


        --***************************
        -- GET_CONFIGURATION w/ status
        --  @see Figure 22: GET_CONFIGURATION Command
        procedure GET_CONFIGURATION
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;
                signal DIO          : inout std_logic_vector(3 downto 0);
                constant adr        : in std_logic_vector(15 downto 0);
                variable config     : out std_logic_vector(31 downto 0);
                variable status     : out std_logic_vector(15 downto 0);
                variable response   : out tESpiRsp
            ) is
            variable msg    : tMemX08(0 to 6);                                      --! eSpi message buffer
            variable cfg    : std_logic_vector(config'range) := (others => '0');    --! internal buffer
            variable sts    : std_logic_vector(status'range) := (others => '0');    --! internal buffer
            variable rsp    : tESpiRsp;                                             --! Slaves response to performed request
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:GET_CONFIGURATION"; end if;
            -- build command
            msg     := (others => (others => '0')); --! clear
            msg(0)  := C_GET_CONFIGURATION;         --! Command
            msg(1)  := adr(15 downto 8);            --! high byte address
            msg(2)  := adr(7 downto 0);             --! low byte address
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
            spiXcv(this, msg, CSn, SCK, DIO, 3, 7, rsp);    --! CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = rsp ) then
                config := msg(4) & msg(3) & msg(2) & msg(1);    --! extract and assemble config
                status := msg(6) & msg(5);                      --! status
            else
                status  := (others => '0');
                config  := (others => '0');
            end if;
            -- propagate response
            response := rsp;
        end procedure GET_CONFIGURATION;
        --***************************


        --***************************
        -- GET_CONFIGURATION w/o status, response
        --   @see Figure 22: GET_CONFIGURATION Command
        procedure GET_CONFIGURATION
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                constant adr    : in std_logic_vector(15 downto 0);
                variable config : out std_logic_vector(31 downto 0);
                variable good   : inout boolean
            ) is
            variable sts : std_logic_vector(15 downto 0);   --! wrapper variable for status
            variable rsp : tESpiRsp;
        begin
            -- get configuration
            GET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, sts, rsp );
            -- in case of no output print to console
            if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
            -- Function is good?
            if ( ACCEPT /= rsp ) then
                good := false;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:GET_CONFIGURATION:Slave " & rsp2str(rsp) severity error; end if;
            end if;
        end procedure GET_CONFIGURATION;
        --***************************


        --***************************
        -- SET_CONFIGURATION w/ status
        --  @see Figure 23: SET_CONFIGURATION Command
        procedure SET_CONFIGURATION
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;
                signal DIO          : inout std_logic_vector(3 downto 0);
                constant adr        : in std_logic_vector(15 downto 0);
                constant config     : in std_logic_vector(31 downto 0);
                variable status     : out std_logic_vector(15 downto 0);
                variable response   : out tESpiRsp
            ) is
            variable msg    : tMemX08(0 to 6);                                      --! eSpi message buffer
            variable cfg    : std_logic_vector(config'range) := (others => '0');    --! internal buffer
            variable sts    : std_logic_vector(status'range) := (others => '0');    --! internal buffer
            variable rsp    : tESpiRsp;                                             --! Slaves response to performed request
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:SET_CONFIGURATION"; end if;
            -- build command
            msg     := (others => (others => '0')); --! clear
            msg(0)  := C_SET_CONFIGURATION;         --! Command
            -- Address: From MSB to LSB, @see: 327432-004, p. 93
            msg(1)  := adr(15 downto 8);            --! high byte address
            msg(2)  := adr(07 downto 0);            --! low byte address
            -- Data: From LSB to MSB, @see: 327432-004, p. 93
            msg(3)  := config(07 downto 00);        --! new config value
            msg(4)  := config(15 downto 08);
            msg(5)  := config(23 downto 16);
            msg(6)  := config(31 downto 24);
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
            spiXcv(this, msg, CSn, SCK, DIO, 7, 3, rsp);    --! CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = rsp ) then
                status := msg(2) & msg(1);  --! status
            else
                status  := (others => '0');
            end if;
            -- propagate response
            response := rsp;
        end procedure SET_CONFIGURATION;
        --***************************


        --***************************
        -- SET_CONFIGURATION w/o status, response
        --   @see Figure 23: SET_CONFIGURATION Command
        procedure SET_CONFIGURATION
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                constant adr    : in std_logic_vector(15 downto 0);
                constant config : in std_logic_vector(31 downto 0);
                variable good   : inout boolean
            ) is
            variable sts : std_logic_vector(15 downto 0);   --! wrapper variable for status
            variable rsp : tESpiRsp;
        begin
            -- get configuration
            SET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, sts, rsp );
            -- in case of no output print to console
            if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
            -- Slave good?
            if ( ACCEPT /= rsp ) then
                good := false;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:SET_CONFIGURATION:Slave " & rsp2str(rsp) severity error; end if;
            end if;
        end procedure SET_CONFIGURATION;
        --***************************


        --***************************
        -- GET_STATUS
        --  @see Figure 20: GET_STATUS Command
        procedure GET_STATUS
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;
                signal DIO          : inout std_logic_vector(3 downto 0);
                variable status     : out std_logic_vector(15 downto 0);
                variable response   : out tESpiRsp
            ) is
            variable msg    : tMemX08(0 to 2);  --! eSpi message buffer
            variable rsp    : tESpiRsp;         --! Slaves response to performed request
        begin
            -- assemble command
            msg     := (others => (others => '0')); --! clear
            msg(0)  := C_GET_STATUS;
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
            spiXcv(this, msg, CSn, SCK, DIO, 1, 3, rsp); --! CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = rsp ) then
                status  := msg(2) & msg(1); --! status
            else
                status  := (others => '0');
            end if;
            -- propagate response
            response := rsp;
        end procedure GET_STATUS;
        --***************************


        --***************************
        -- GET_STATUS w/o register, prints only to console
        --  @see Figure 20: GET_STATUS Command
        procedure GET_STATUS
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                variable good   : inout boolean
            ) is
            variable fg     : boolean := true;                  --! state of function good
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp    : tESpiRsp;                         --!
        begin
            -- acquire status
                -- GET_STATUS(this, CSn, SCK, DIO, status, response, good)
            GET_STATUS(this, CSn, SCK, DIO, sts, rsp);
            -- in case of no output print to console
            if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
            -- Slave request good?
            if ( ACCEPT /= rsp ) then
                good := false;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:GET_STATUS:Slave " & rsp2str(rsp) severity error; end if;
            end if;
        end procedure GET_STATUS;
        --***************************
    ----------------------------------------------



    ----------------------------------------------
    -- Memory Read / Write Operation
    ----------------------------------------------

        --***************************
        -- Memory write (32bit)
        -- PUT_MEMWR32_SHORT / PUT_NP
        --  @see Figure 35: Short Peripheral Memory or Short I/O Write Packet Format (Master Initiated only)
        procedure MEMWR32
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;
                signal DIO          : inout std_logic_vector(3 downto 0);
                constant adr        : in std_logic_vector(31 downto 0);
                constant data       : in tMemX08;
                variable status     : out std_logic_vector(15 downto 0);
                variable response   : out tESpiRsp
            ) is
            variable msg        : tMemX08(0 to data'length + 9);    --! 4Byte Address, Length 1Byte, Length/Tag 1Byte, Cycle Type 1Byte, CMD 1Byte, CRC 1Byte
            variable dLenSlv    : std_logic_vector(11 downto 0);    --! needed for 'PUT_MEMWR32_SHORT'
            variable msgLen     : natural := 0;                     --! message length can vary
            variable rsp        : tESpiRsp;                         --! Slaves response to performed request
        begin
            -- prepare
            msg := (others => (others => '0'));                                         --! init message array
            -- determine instruction type
            if ( (1 = data'length) or (2 = data'length) or (4 = data'length ) ) then    --! PUT_MEMWR32_SHORT; Figure 35: Short Peripheral Memory or Short I/O Write Packet Format (Master Initiated only)
                -- user message
                if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:MEMWR32: PUT_MEMWR32_SHORT"; end if;
                -- build instruction
                dLenSlv := std_logic_vector(to_unsigned(data'length - 1, dLenSlv'length));  --! number of bytes
                msg(0)  := C_PUT_MEMWR32_SHORT & dLenSlv(1 downto 0);
                msgLen  := msgLen + 1;
            else                                                                        --! PUT_NP; Figure 34: Peripheral Memory Write Packet Format
                -- user message
                if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:MEMWR32: PUT_PC"; end if;
                -- build instruction
                dLenSlv := std_logic_vector(to_unsigned(data'length, dLenSlv'length));  --! number of bytes
                msg(0)  := C_PUT_PC;                                                    --! Posted Completion Command
                msg(1)  := C_CT_MEMWR32;                                                --! Memory write with 32Bit
                msg(2)  := "0000" & dLenSlv(11 downto 8);                               --! TAG and Len field
                msg(3)  := dLenSlv(7 downto 0);                                         --! Len Field
                msgLen  := msgLen + 4;
            end if;
            -- add address to message
            msg(msgLen + 0) := adr(31 downto 24);
            msg(msgLen + 1) := adr(23 downto 16);
            msg(msgLen + 2) := adr(15 downto 8);
            msg(msgLen + 3) := adr(7 downto 0);
            msgLen          := msgLen + 4;
            -- fill in data
            msg(msgLen to data'length + msgLen - 1) := data;    --! copy data
            msgLen := msgLen + data'length;
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
            spiXcv(this, msg, CSn, SCK, DIO, msgLen, 3, response);  --! CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = rsp ) then
                status  := msg(2) & msg(1); --! status
            else
                status  := (others => '0');
            end if;
            -- propagate response
            response := rsp;
        end procedure MEMWR32;
        --***************************


        --***************************
        -- Memory write (32bit), w/o status and response register -> console print, except only one data word
        -- PUT_MEMWR32_SHORT / PUT_NP
        --  @see Figure 35: Short Peripheral Memory or Short I/O Write Packet Format (Master Initiated only)
        procedure MEMWR32
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;
                signal DIO          : inout std_logic_vector(3 downto 0);
                constant adr        : in std_logic_vector(31 downto 0);     --! memory address
                constant data       : in std_logic_vector(7 downto 0);      --! single data word
                variable good       : inout boolean                         --! successful
            ) is
            variable dBuf   : tMemX08(0 to 0);                  --! captures single data word
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp    : tESpiRsp;                         --! decoded slave response
        begin
            -- fill in data
            dBuf(0) := data;
                -- MEMWR32(this, CSn, SCK, DIO, adr, data, status, response)
            MEMWR32(this, CSn, SCK, DIO, adr, dBuf, sts, rsp);
            -- Slave request good?
            if ( ACCEPT /= rsp ) then
                good := false;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:MEMWR32:Slave " & rsp2str(rsp) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
            end if;
        end procedure MEMWR32;
        --***************************


        --***************************
        -- Memory write (32bit), w/o status/response register, prints it values to console, except only one data word
        -- PUT_MEMWR32_SHORT / PUT_NP
        --  @see Figure 35: Short Peripheral Memory or Short I/O Write Packet Format (Master Initiated only)
        procedure MEMWR32
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;
                signal DIO          : inout std_logic_vector(3 downto 0);
                constant adr        : in std_logic_vector(31 downto 0);     --! memory address
                constant data       : in tMemX08;                           --! multiple data
                variable good       : inout boolean                         --! successful
            ) is
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp    : tESpiRsp;                         --! decoded slave response
        begin
                -- MEMWR32(this, CSn, SCK, DIO, adr, data, status, response)
            MEMWR32(this, CSn, SCK, DIO, adr, data, sts, rsp);
            -- Slave request good?
            if ( ACCEPT /= rsp ) then
                good := false;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:MEMWR32:Slave " & rsp2str(rsp) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
            end if;
        end procedure MEMWR32;
        --***************************


        --***************************
        -- Memory read (32bit)
        -- PUT_MEMRD32_SHORT / PUT_PC
        --  @see Figure 37: Short Peripheral Memory or Short I/O Read Packet Format (Master Initiated only)
        procedure MEMRD32
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;
                signal DIO          : inout std_logic_vector(3 downto 0);
                constant adr        : in std_logic_vector(31 downto 0);
                variable data       : out tMemX08;
                variable status     : out std_logic_vector(15 downto 0);
                variable response   : out tESpiRsp
            ) is
            variable msg        : tMemX08(0 to data'length + 9);    --! 4Byte Address, Length 1Byte, Length/Tag 1Byte, Cycle Type 1Byte, CMD 1Byte, CRC 1Byte
            variable dataLenSlv : std_logic_vector(11 downto 0);    --! needed for 'PUT_MEMWR32_SHORT'
            variable msgLen     : integer := 0;                     --! message length can vary
            variable rsp        : tESpiRsp;                         --! Slaves response to performed request
        begin
            -- init
            msg := (others => (others => '0'));
            -- determine instruction type
            if ( (1 = data'length) or (2 = data'length) or (4 = data'length ) ) then    --! CMD: PUT_MEMWR32_SHORT
                -- user message
                if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:MEMRD32: PUT_MEMRD32_SHORT instruction"; end if;
                -- build instruction
                dataLenSlv  := std_logic_vector(to_unsigned(data'length - 1, dataLenSlv'length));   --! number of bytes
                msg(0)      := C_PUT_MEMRD32_SHORT & dataLenSlv(1 downto 0);                        --! assemble command
                msgLen      := msgLen + 1;
                msg(1)      := adr(31 downto 24);
                msg(2)      := adr(23 downto 16);
                msg(3)      := adr(15 downto 8);
                msg(4)      := adr(7 downto 0);
                msgLen      := msgLen + 4;
            else                                                                        --! CMD: PUT_NP
                --! TODO


            end if;
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
            spiXcv(this, msg, CSn, SCK, DIO, msgLen, data'length+3, rsp);   --! xByte Data, +1Byte Response, +2Byte Status, CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = rsp ) then
                data    := msg(1 to data'length);                   --! extract data from message
                status  := msg(data'length+2) & msg(data'length+1); --! status
            else
                status  := (others => '0');
            end if;
            -- propagate response
            response := rsp;
        end procedure MEMRD32;
        --***************************


        --***************************
        -- Memory read (32bit)
        -- PUT_MEMRD32_SHORT / PUT_PC
        --  @see Figure 37: Short Peripheral Memory or Short I/O Read Packet Format (Master Initiated only)
        procedure MEMRD32
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;
                signal DIO          : inout std_logic_vector(3 downto 0);
                constant adr        : in std_logic_vector(31 downto 0);     --! memory address
                variable data       : out std_logic_vector(7 downto 0);     --! single data word
                variable good       : inout boolean                         --! successful?
            ) is
            variable dBuf   : tMemX08(0 to 0);
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp    : tESpiRsp;                         --! decoded slave response
        begin
                -- MEMRD32(this, CSn, SCK, DIO, adr, data, status, response)
            MEMRD32(this, CSn, SCK, DIO, adr, dBuf, sts, rsp);
            -- Slave request good?
            if ( ACCEPT /= rsp ) then
                good := false;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:MEMRD32:Slave " & rsp2str(rsp) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
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
        -- IOWR
        -- PUT_IOWR_SHORT
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IOWR
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;
                signal DIO          : inout std_logic_vector(3 downto 0);
                constant adr        : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                constant data       : in tMemX08;                           --! write data, 1/2/4 Bytes supported
                variable status     : out std_logic_vector(15 downto 0);    --! slave status
                variable response   : out tESpiRsp                          --! command response
            ) is
            variable msg        : tMemX08(0 to data'length + 3);    --! CMD 1Byte, 2Byte Address
            variable msgLen     : natural := 0;                     --! message length can vary
            variable rsp        : tESpiRsp;                         --! Slaves response to performed request
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:IOWR: PUT_IOWR_SHORT"; end if;
            -- check length
            if not ( (1 = data'length) or (2 = data'length) or (4 = data'length ) ) then    --! PUT_IOWR_SHORT; Figure 26: Master Initiated Short Non-Posted Transaction
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:IOWR: data length " & integer'image(data'length) & " unsupported; Only 1/2/4 Bytes allowed" severity error; end if;
                return;         --! leave procedure
            end if;
            -- prepare data packet
            msg     := (others => (others => '0'));                                             --! init message array
            msg(0)  := C_PUT_IOWR_SHORT & std_logic_vector(to_unsigned(data'length - 1, 2));    --! CPUT_IOWR_SHORT w/ 1/2/4 data bytes
            msg(1)  := adr(15 downto 8);
            msg(2)  := adr(7 downto 0);
            msgLen  := msgLen + 3;
            -- fill in data
            msg(msgLen to data'length + msgLen - 1) := data;    --! copy data
            msgLen := msgLen + data'length;
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
            spiXcv(this, msg, CSn, SCK, DIO, msgLen, 3, rsp);   --! CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = rsp ) then
                status  := msg(2) & msg(1); --! status
            else
                status  := (others => '0');
            end if;
            -- propagate response
            response := rsp;
        end procedure IOWR;
        --***************************


        --***************************
        -- IOWR_SHORT, w/o status and response register -> console print, except only one data word
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IOWR
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                constant data   : in std_logic_vector(7 downto 0);      --! single data word
                variable good   : inout boolean                         --! successful?
            ) is
            variable dBuf   : tMemX08(0 to 0);
            variable fg     : boolean := true;                  --! state of function good
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp    : tESpiRsp;                         --! decoded slave response
        begin
            -- fill in data
            dBuf(0) := data;
                -- IOWR( this, CSn, SCK, DIO, adr, data, status, response )
            IOWR( this, CSn, SCK, DIO, adr, dBuf, sts, rsp );
            -- Slave request good?
            if ( ACCEPT /= rsp ) then
                good := false;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:IOWR:Slave " & rsp2str(rsp) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
            end if;
        end procedure IOWR;
        --***************************


        --***************************
        -- IORD
        -- PUT_IORD_SHORT
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IORD
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;
                signal DIO          : inout std_logic_vector(3 downto 0);
                signal ALERTn       : in std_logic;                         --! SLAVE requestes service
                constant adr        : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                variable data       : out tMemX08;                          --! read data, 1/2/4 Bytes supported
                variable status     : out std_logic_vector(15 downto 0);    --! slave status
                variable response   : out tESpiRsp                          --! command response
            ) is
            variable msg        : tMemX08(0 to data'length + 6);    --! +1Byte Response, +3Byte Header, +2Byte Status
            variable rsp        : tESpiRsp;                         --! Slaves response to performed request
            variable rspGetSts  : tESpiRsp;                         --! Slaves response to performed request
            variable tiout      : natural := 0;                     --! tiout counter
            variable sts        : std_logic_vector(15 downto 0);    --! help variable for status
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:IORD: PUT_IORD_SHORT"; end if;
            -- check length
            if not ( (1 = data'length) or (2 = data'length) or (4 = data'length ) ) then    --! PUT_IOWR_SHORT; Figure 26: Master Initiated Short Non-Posted Transaction
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:IORD: data length " & integer'image(data'length) & " unsupported; Only 1/2/4 Bytes allowed" severity error; end if;
                response := FATAL_ERROR;    --! invalid data length used
                return;                     --! leave procedure
            end if;
            -- prepare data packet
            msg     := (others => (others => '0'));                                             --! init message array
            msg(0)  := C_PUT_IORD_SHORT & std_logic_vector(to_unsigned(data'length - 1, 2));    --! CPUT_IORD_SHORT w/ 1/2/4 data bytes
            msg(1)  := adr(15 downto 8);
            msg(2)  := adr(7 downto 0);
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
            spiXcv(this, msg, CSn, SCK, DIO, 3, data'length+3, rsp);    --! CRC added and checked by transceiver procedure
            -- slave has the data?
            if ( ACCEPT = rsp ) then                                --! data is in response
                data    := msg(1 to data'length - 1 + 1);           --! data bytes
                sts     := msg(data'length+2) & msg(data'length+1); --! status register
            elsif ( DEFER = rsp ) then     --! Wait, Figure 25: Deferred Master Initiated Non-Posted Transaction
                -- assemble status
                sts := msg(2) & msg(1); --! status
                -- check for PC_AVAIL, otherwise wait for alert
                while ( sts(4) = '0' ) loop
                    -- user message
                    if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:IORD:DEFER: no PC_AVAIL wait for #ALERT"; end if;
                    -- wait for alert
                    while ( ALERTn /= '0' ) loop
                        wait for this.TSpiClk/8;    --! wait for core
                        tiout := tiout + 1;         --! increment counter
                        if ( tiout > 8 * (this.tiout/this.TSpiClk) ) then
                            rsp := NO_RESPONSE;
                            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:IORD: After DEFER no reponse within " & time'image(this.tiout); end if;
                            exit;
                        end if;
                    end loop;
                    -- check status
                    if ( DEFER = rsp ) then
                        -- GET_STATUS ( this, CSn, SCK, DIO, status, response )
                        GET_STATUS ( this, CSn, SCK, DIO, sts, rspGetSts );     --! check for PC_AVAIL
                        if ( ACCEPT /= rspGetSts ) then
                            rsp := FATAL_ERROR;
                            exit;
                        end if;
                    else
                        exit;
                    end if;
                end loop;
                -- DEFER and PC_AVAIL, fetch data
                if ( DEFER = rsp and sts(4) = '1' ) then
                    -- user message
                    if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:IORD:DEFER: PC_AVAIL "; end if;
                    -- assemble Posted completion message
                    msg     := (others => (others => '0')); --! init message array
                    msg(0)  := C_GET_PC;                    --! request posted completion
                        -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
                    -- numRxByte: +1Byte Response, +3Byte Header, +2Byte Status
                    spiXcv(this, msg, CSn, SCK, DIO, 1, data'length+6, rsp);    --! CRC added and checked by transceiver procedure
                else
                    rsp := FATAL_ERROR;
                end if;
                -- slave has now the data
                if ( ACCEPT = rsp ) then
                    sts     := msg(4 + data'length + 2) & msg(4 + data'length + 1); --! status register
                    data    := msg(4 to data'length + 4 - 1);                       --! @see: Figure 39: Peripheral Memory or I/O Completion With and Without Data Packet Format
                end if;
            else
                sts := (others => '0'); --! invalid
            end if;
            -- propagate response
            response    := rsp;
            status      := sts;
        end procedure IORD;
        --***************************


        --***************************
        -- IORD_SHORT, w/o status and response register -> console print, except only one data word
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IORD
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                signal ALERTn   : in std_logic;                         --! SLAVE requestes service
                constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                variable data   : out std_logic_vector(7 downto 0);     --! single data word
                variable good   : inout boolean                         --! successful?
            ) is
            variable dBuf   : tMemX08(0 to 0);
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp    : tESpiRsp;                         --! decoded slave response
        begin
                -- IORD( this, CSn, SCK, DIO, ALERTn, adr, data, status, response )
            IORD( this, CSn, SCK, DIO, ALERTn, adr, dBuf, sts, rsp );
            -- Slave request good?
            if ( ACCEPT /= rsp ) then
                good := false;
                data := (others => '0');    --! make invalid
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:IORD:Slave " & rsp2str(rsp) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
                -- release data
                data := dBuf(0);
            end if;
        end procedure IORD;
        --***************************

    ----------------------------------------------



    ----------------------------------------------
    -- Virtual Channel Interactions
    ----------------------------------------------

        --***************************
        -- Virtual Wire Channel Write
        -- PUT_VWIRE
        --   @see Figure 41: Virtual Wire Packet Format, Master Initiated Virtual Wire Transfer
        procedure VWIREWR
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;                        --! slave select
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                constant vwireIdx   : in tMemX08;                           --! virtual wire index, @see Table 9: Virtual Wire Index Definition
                constant vwireData  : in tMemX08;                           --! virtual wire data
                variable status     : out std_logic_vector(15 downto 0);    --! slave status
                variable response   : out tESpiRsp                          --! slave response to command
            ) is
            variable msg    : tMemX08(0 to 2*vwireIdx'length + 2);  --! CMD: 1Byte, Wire Count: 1Byte
            variable msgLen : natural := 0;                         --! message length can vary
            variable rsp    : tESpiRsp;                             --! Slaves response to performed request
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:VWIREWR: PUT_VWIRE instruction"; end if;
            -- some checks
            if ( vwireIdx'length /= vwireData'length ) then
                response := FATAL_ERROR;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:VWIREWR: vwireIdx and vwireData needs same length" severity error; end if;
            end if;
            if ( vwireIdx'length > 63 ) then
                response := FATAL_ERROR;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:VWIREWR: maximal length for vwire commands of 64 exceeded" severity error; end if;
            end if;
            -- init
            msg := (others => (others => '0'));
            -- assemble command
            msg(0)  := C_PUT_VWIRE;
            msg(1)  := "00" & std_logic_vector(to_unsigned(vwireIdx'length-1, 6));  --! set length of vwire message, 0-based count
            msgLen  := msgLen+2;
            -- add data
            for i in 0 to vwireIdx'length-1 loop
                msg(2+2*i)      := vwireIdx(i);     --! add index, 2 cause of command
                msg(2+2*i+1)    := vwireData(i);
                msgLen          := msgLen+2;        --! update message length
            end loop;
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
            spiXcv(this, msg, CSn, SCK, DIO, msgLen, 3, rsp);   --! CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = rsp ) then
                status  := msg(2) & msg(1); --! status
            else
                status  := (others => '0');
            end if;
            -- propagate response
            response := rsp;
        end procedure VWIREWR;
        --***************************


        --***************************
        -- Virtual Wire Channel Write, except only one data word
        -- PUT_VWIRE
        --   @see Figure 41: Virtual Wire Packet Format, Master Initiated Virtual Wire Transfer
        procedure VWIREWR
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;                        --! slave select
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                constant vwireIdx   : in std_logic_vector(7 downto 0);      --! virtual wire index, @see Table 9: Virtual Wire Index Definition
                constant vwireData  : in std_logic_vector(7 downto 0);      --! virtual wire data
                variable status     : out std_logic_vector(15 downto 0);    --! slave status
                variable response   : out tESpiRsp                          --! slave response to command
            ) is
            variable idx    : tMemX08(0 to 0);  --! vwireIdx
            variable data   : tMemX08(0 to 0);  --! vwireData
        begin
            -- fill in data
            idx(0)  := vwireIdx;
            data(0) := vwireData;
            -- call more general function
                -- VWIREWR( this, CSn, SCK, DIO, vwireIdx, vwireData, status, response );
            VWIREWR( this, CSn, SCK, DIO, idx, data, status, response );
        end procedure VWIREWR;
        --***************************


        --***************************
        -- Virtual Wire Channel Write, w/o status/response register, prints it values to console, except only one data word
        -- PUT_VWIRE
        --   @see Figure 41: Virtual Wire Packet Format, Master Initiated Virtual Wire Transfer
        procedure VWIREWR
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;                        --! slave select
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                constant vwireIdx   : in std_logic_vector(7 downto 0);      --! virtual wire index, @see Table 9: Virtual Wire Index Definition
                constant vwireData  : in std_logic_vector(7 downto 0);      --! virtual wire data
                variable good       : inout boolean                         --! successful
            ) is
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp    : tESpiRsp;                         --! decoded slave response
        begin
            -- call more general function
                -- VWIREWR( this, CSn, SCK, DIO, vwireIdx, vwireData, status, response );
            VWIREWR( this, CSn, SCK, DIO, vwireIdx, vwireData, sts, rsp );
            -- Slave response good?
            if ( ACCEPT /= rsp ) then
                good := false;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:VWIREWR:Slave " & rsp2str(rsp) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
            end if;
        end procedure VWIREWR;
        --***************************

    ----------------------------------------------



    ----------------------------------------------
    -- System Event Virtual Wires
    ----------------------------------------------

        --***************************
        -- Vitual Wire: Manipulate PLTRST level
        -- Platform Reset: Command to indicate Platform Reset assertion and de-assertion.
        --   @see Table 11: System Event Virtual Wires for Index=3
        procedure VW_PLTRST
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;                        --! slave select
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                constant XPLTRST    : bit;                                  --! active low reset, assert/de-assert
                variable good       : inout boolean                         --! successful
            ) is
                variable vwData : std_logic_vector(7 downto 0);             --! Modifier of PLTRST
        begin
            -- assert/deassert reset?
            if ( XPLTRST = '0' ) then   -- assert
                -- user message
                if ( this.verbose > C_MSG_INFO ) then
                    Report "eSpiMasterBfm:VW_PLTRST: XPLTRST = 0";
                end if;
                -- prepare data
                vwData := x"11";    --! activate PLTRST#, activate SUS_STAT#
            else                        -- deassert
                -- user message
                if ( this.verbose > C_MSG_INFO ) then
                    Report "eSpiMasterBfm:VW_PLTRST: XPLTRST = 1";
                end if;
                -- prepare data
                vwData := x"22";    --! deactivate PLTRST#, deactivate SUS_STAT#
            end if;
            -- perform command
                -- VWIREWR ( this, CSn, SCK, DIO, vwireIdx, vwireData, good );
            VWIREWR ( this, CSn, SCK, DIO, x"03", vwData, good );
        end procedure VW_PLTRST;
        --***************************

    ----------------------------------------------

end package body eSpiMasterBfm;
--------------------------------------------------------------------------
