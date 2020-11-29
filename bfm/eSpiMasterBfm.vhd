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
-- @see:        https://github.com/akaeba/eSpiMasterBfm
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
-- eSpiMasterBfm: eSPI Master Bus functional model package
package eSpiMasterBfm is

    -----------------------------
    -- Typs
        -- Arrays
        type tMemX08 is array (natural range <>) of std_logic_vector (7 downto 0);  --! Byte orientated memory array
        type slv16 is array (natural range <>) of std_logic_vector (15 downto 0);   --! unconstrained array
        type tintx is array (natural range <>) of integer;                          --!

        -- System Event Virtual Wires
        --   resolved index to name, required by print
        type tSysEventName is array(2 to 7, 0 to 3) of string(1 to 22);

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
            tioutAlert  : natural;      --! number of clock cycles before BFM gives with time out up
            tioutRd     : natural;      --! number of Get Status Cycles before data read gives up
            alertMode   : boolean;      --! True: ALERT# pin for alert signaling used, False: DIO[1] signals alert
        end record tESpiBfm;
    -----------------------------


    -----------------------------
    -- Functions (public)
        function crc8 ( msg : in tMemX08 ) return std_logic_vector; --! crc8: calculate crc from a message
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
            -- w/o status, response, regs, instead prints direct to log
            procedure GET_CONFIGURATION
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    constant adr    : in std_logic_vector(15 downto 0);     --! config address
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
            -- w/o status, response
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
            -- data byte, w/o response and status register
            procedure IOWR_BYTE
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                    constant data   : in std_logic_vector(7 downto 0);      --! data byte
                    variable good   : inout boolean                         --! successful?
                );
            -- data word, w/o response and status register
            procedure IOWR_WORD
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                    constant data   : in std_logic_vector(15 downto 0);     --! data word
                    variable good   : inout boolean                         --! successful?
                );
            -- dual data word, w/o response and status register
            procedure IOWR_DWORD
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                    constant data   : in std_logic_vector(31 downto 0);     --! dual data word
                    variable good   : inout boolean                         --! successful?
                );
            -- Default IOWR is byte orientated access
            -- data byte, w/o response and status register
            procedure IOWR
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                    constant data   : in std_logic_vector(7 downto 0);      --! data byte
                    variable good   : inout boolean                         --! successful?
                );

        -- IORD
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
            -- data byte, w/o response and status register
            procedure IORD_BYTE
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                    variable data   : out std_logic_vector(7 downto 0);     --! single data byte
                    variable good   : inout boolean                         --! successful?
                );
            -- data word, w/o response and status register
            procedure IORD_WORD
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                    variable data   : out std_logic_vector(15 downto 0);    --! data word
                    variable good   : inout boolean                         --! successful?
                );
            -- data dual word, w/o response and status register
            procedure IORD_DWORD
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                    variable data   : out std_logic_vector(31 downto 0);    --! data dual word
                    variable good   : inout boolean                         --! successful?
                );
            -- Default IORD is byte orientated access
            -- data byte, w/o response and status register
            procedure IORD
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;
                    signal SCK      : out std_logic;
                    signal DIO      : inout std_logic_vector(3 downto 0);
                    constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                    variable data   : out std_logic_vector(7 downto 0);     --! data byte
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
            -- single vwire instruction, wire via name selected, see "System Event Virtual Wires" in spec or 'C_SYSEVENT_NAME' in bfm
            procedure VWIREWR
                (
                    variable this   : inout tESpiBfm;
                    signal CSn      : out std_logic;                        --! slave select
                    signal SCK      : out std_logic;                        --! shift clock
                    signal DIO      : inout std_logic_vector(3 downto 0);   --! data lines
                    constant name   : in string;                            --! Virtual wire name
                    constant value  : in bit;                               --! virtual wire value
                    variable good   : inout boolean                         --! successful
                );

        -- VWIRERD
        --  @see Figure 41: Virtual Wire Packet Format, Master Initiated Virtual Wire Transfer
            -- arbitrary number (<64) of vwire data, response and status register
            procedure VWIRERD
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;                        --! slave select
                    signal SCK          : out std_logic;                        --! shift clock
                    signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                    variable vwireIdx   : out tMemX08(0 to 63);                 --! virtual wire index, @see Table 9: Virtual Wire Index Definition, max. 64 virtual wires
                    variable vwireData  : out tMemX08(0 to 63);                 --! virtual wire data
                    variable vwireLen   : out integer range 0 to 64;            --! number of wire pairs
                    variable status     : out std_logic_vector(15 downto 0);    --! slave status
                    variable response   : out tESpiRsp                          --! slave response to command
                );
            -- read wires, print to console only
            procedure VWIRERD
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;                        --! slave select
                    signal SCK          : out std_logic;                        --! shift clock
                    signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                    variable good       : inout boolean                         --! successful
                );

        -- Virtual Wires Helper
            -- VW_ADD: adds based on string virtual wire entry to list
            procedure VW_ADD
                (
                    variable this   : inout tESpiBfm;   --! common storage element
                    constant name   : in string;        --! Virtual wire name
                    constant value  : in bit;           --! virtual wire value
                    variable vwIdx  : inout tMemX08;    --! list with virtual wire indexes
                    variable vwData : inout tMemX08;    --! list with virtual wire data
                    variable vwLen  : inout natural;    --! effective list length
                    variable good   : inout boolean     --! successful
                );

        -- Virtual Wire: Waits until is equal
        --   waits until a virtual wire has the given value
        --   @see Table 9: Virtual Wire Index Definition
            procedure WAIT_VW_IS_EQ
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;                        --! slave select
                    signal SCK          : out std_logic;                        --! shift clock
                    signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                    signal ALERTn       : in std_logic;                         --! Alert
                    constant wireName   : in string;                            --! name of the virtual wire
                    constant wireVal    : in bit;                               --! value of the virtual wire
                    variable good       : inout boolean                         --! successful?
                );

        -- Print: Slave Configuration Registers to Console Log
            procedure PRT_CFG_REGS
                (
                    variable this       : inout tESpiBfm;
                    signal CSn          : out std_logic;                        --! slave select
                    signal SCK          : out std_logic;                        --! shift clock
                    signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                    variable good       : inout boolean                         --! successful
                );

    -----------------------------

end package eSpiMasterBfm;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- eSpiMasterBfmPKG: eSPI Master Bus functional model package
package body eSpiMasterBfm is

    ----------------------------------------------
    -- Constant BFM Handling
    ----------------------------------------------

        --***************************
        -- Message Levels
        constant C_MSG_ERROR    : integer := 0;
        constant C_MSG_WARN     : integer := 1;
        constant C_MSG_INFO     : integer := 2;
        --***************************


        --***************************
        -- Time-out
        constant C_TIOUT_CYC_ALERT  : integer := 100;   --! number of clock cycles before BFM gives with time out up
        constant C_TIOUT_CYC_RD     : integer := 20;    --! number of status retries for read completion before BFM gives uo
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Early Help Functions
    --   f.e. needed for constant initialization
    ----------------------------------------------

        --***************************
        -- padStr
        --   creates an string with a fixed length, padded with NUL
        function padStr ( str : in string; pad : in character; len : in positive ) return string is
            variable padedStr : string(1 to len);
        begin
            -- pad with null
            padedStr := (others => pad);
            -- check length
            if ( str'length < len ) then
                padedStr(1 to str'length) := str;
            else
                padedStr := str(1 to str'length);
            end if;
            return padedStr;
        end function padStr;
        --***************************

    ----------------------------------------------


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
        constant C_CT_MEMRD32           : std_logic_vector(7 downto 0)  := "00000000";  --! 32 bit addressing Memory Read Request. LPC Memory Read and LPC Bus Master Memory Read requests are mapped to this cycle type.
        constant C_CT_MEMRD64           : std_logic_vector(7 downto 0)  := "00000010";  --! 64 bit addressing Memory Read Request. Support of upstream Memory Read 64 is mandatory for eSPI slaves that are bus mastering capable.
        constant C_CT_MEMWR32           : std_logic_vector(7 downto 0)  := "00000001";  --! 32 bit addressing Memory Write Request. LPC Memory Write and LPC Bus Master Memory Write requests are mapped to this cycle type.
        constant C_CT_MEMWR64           : std_logic_vector(7 downto 0)  := "00000011";  --! 64 bit addressing Memory Write Request. Support of upstream Memory Write 64 is mandatory for eSPI slaves that are bus mastering capable.
        constant C_CT_MSG               : std_logic_vector(7 downto 0)  := "000---00";  --! Message Request.
        constant C_CT_MSG_W_DAT         : std_logic_vector(7 downto 0)  := "000---01";  --! Message Request with data payload.
        constant C_CT_CPL_OK_WO_DAT     : std_logic_vector(7 downto 0)  := "00000110";  --! Successful Completion Without Data. Corresponds to I/O Write.
        constant C_CT_CPL_OK_W_DAT      : std_logic_vector(7 downto 0)  := "00001--1";  --! Successful Completion With Data. Corresponds to Memory Read or I/O Read.
        constant C_CT_CPL_FAIL_W_DAT    : std_logic_vector(7 downto 0)  := "00001--0";  --! Unsuccessful Completion Without Data. Corresponds to Memory or I/O.
        --***************************

        --***************************
        -- Status Register, Figure 16: Slave’s Status Register Definition
        constant C_STS_PC_FREE          : integer := 0;     --! Peripheral Posted/Completion Rx Queue Free
        constant C_STS_NP_FREE          : integer := 1;     --! Peripheral Non-Posted Rx Queue Free
        constant C_STS_VWIRE_FREE       : integer := 2;     --! Virtual Wire Rx Queue Free
        constant C_STS_OOB_FREE         : integer := 3;     --! OOB Posted Rx Queue Free
        constant C_STS_PC_AVAIL         : integer := 4;     --! Peripheral Posted/Completion Tx Queue Avail
        constant C_STS_NP_AVAIL         : integer := 5;     --! Peripheral Non-Posted Tx Queue Avail
        constant C_STS_VWIRE_AVAIL      : integer := 6;     --! Virtual Wire Tx Queue Avail
        constant C_STS_OOB_AVAIL        : integer := 7;     --! OOB Posted Tx Queue Avail
        constant C_STS_FLASH_C_FREE     : integer := 8;     --! Flash Completion Rx Queue Free
        constant C_STS_FLASH_NP_FREE    : integer := 9;     --! Flash Non-Posted Rx Queue Free
        constant C_STS_FLASH_C_AVAIL    : integer := 12;    --! Flash Completion Tx Queue Avail
        constant C_STS_FLASH_NP_AVAIL   : integer := 13;    --! Flash Non-Posted Tx Queue Avail
        --***************************

        --***************************
        -- System Event Wires
        --  @see 5.2.2.2 System Event Virtual Wires
        --  @ https://stackoverflow.com/questions/17160878/how-to-declare-two-dimensional-arrays-and-their-elements-in-vhdl/17161967
        constant C_SYSEVENT_NAME : tSysEventName := (   (padStr("SLP_S3#",              ' ', 22), padStr("SLP_S4#",     ' ', 22), padStr("SLP_S5#",        ' ', 22), padStr("RSV",                    ' ', 22)),
                                                        (padStr("SUS_STAT#",            ' ', 22), padStr("PLTRST#",     ' ', 22), padStr("OOB_RST_WARN",   ' ', 22), padStr("RSV",                    ' ', 22)),
                                                        (padStr("OOB_RST_ACK",          ' ', 22), padStr("RSV",         ' ', 22), padStr("WAKE#",          ' ', 22), padStr("PME#",                   ' ', 22)),
                                                        (padStr("SLAVE_BOOT_LOAD_DONE", ' ', 22), padStr("ERROR_FATAL", ' ', 22), padStr("ERROR_NONFATAL", ' ', 22), padStr("SLAVE_BOOT_LOAD_STATUS", ' ', 22)),
                                                        (padStr("SCI#",                 ' ', 22), padStr("SMI#",        ' ', 22), padStr("RCIN#",          ' ', 22), padStr("HOST_RST_ACK",           ' ', 22)),
                                                        (padStr("HOST_RST_WARN",        ' ', 22), padStr("SMIOUT#",     ' ', 22), padStr("NMIOUT#",        ' ', 22), padStr("RSV",                    ' ', 22))
                                                    );
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
            -- @see: https://barrgroup.com/embedded-systems/how-to/crc-calculation-c-code
            -- @see: https://crccalc.com
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
        end function crc8;
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
        -- upper
        --   converts upper/lower letters to upper letters only
        function upper
            (
                constant str : in string    --! mixed letter string
            ) return string is
            variable upperStr   : string(str'range);    --! converted upper string
            variable intChar    : integer;              --! to character corresponding integer
        begin
            for i in str'range loop
                intChar := character'pos(character(str(i)));
                -- lower characters in ASCII table
                --   @see: http://www.asciitable.com
                if ( (intChar >= 97) and (intChar <= 122) ) then
                    intChar := intChar - 32;    --! make upper
                end if;
                upperStr(i) := character'val(intChar);
            end loop;
            return upperStr;
        end function upper;
        --***************************


        --***************************
        -- trim
        --   removes leading/trailing blanks from string
        function trim
            (
                constant str : in string    --! input string
            ) return string is
            variable strStart   : positive;
            variable strStop    : positive;
            variable trimStr    : string(1 to str'length);
        begin
            -- init
            strStart    := str'left;
            strStop     := str'right;
            -- determine leading blank index
            for i in str'left to str'right loop
                if ( character(' ') /= str(i) ) then
                    strStart := i;
                    exit;
                end if;
            end loop;
            -- determine trailing blank indexes
            for i in str'right downto strStart loop
                if ( character(' ') /= str(i) ) then
                    strStop := i;
                    exit;
                end if;
            end loop;
            -- empty string
            if ( strStop = strStart ) then
                return "";
            end if;
            -- assemble result string
            trimStr(1 to (strStop-strStart)+1) := str(strStart to strStop);
            return trimStr(1 to (strStop-strStart)+1);
        end function trim;
        --***************************


        --***************************
        -- match
        --   returns true if string matches
        function match
            (
                constant str1 : in string;  --! input string 1
                constant str2 : in string   --! input string 2
            ) return boolean is
            constant cStr1 : string := trim(str1);
            constant cStr2 : string := trim(str2);
        begin
            -- same length?
            if ( cStr1'length /= cStr2'length ) then
                return false;
            end if;
            -- match?
            if ( upper(cStr1) = upper(cStr2) ) then
                return true;
            end if;
            -- no match
            return false;
        end function match;
        --***************************


        --***************************
        -- hexStr
        --   converts byte array into hexadecimal string
        function hexStr ( msg : in tMemX08 ) return string is
            variable str : string(1 to (msg'length+1)*5+1);  --! 8bit per
        begin
            -- init
            str := (others => NUL);
            -- build hex value
            for i in 0 to msg'length-1 loop
                str(i*5+1 to i*5+5) := "0x" & to_hstring(msg(i)) & " ";
            end loop;
            -- return
            return str(1 to (msg'length-1)*5+4);    --! +4 drops last blank
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
        -- ct2str
        --   print decoded cycle type in human readable form to string
        function ct2str ( ct : std_logic_vector(7 downto 0) ) return string is
            variable ret : string(1 to 50) := (others => character(NUL));   --! make empty
            variable len : integer;                                         --! shorts string to allow concat w/o print abort
        begin
            -- convert
            if ( std_match(ct, C_CT_MEMRD32) ) then
                len             := 7;
                ret(1 to len)   := "MEMRD32";
            elsif ( std_match(ct, C_CT_MEMRD64) ) then
                len             := 7;
                ret(1 to len)   := "MEMRD64";
            elsif ( std_match(ct, C_CT_MEMWR32) ) then
                len             := 7;
                ret(1 to len)   := "MEMWR32";
            elsif ( std_match(ct, C_CT_MEMWR64) ) then
                len             := 7;
                ret(1 to len)   := "MEMWR64";
            elsif ( std_match(ct, C_CT_MSG) ) then
                len             := 7;
                ret(1 to len)   := "Message";
            elsif ( std_match(ct, C_CT_MSG_W_DAT) ) then
                len             := 17;
                ret(1 to len)   := "Message with Data";
            elsif ( std_match(ct, C_CT_CPL_OK_WO_DAT) ) then
                len             := 34;
                ret(1 to len)   := "Successful Completion Without Data";
            elsif ( std_match(ct, C_CT_CPL_OK_W_DAT) ) then
                len             := 31;
                ret(1 to len)   := "Successful Completion With Data";
            elsif ( std_match(ct, C_CT_CPL_FAIL_W_DAT) ) then
                len             := 36;
                ret(1 to len)   := "Unsuccessful Completion Without Data";
            else
                ret(1 to 7) := "UNKNOWN";
                len         := 7;
            end if;
            -- release
            return ret(1 to len);
        end function ct2str;
        --***************************


        --***************************
        -- sts2str
        --   print status register to string in a human-readable way
        function sts2str ( sts : in std_logic_vector(15 downto 0) ) return string is
            variable ret : string(1 to 807);
        begin
            -- convert
            ret :=  character(LF) &
                    "     Status           : 0x"    & to_hstring(sts)                                                                                                                                   & character(LF) &
                    "       PC_FREE        : "      & integer'image(to_integer(unsigned(sts(C_STS_PC_FREE        downto C_STS_PC_FREE))))        & "       Peripheral Posted/Completion Rx Queue Free"  & character(LF) &
                    "       NP_FREE        : "      & integer'image(to_integer(unsigned(sts(C_STS_NP_FREE        downto C_STS_NP_FREE))))        & "       Peripheral Non-Posted Rx Queue Free"         & character(LF) &
                    "       VWIRE_FREE     : "      & integer'image(to_integer(unsigned(sts(C_STS_VWIRE_FREE     downto C_STS_VWIRE_FREE))))     & "       Virtual Wire Rx Queue Free"                  & character(LF) &
                    "       OOB_FREE       : "      & integer'image(to_integer(unsigned(sts(C_STS_OOB_FREE       downto C_STS_OOB_FREE))))       & "       OOB Posted Rx Queue Free"                    & character(LF) &
                    "       PC_AVAIL       : "      & integer'image(to_integer(unsigned(sts(C_STS_PC_AVAIL       downto C_STS_PC_AVAIL))))       & "       Peripheral Posted/Completion Tx Queue Avail" & character(LF) &
                    "       NP_AVAIL       : "      & integer'image(to_integer(unsigned(sts(C_STS_NP_AVAIL       downto C_STS_NP_AVAIL))))       & "       Peripheral Non-Posted Tx Queue Avail"        & character(LF) &
                    "       VWIRE_AVAIL    : "      & integer'image(to_integer(unsigned(sts(C_STS_VWIRE_AVAIL    downto C_STS_VWIRE_AVAIL))))    & "       Virtual Wire Tx Queue Avail"                 & character(LF) &
                    "       OOB_AVAIL      : "      & integer'image(to_integer(unsigned(sts(C_STS_OOB_AVAIL      downto C_STS_OOB_AVAIL))))      & "       OOB Posted Tx Queue Avail"                   & character(LF) &
                    "       FLASH_C_FREE   : "      & integer'image(to_integer(unsigned(sts(C_STS_FLASH_C_FREE   downto C_STS_FLASH_C_FREE))))   & "       Flash Completion Rx Queue Free"              & character(LF) &
                    "       FLASH_NP_FREE  : "      & integer'image(to_integer(unsigned(sts(C_STS_FLASH_NP_FREE  downto C_STS_FLASH_NP_FREE))))  & "       Flash Non-Posted Rx Queue Free"              & character(LF) &
                    "       FLASH_C_AVAIL  : "      & integer'image(to_integer(unsigned(sts(C_STS_FLASH_C_AVAIL  downto C_STS_FLASH_C_AVAIL))))  & "       Flash Completion Tx Queue Avail"             & character(LF) &
                    "       FLASH_NP_AVAIL : "      & integer'image(to_integer(unsigned(sts(C_STS_FLASH_NP_AVAIL downto C_STS_FLASH_NP_AVAIL)))) & "       Flash Non-Posted Tx Queue Avail";
            -- release
            return ret;
        end function sts2str;
        --***************************


        --***************************
        -- vw2str
        --   prints virtual wires in a human-readable way
        function vw2str
            (
                constant idx    : in tMemX08;   --! slv array of virtual wire indexes
                constant data   : in tMemX08;   --! slv array of virtual wire data
                constant len    : in natural    --! array number of elements
            )
        return string is
            constant nameLen    : natural           := C_SYSEVENT_NAME(C_SYSEVENT_NAME'low, C_SYSEVENT_NAME'low)'length;    --! get string length for memory allocation
            constant blankPad   : string(1 to 7)    := "       ";                       --! blanks for entry alignment
            constant lineLen    : natural           := nameLen + blankPad'length + 5;   --! str + ' : x' + NL
            variable str        : string(1 to 4*len*lineLen + 32);                      --! 4: if system event wire, in one data are up to 4 wires encoded, +32 in case of len=0
            variable strLen     : natural;                                              --! used number of characters
            variable index      : integer;                                              --! idx converted to integer
        begin
            -- init
            str     := (others => (character(NUL)));
            strLen  := 0;
            -- wires available
            if ( 0 = len ) then
                strLen              := 31;
                str(1 to strLen)    := "     No virtual wires available";
                return str(1 to strLen);
            end if;
            -- process IRQ as events
            for i in 0 to len-1 loop
                -- slv as integer needed
                index := to_integer(unsigned(idx(i)));
                -- IRQ event
                --   @see Table 9: Virtual Wire Index Definition
                if ( (0 <= index) and (index <= 1) ) then
                    -- assemble IRQ String
                    str(strLen+1 to strLen+lineLen) := blankPad                                                                                                         &
                                                       padstr("IRQ" & integer'image(to_integer(unsigned(data(i)(data(0)'left-1 downto data(0)'right)))) , ' ', nameLen) &
                                                       " : "        & integer'image(to_integer(unsigned(data(i)(data(0)'left downto data(0)'left))))                    &
                                                       character(LF);
                    strLen := strLen + lineLen;
                end if;
            end loop;
            -- process virtual wires
            for i in 0 to len-1 loop
                -- slv as integer needed
                index := to_integer(unsigned(idx(i)));
                -- check index for system event
                if ( (C_SYSEVENT_NAME'low <= index) and (index <= C_SYSEVENT_NAME'high) ) then
                    -- iterate over bits of system event
                    for j in C_SYSEVENT_NAME'range(2) loop
                        -- valid?
                        --   @see Table 9: Virtual Wire Index Definition
                        if ( '1' = data(i)(j+4) ) then
                            str(strLen+1 to strLen+lineLen) := blankPad & C_SYSEVENT_NAME(index,j) & " : "              &
                                                               integer'image(to_integer(unsigned(data(i)(j downto j)))) &
                                                               character(LF);
                            strLen := strLen + lineLen;
                        end if;
                    end loop;
                end if;
            end loop;
            return str(1 to strLen-1);  --! drop last line feed
        end function vw2str;
        --***************************


        --***************************
        -- newVW
        --   creates virtual wire index/value pair based on name/value
        --   returns array with virtual wire index (idx0) and data (idx1)
        function newVW
            (
                constant name   : in string;    --! virtual wire name
                constant value  : in bit        --! virtual wire value
            ) return tMemX08 is
            variable virtWire   : tMemX08(0 to 1);              --! virtual wire index/value pair
            variable irqNumSlv  : std_logic_vector(7 downto 0); --! helps for IRQ creation
        begin
            -- init
            virtWire := (others => (others => '-'));    --! no wire created
            -- IRQ?
            if ( "IRQ" = upper(name(name'left to name'left+2)) ) then
                -- @see https://stackoverflow.com/questions/7271092/how-to-convert-a-string-to-integer-in-vhdl
                -- @see Table 9: Virtual Wire Index Definition
                -- MSB is index, MSB-1... IRQ number
                irqNumSlv   := std_logic_vector(to_unsigned(integer'value(name(name'left+3 to name'right)), irqNumSlv'length));
                virtWire(0) := "0000000" & irqNumSlv(irqNumSlv'left);                                       --! MSB IRQ index
                virtWire(1) := to_stdulogic(value) & irqNumSlv(irqNumSlv'left-1 downto irqNumSlv'right);    --! MSB IRQ value, MSB-1... IRQ number
                return virtWire;
            end if;
            -- system event virtual wire?
            for i in C_SYSEVENT_NAME'range(1) loop
                --iterate over entries in virtual wire index
                for j in C_SYSEVENT_NAME'range(2) loop
                    if ( match(name, C_SYSEVENT_NAME(i,j)) ) then
                        virtWire(0)         := std_logic_vector(to_unsigned(i, virtWire(0)'length));    --! virtual wire index
                        virtWire(1)(j+4)    := '1';                                                     --! virtual wire data, value is valid
                        virtWire(1)(j)      := to_stdulogic(value);                                     --! virtual wire value
                        return virtWire;
                    end if;
                end loop;
            end loop;
            return virtWire;
        end function newVW;
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
            this.TSpiClk    := 50 ns;               --! default clock is 20MHz
            this.crcSlvEna  := false;               --! out of reset is CRC disabled
            this.spiMode    := SINGLE;              --! Default mode, out of reset
            this.sigSkew    := 0 ns;                --! no skew between clock edge and data defined
            this.verbose    := 0;                   --! all messages disabled
            this.tiout      := 100 us;              --! 100us master time out for wait
            this.tioutAlert := C_TIOUT_CYC_ALERT;   --! number of clock cycles before BFM gives up with waiting for ALERTn
            this.tioutRd    := C_TIOUT_CYC_RD;      --! number of clock cycles before BFM gives up with waiting for ALERTn
            this.alertMode  := false;               --! in default is DIO[1] for alert signaling used
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
                    if ( SINGLE = this.spiMode ) then   --! one bit per cycle transfered
                        SCK     <= '0';                 --! falling edge
                        DIO(0)  <= msg(i)(j);           --! assign data
                        wait for this.TSpiClk/2;        --! half clock cycle
                        SCK     <= '1';                 --! rising edge
                        wait for this.TSpiClk/2;        --! half clock cycle
                    elsif ( DUAL = this.spiMode ) then  --! two bits per clock cycle are transfered
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
                    if ( SINGLE = this.spiMode ) then       --! one bit per clock cycle transferred
                        SCK                 <= '0';                                                 --! falling edge
                        wait for this.TSpiClk/2;                                                    --! half clock cycle
                        SCK                 <= '1';                                                 --! rising edge
                        slv1(0 downto 0)    := std_logic_vector(TO_01(unsigned(DIO(1 downto 1))));  --! help
                        msg(i)(j)           := slv1(0);                                             --! capture data from line
                        wait for this.TSpiClk/2;                                                    --! half clock cycle
                    elsif ( DUAL = this.spiMode ) then     --! two bits per clock cycle are transfered
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
                    end if;
                end loop;
            end loop;
        end procedure spiRx;
        --***************************


        --***************************
        -- SPI Transceiver procedure
        --   function can left after specified number of RX bytes and go on after
        --     needed if response length is dynamically encoded in response
        --   sends command to eSPI slave and captures response
        --   the request is overwritten by the response
        procedure spiXcv
            (
                variable this       : inout tESpiBfm;
                variable msg        : inout tMemX08;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! bidirectional data
                constant txByte     : in integer;                           --! request length of message in bytes
                constant rxByte     : in integer;                           --! response length in bytes
                constant intRxByte  : in integer;                           --! interrupts procedure after byte count
                variable response   : out tESpiRsp                          --! Slaves response to performed request
            ) is
            variable crcMsg     : tMemX08(0 to msg'length); --! message with calculated CRC
            variable rsp        : tESpiRsp;                 --! decoded slave response
            variable rxStart    : integer;                  --! start index in message
            variable rxStop     : integer;                  --! stop index in message
            variable dropCRC    : boolean;                  --! if true CRC is from return message removed
            variable termCon    : boolean;                  --! terminates connection to slave
            variable prtRx      : boolean;                  --! print RX packet to console log
        begin
            -- entry message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:spiXcv"; end if;
            -- some checks
            if ( (msg'length < txByte) or (msg'length < rxByte) ) then
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:spiXcv: Not enough memory allocated" severity error; end if;
                response := FATAL_ERROR;
                return;
            end if;
            -- non-split or split packet (Part 1/2)?
            if ( (-1 /= txByte) and (intRxByte = rxByte) ) then     --! packet in one shoot, w/o intermediate processing recorded
                dropCRC     := true;
                termCon     := true;
                prtRx       := true;
                rxStart     := 0;
                rxStop      := rxByte;
            elsif ( (-1 /= txByte) and (intRxByte < rxByte) ) then  --! packet is not fully fetched, cause intermediate processing and higher hierarchy is required
                dropCRC     := false;
                termCon     := false;
                prtRx       := false;
                rxStart     := 0;
                rxStop      := intRxByte-1;
            elsif ( (-1 = txByte) and (intRxByte < rxByte) ) then   --! fetch missing part of the packet
                dropCRC                     := true;
                termCon                     := true;
                prtRx                       := true;
                rxStart                     := intRxByte-1;
                rxStop                      := rxByte;
                crcMsg(0 to intRxByte-1)    := msg(0 to intRxByte-1);   --! restore in previous cycle fetched data
            else
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:spiXcv: Something went wrong" severity error; end if;
                response := FATAL_ERROR;
                return;
            end if;
            -- only send if number of tx bytes specified, otherwise in the middle of a packet
            if ( -1 /= txByte ) then
                -- prepare data
                crcMsg(0 to txByte-1)    := msg(0 to txByte-1);          --! copy request
                crcMsg(txByte)           := crc8(crcMsg(0 to txByte-1)); --! append CRC
                -- print send message to console
                if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:spiXcv:Tx: " & hexStr(crcMsg(0 to txByte)); end if;
                -- start
                CSn <= '0';                                         --! enable Slave
                spiTx(this, crcMsg(0 to txByte), SCK, DIO);         --! write to slave
                spiTar(this, SCK, DIO);                             --! change direction (write-to-read), two cycles
                spiRx(this, crcMsg(0 to 0), SCK, DIO);              --! read only response field
                while ( WAIT_STATE = decodeRsp(crcMsg(0)) ) loop    --! wait for response ready
                    spiRx(this, crcMsg(0 to 0), SCK, DIO);          --! read from slave
                end loop;
                rsp := decodeRsp(crcMsg(0));    --! decode response
            end if;
            -- acquire RX packet
            if ( ACCEPT = rsp ) then            --! all fine
                -- fetch pending bytes
                spiRx(this, crcMsg(rxStart+1 to rxStop), SCK, DIO);
            elsif ( DEFER = rsp ) then          --! defer (1Byte) returns slave status (2Byte) and CRC (1Byte)
                -- fetch pending bytes
                rxStop  := 3;                               --! in defer (1Byte) returns slave status (2Byte) and CRC (1Byte)
                spiRx(this, crcMsg(1 to rxStop), SCK, DIO); --! read from slave,
                -- mark as finished packet, if it was planed as interrupted packet, after DEFER new read cycle
                dropCRC := true;                            --! only one byte fetched from slave
                termCon := true;                            --! connection to slave can closed
                prtRx   := true;
            elsif ( NO_RESPONSE = rsp ) then
                rxStop  := 0;
                dropCRC := false;   --! only one byte fetched from slave
                termCon := true;    --! connection to slave can closed
                prtRx   := true;    --! print no response to console
            else
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:spiXcv: unexpected response '" & rsp2str(rsp) & "'" severity error; end if;
                termCon := true;    --! close slaves connection
            end if;
            -- return CRC?
            if ( dropCRC ) then
                -- check crc
                if (not checkCRC(this, crcMsg(0 to rxStop))) then
                    rsp := FATAL_ERROR; --! Table 4: Response Field Encodings, It is also the default response when fatal CRC error is detected on the command packet; Here: also used for response
                    if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:spiXcv:Rx:CRC failed" severity error; end if;
                end if;
                -- drop CRC
                msg(0 to rxStop-1) := crcMsg(0 to rxStop-1);
            else
                msg(0 to rxStop) := crcMsg(0 to rxStop);    --! interrupted packet needs no drop of CRC
            end if;
            -- terminate slave connection
            if ( termCon ) then
                -- Terminate connection to slave
                SCK <= '0';
                wait for this.TSpiClk/2;    --! half clock cycle
                CSn <= '1';
                wait for this.TSpiClk;      --! limits CSn bandwidth to SCK
            end if;
            -- print receive message to console
            if ( prtRx ) then
                if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:spiXcv:Rx: " & hexStr(crcMsg(0 to rxStop)); end if;
            end if;
            -- release response
            response := rsp;
        end procedure spiXcv;
        --***************************


        --***************************
        -- SPI Transceiver procedure
        --   w/o any interruption, all TX/RX bytes are transferred in one shoot
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
        begin
            -- map to interruptible transceiver procedure
                -- spiXcv( this, msg, CSn, SCK, DIO, txByte, rxByte, intRxByte, response )
            spiXcv( this, msg, CSn, SCK, DIO, numTxByte, numRxByte, numRxByte, response );
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
        -- GET_CONFIGURATION, prints direct to log
        --   @see Figure 22: GET_CONFIGURATION Command
        procedure GET_CONFIGURATION
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                constant adr    : in std_logic_vector(15 downto 0);
                variable good   : inout boolean
            ) is
            variable sts : std_logic_vector(15 downto 0);   --! wrapper variable for status
            variable cfg : std_logic_vector(31 downto 0);   --! wrapper for config
            variable rsp : tESpiRsp;
        begin
            -- get configuration
            GET_CONFIGURATION( this, CSn, SCK, DIO, adr, cfg, sts, rsp );
            -- in case of no output print to console
            if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
            -- Function is good?
            if ( ACCEPT /= rsp ) then
                good := false;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:GET_CONFIGURATION:Slave " & rsp2str(rsp) severity error; end if;
            else
                Report "GET_CONFIGURATION: ADR=0x" & to_hstring(adr) & "; CFG=0x" & to_hstring(cfg) & ";";  -- print to log
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
    -- Help Procedures, handles complex common interactions
    ----------------------------------------------

        --***************************
        -- Poll for PC_AVAIL and fetch data
        --  @see Figure 20: GET_STATUS Command
        --  @see Figure 25: Deferred Master Initiated Non-Posted Transaction
        --  @see Figure 36: Peripheral Memory Read Packet Format
        --  @see Figure 39: Peripheral Memory or I/O Completion With and Without Data Packet Format
        procedure RD_DEFER_PC_AVAIL
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out   std_logic;                      --! Slave select
                signal SCK          : out   std_logic;                      --! Shift Clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! data
                variable data       : out   tMemX08;                        --! read data, 1/2/4 Bytes supported
                variable status     : inout std_logic_vector(15 downto 0);  --! slave status
                variable response   : out   tESpiRsp                        --! command response

            ) is
            variable tiout      : natural;                          --! counter for tiout
            variable rsp        : tESpiRsp;                         --! Slaves response to performed request
            variable sts        : std_logic_vector(15 downto 0);    --! internal status
            variable msg        : tMemX08(0 to data'length + 6);    --! +1Byte Response, +3Byte Header, +2Byte Status
            variable dlen_slv   : std_logic_vector(11 downto 0);    --! data field length
            variable dlen       : integer range 0 to 1024;          --! data length of completion packet
            variable cycTyp     : std_logic_vector(7 downto 0);     --! cycle type, @see:
            variable tag        : std_logic_vector(3 downto 0);     --! tag, @see:
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:RD_DEFER_PC_AVAIL: Acquires read data after DEFER"; end if;
            -- check for PC_AVAIL
            sts     := status;      --! handles internal status
            tiout   := 0;
            while ( ('0' = sts(C_STS_PC_AVAIL)) and tiout < this.tioutRd ) loop --! no PC_AVAIL, wait for it
                -- check slave status
                    -- GET_STATUS ( this, CSn, SCK, DIO, status, response )
                GET_STATUS ( this, CSn, SCK, DIO, sts, rsp );
                if ( ACCEPT /= rsp ) then
                    if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:RD_DEFER_PC_AVAIL: GET_STATUS failed with '" & rsp2str(rsp) & "'" severity error; end if;
                    rsp := FATAL_ERROR;     --! make to fail
                    sts := (others => '0'); --! no valid data
                    exit;                   --! leave loop
                end if;
                -- inc tiout counter
                tiout := tiout + 1;
            end loop;
            -- check for reach tiout
            if ( (tiout = this.tioutRd) and ('0' = sts(C_STS_PC_AVAIL)) ) then
                rsp := NO_RESPONSE; --! no data available
                if ( this.verbose > C_MSG_WARN ) then Report "eSpiMasterBfm:RD_DEFER_PC_AVAIL: No data available in allowed response time" severity warning; end if;
            end if;
            -- fetch data from slave
            if ( (ACCEPT = rsp) and ('1' = sts(C_STS_PC_AVAIL)) ) then  --! no ero and data is available
                -- user message
                if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:RD_DEFER_PC_AVAIL: PC_AVAIL"; end if;
                -- assemble Posted completion message
                msg     := (others => (others => '0')); --! init message array
                msg(0)  := C_GET_PC;                    --! request posted completion
                -- @see: Figure 36: Peripheral Memory Read Packet Format
                -- @see: Figure 39: Peripheral Memory or I/O Completion With and Without Data Packet Format
                -- numRxByte: +1Byte Response, +3Byte Header, +2Byte Status
                    -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
                spiXcv(this, msg, CSn, SCK, DIO, 1, data'length+6, rsp);    --! CRC added and checked by transceiver procedure
                -- slave has the data?
                if ( ACCEPT = rsp ) then
                    -- disassemble read packet, @see: Figure 39: Peripheral Memory or I/O Completion With and Without Data Packet Format
                    cycTyp      := msg(1);                                              --! cycle type
                    tag         := msg(2)(7 downto 4);                                  --! tag
                    dlen_slv    := msg(2)(3 downto 0) & msg(3);                         --! intermediate
                    dlen        := to_integer(unsigned(dlen_slv));                      --! data length
                    data        := msg(4 to data'length + 4 - 1);                       --! data
                    sts         := msg(4 + data'length + 2) & msg(4 + data'length + 1); --! status register
                    -- Some Info
                    if ( this.verbose > C_MSG_INFO ) then
                        -- print to console log
                        Report                                                                character(LF) &
                                "     PC Details:"                                          & character(LF) &
                                "       Cycle Type : "      & ct2str(cycTyp)                & character(LF) &
                                "       Tag        : 0x"    & to_hstring(tag)               & character(LF) &
                                "       Length     : "      & integer'image(dlen)   & "d";
                    end if;
                    -- check
                    if ( dlen /= data'length ) then
                        if ( this.verbose > C_MSG_WARN ) then Report "eSpiMasterBfm:RD_DEFER_PC_AVAIL: Request not completely completed, pad with zeros" severity warning; end if;
                    end if;
                end if;
            else
                sts := (others => '0'); --! make invalid
            end if;
            -- propagate back
            response    := rsp;
            status      := sts;
        end procedure RD_DEFER_PC_AVAIL;
        --***************************


        --***************************
        -- Wait Alert and get status from slave
        --   is left with CSn = 0
        --   @see Figure 20: GET_STATUS Command
        procedure WAIT_ALERT
            (
                variable this       : inout tESpiBfm;                       --! common storage element
                signal CSn          : out std_logic;                        --! slave select
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! bidirectional data
                signal ALERTn       : in std_logic                          --! slaves alert pin
            ) is
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:WAIT_ALERT"; end if;
            -- wait for alert
            while ( true ) loop
                if ( this.alertMode ) then
                    if ( '0' = to_bit(std_ulogic(ALERTn), '1') ) then
                        wait for this.TSpiClk/2;        --! limit bandwidth
                        CSn <= '0';                     --! ACK alert
                        wait until rising_edge(ALERTn); --! wait for slave; true: from low value ('0' or 'L') to high value ('1' or 'H').
                        if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:WAIT_ALERT: ALERTn signals alert"; end if;
                        exit;                           --! go on with status
                    end if;
                else
                    if ( '0' = to_bit(std_ulogic(DIO(1)), '1') ) then
                        wait for this.TSpiClk/2;
                        CSn <= '0';
                        wait until rising_edge(DIO(1));
                        if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:WAIT_ALERT: DIO[1] signals alert"; end if;
                        exit;
                    end if;
                end if;
                wait for this.TSpiClk/2;
            end loop;
            wait for this.TSpiClk;  --! limit bandwidth
        end procedure WAIT_ALERT;
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
        -- IOWR - arbitrary number (1/2/4 bytes) of data, response and status register
        --   PUT_IOWR_SHORT
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
        -- IOWR - byte (8Bit)
        --   w/o status and response register -> console print
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IOWR_BYTE
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                constant data   : in std_logic_vector(7 downto 0);      --! data byte
                variable good   : inout boolean                         --! successful?
            ) is
            variable dBuf   : tMemX08(0 to 0);
            variable fg     : boolean := true;                  --! state of function good
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp    : tESpiRsp;                         --! decoded slave response
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:IOWR_BYTE"; end if;
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
        end procedure IOWR_BYTE;
        --***************************


        --***************************
        -- IOWR - word (16Bit)
        --   w/o status and response register -> console print
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IOWR_WORD
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                constant data   : in std_logic_vector(15 downto 0);     --! data word
                variable good   : inout boolean                         --! successful?
            ) is
            variable dBuf       : tMemX08(0 to 1);
            variable fg         : boolean := true;                  --! state of function good
            variable sts        : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp        : tESpiRsp;                         --! decoded slave response
            variable adr_word   : std_logic_vector(adr'range);      --! word aligned address
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:IOWR_WORD"; end if;
            -- prepare
            adr_word    := adr(adr'left downto adr'right + 1) & "0";    --! align addresses to data width
            dBuf(0)     := data(7 downto 0);                            --! fill in data
            dBuf(1)     := data(15 downto 8);                           --!
                -- IOWR( this, CSn, SCK, DIO, adr, data, status, response )
            IOWR( this, CSn, SCK, DIO, adr_word, dBuf, sts, rsp );
            -- Slave request good?
            if ( ACCEPT /= rsp ) then
                good := false;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:IOWR:Slave " & rsp2str(rsp) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
            end if;
        end procedure IOWR_WORD;
        --***************************


        --***************************
        -- IOWR - dual word (32Bit)
        --   w/o status and response register -> console print
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IOWR_DWORD
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                constant data   : in std_logic_vector(31 downto 0);     --! dual data word
                variable good   : inout boolean                         --! successful?
            ) is
            variable dBuf       : tMemX08(0 to 3);
            variable fg         : boolean := true;                  --! state of function good
            variable sts        : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp        : tESpiRsp;                         --! decoded slave response
            variable adr_dword  : std_logic_vector(adr'range);      --! word aligned address
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:IOWR_DWORD"; end if;
            -- prepare
            adr_dword   := adr(adr'left downto adr'right + 2) & "00";   --! align addresses to data width
            dBuf(0)     := data(7 downto 0);                            --! fill in data
            dBuf(1)     := data(15 downto 8);                           --!
            dBuf(2)     := data(23 downto 16);                          --!
            dBuf(3)     := data(31 downto 24);                          --!
                -- IOWR( this, CSn, SCK, DIO, adr, data, status, response )
            IOWR( this, CSn, SCK, DIO, adr_dword, dBuf, sts, rsp );
            -- Slave request good?
            if ( ACCEPT /= rsp ) then
                good := false;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:IOWR:Slave " & rsp2str(rsp) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
            end if;
        end procedure IOWR_DWORD;
        --***************************


        --***************************
        -- IOWR - byte (8Bit)
        --   w/o status and response register -> console print
        --   default IOWR is byte orientated access
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IOWR
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                constant data   : in std_logic_vector(7 downto 0);      --! data byte
                variable good   : inout boolean                         --! successful?
            ) is
        begin
                -- IOWR_BYTE( this, CSn, SCK, DIO, adr, data, good )
            IOWR_BYTE( this, CSn, SCK, DIO, adr, data, good );          --! default IOWR is byte operation
        end procedure IOWR;
        --***************************



        --***************************
        -- IORD - arbitrary number (1/2/4 bytes) of data, response and status register
        --   PUT_IORD_SHORT
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IORD
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;
                signal DIO          : inout std_logic_vector(3 downto 0);
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
                -- data ready
                sts     := msg(data'length+2) & msg(data'length+1); --! status register
                data    := msg(1 to data'length - 1 + 1);           --! data bytes
            elsif ( DEFER = rsp ) then  --! Wait, Figure 25: Deferred Master Initiated Non-Posted Transaction
                -- wait for data
                sts := msg(2) & msg(1); --! status
                    -- RD_DEFER_PC_AVAIL( this, CSn, SCK, DIO, data, status, response )
                RD_DEFER_PC_AVAIL( this, CSn, SCK, DIO, data, sts, rsp );
            else
                sts := (others => '0'); --! invalid
            end if;
            -- propagate response
            response    := rsp;
            status      := sts;
        end procedure IORD;
        --***************************


        --***************************
        -- IORD - byte (8bit)
        --   w/o status and response register -> console print
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IORD_BYTE
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                variable data   : out std_logic_vector(7 downto 0);     --! data byte
                variable good   : inout boolean                         --! successful?
            ) is
            variable dBuf   : tMemX08(0 to 0);
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp    : tESpiRsp;                         --! decoded slave response
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:IORD_BYTE"; end if;
            -- prepare
            dBuf := (others => (others => '0'));    -- init
                -- IORD( this, CSn, SCK, DIO, adr, data, status, response )
            IORD( this, CSn, SCK, DIO, adr, dBuf, sts, rsp );
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
        end procedure IORD_BYTE;
        --***************************


        --***************************
        -- IORD - word (16bit)
        --   w/o status and response register -> console print
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IORD_WORD
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                variable data   : out std_logic_vector(15 downto 0);    --! data word
                variable good   : inout boolean                         --! successful?
            ) is
            variable dBuf       : tMemX08(0 to 1);
            variable sts        : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp        : tESpiRsp;                         --! decoded slave response
            variable adr_word   : std_logic_vector(adr'range);      --! word aligned address
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:IORD_WORD"; end if;
            -- prepare
            adr_word    := adr(adr'left downto adr'right + 1) & "0";    --! align addresses to data width
            dBuf        := (others => (others => '0'));                 --! init
                -- IORD( this, CSn, SCK, DIO, adr, data, status, response )
            IORD( this, CSn, SCK, DIO, adr_word, dBuf, sts, rsp );
            -- Slave request good?
            if ( ACCEPT /= rsp ) then
                good := false;
                data := (others => '0');    --! make invalid
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:IORD:Slave " & rsp2str(rsp) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
                -- release data
                data := dBuf(1) & dBuf(0);
            end if;
        end procedure IORD_WORD;
        --***************************


        --***************************
        -- IORD - dual word (32bit)
        --   w/o status and response register -> console print
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IORD_DWORD
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                variable data   : out std_logic_vector(31 downto 0);    --! data dual word
                variable good   : inout boolean                         --! successful?
            ) is
            variable dBuf       : tMemX08(0 to 3);
            variable sts        : std_logic_vector(15 downto 0);    --! needed for stucking
            variable rsp        : tESpiRsp;                         --! decoded slave response
            variable adr_dword  : std_logic_vector(adr'range);      --! word aligned address
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:IORD_WORD"; end if;
            -- prepare
            adr_dword   := adr(adr'left downto adr'right + 2) & "00";   --! align addresses to data width
            dBuf        := (others => (others => '0'));                 --! init
                -- IORD( this, CSn, SCK, DIO, adr, data, status, response )
            IORD( this, CSn, SCK, DIO, adr_dword, dBuf, sts, rsp );
            -- Slave request good?
            if ( ACCEPT /= rsp ) then
                good := false;
                data := (others => '0');    --! make invalid
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:IORD:Slave " & rsp2str(rsp) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
                -- release data
                data := dBuf(3) & dBuf(2) & dBuf(1) & dBuf(0);
            end if;
        end procedure IORD_DWORD;
        --***************************


        --***************************
        -- IORD - byte (8Bit)
        --   w/o status and response register -> console print
        --   default IORD is byte orientated access
        --   @see Figure 26: Master Initiated Short Non-Posted Transaction
        procedure IORD
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;
                signal SCK      : out std_logic;
                signal DIO      : inout std_logic_vector(3 downto 0);
                constant adr    : in std_logic_vector(15 downto 0);     --! IO space address, 16Bits
                variable data   : out std_logic_vector(7 downto 0);     --! data byte
                variable good   : inout boolean                         --! successful?
            ) is
        begin
                -- IORD_BYTE( this, CSn, SCK, DIO, adr, data, good )
            IORD_BYTE( this, CSn, SCK, DIO, adr, data, good );          --! default IORD is byte operation
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
            variable idx    : tMemX08(0 to 0);                  --! vwireIdx
            variable data   : tMemX08(0 to 0);                  --! vwireData
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stuck
            variable rsp    : tESpiRsp;                         --! decoded slave response
        begin
            -- fill in data
            idx(0)  := vwireIdx;
            data(0) := vwireData;
            -- call more general function
                -- VWIREWR( this, CSn, SCK, DIO, vwireIdx, vwireData, status, response );
            VWIREWR( this, CSn, SCK, DIO, idx, data, sts, rsp );
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


        --***************************
        -- Virtual Wire Channel Write: wire name and value, see "System Event Virtual Wires" for proper names
        --   @see Figure 41: Virtual Wire Packet Format, Master Initiated Virtual Wire Transfer
        procedure VWIREWR
            (
                variable this   : inout tESpiBfm;
                signal CSn      : out std_logic;                        --! slave select
                signal SCK      : out std_logic;                        --! shift clock
                signal DIO      : inout std_logic_vector(3 downto 0);   --! data lines
                constant name   : in string;                            --! Virtual wire name
                constant value  : in bit;                               --! virtual wire value
                variable good   : inout boolean                         --! successful
            ) is
            variable vwireIdx   : tMemX08(0 to 1);  --! virtual wire index, @see Table 9: Virtual Wire Index Definition, max. 64 virtual wires
            variable vwireData  : tMemX08(0 to 1);  --! virtual wire data
            variable vwireLen   : integer;
            variable vwAdd      : boolean;
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:VWIREWR"; end if;
            -- build virtual wire
            vwireLen    := 0;
            vwAdd       := true;
            VW_ADD( this, name, value, vwireIdx, vwireData, vwireLen, vwAdd );   --! build virtual wire
            -- write to endpoint
            if ( vwAdd ) then
                VWIREWR( this, CSn, SCK, DIO, vwireIdx(0), vwireData(0), vwAdd );
            end if;
            -- successful?
            if ( vwAdd ) then
                if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:VWIREWR: " & name & " = " & integer'image(to_integer(unsigned'('0' & to_stdulogic(value)))); end if;
            else
                if ( this.verbose > C_MSG_WARN ) then Report "eSpiMasterBfm:VWIREWR: " & name & " Failed" severity warning; end if;
                good := false;
            end if;
        end procedure VWIREWR;
        --***************************


        --***************************
        -- Virtual Wire Channel Read
        -- GET_VWIRE
        --   @see Figure 41: Virtual Wire Packet Format, Master Initiated Virtual Wire Transfer
        procedure VWIRERD
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;                        --! slave select
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                variable vwireIdx   : out tMemX08(0 to 63);                 --! virtual wire index, @see Table 9: Virtual Wire Index Definition
                variable vwireData  : out tMemX08(0 to 63);                 --! virtual wire data
                variable vwireLen   : out integer range 0 to 64;            --! number of wire pairs
                variable status     : out std_logic_vector(15 downto 0);    --! slave status
                variable response   : out tESpiRsp                          --! slave response to command
            ) is
            variable msg        : tMemX08(0 to 2*64 + 1 + 2);       --! max. 64 Wires in same packet, +1 response, +2 status
            variable msgLen     : natural := 0;                     --! message length can vary
            variable rsp        : tESpiRsp;                         --! Slaves response to performed request
            variable sts        : std_logic_vector(15 downto 0);    --! slaves status buffer
            variable wireCnt    : natural;                          --! number of virtual wires
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:VWIRERD"; end if;
            -- init output
            vwireIdx    := (others => (others => '0'));
            vwireData   := (others => (others => '0'));
            vwireLen    := 0;
            status      := (others => '0');
            -- check for virtual message available
                -- GET_STATUS ( this, CSn, SCK, DIO, status, response )
            GET_STATUS ( this, CSn, SCK, DIO, sts, rsp );
            if ( (ACCEPT = rsp) and '1' = sts(C_STS_VWIRE_AVAIL) ) then
                -- message
                if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:VWIRERD:GET_VWIRE"; end if;
                -- acquire count of virtual wires
                msg     := (others => (others => '0')); -- clear
                msg(0)  := C_GET_VWIRE;
                    -- spiXcv( this, msg, CSn, SCK, DIO, txByte, rxByte, intRxByte, response );
                spiXcv( this, msg, CSn, SCK, DIO, 1, msg'length, 2, rsp );
                -- Slave Accepted Request?
                if ( ACCEPT = rsp ) then
                    -- extract wire count
                    wireCnt := to_integer(unsigned(msg(1)(5 downto 0))) + 1;    --! 0-based counter
                    if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:VWIRERD: number available wires = " & integer'image(wireCnt); end if;
                    -- fetch rest of packet
                        -- spiXcv( this, msg, CSn, SCK, DIO, txByte, rxByte, intRxByte, response );
                    spiXcv( this, msg, CSn, SCK, DIO, -1, 2+2*wireCnt+2, 2, rsp );  --! +2: two bytes in first request, *2: per virtual wire 2byte, +2: Status register has two bytes
                    -- align data to output
                    for i in 0 to wireCnt - 1 loop
                        vwireIdx(i)     := msg(i*2 + 2);    --! +1 Response, +1 wire count
                        vwireData(i)    := msg(i*2 + 3);    --! +1 Response, +1 wire count, +1 wire index
                    end loop;
                    status      := msg((wireCnt-1)*2 + 2 + 3) & msg((wireCnt-1)*2 + 2 + 2); --! +1 Response, +1 wire count, +1/+2 status bytes
                    response    := rsp;
                    vwireLen    := wireCnt;
                else
                    response := FATAL_ERROR;
                    if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:VWIRERD:GET_VWIRE: Slave Not accepted Request" severity error; end if;
                end if;
            else
                if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:VWIRERD: no virtual wires available"; end if;
                response    := rsp;
                status      := sts;
                vwireLen    := 0;
            end if;
        end procedure VWIRERD;
        --***************************


        --***************************
        -- Virtual Wire Channel Read
        -- GET_VWIRE
        --   @see Figure 41: Virtual Wire Packet Format, Master Initiated Virtual Wire Transfer
        procedure VWIRERD
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;                        --! slave select
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                variable good       : inout boolean                         --! successful
            ) is
            variable vwireIdx   : tMemX08(0 to 63);                 --! virtual wire index, @see Table 9: Virtual Wire Index Definition
            variable vwireData  : tMemX08(0 to 63);                 --! virtual wire data
            variable vwireLen   : integer range 0 to 64;            --! number of wire pairs
            variable rsp        : tESpiRsp;                         --! Slaves response to performed request
            variable sts        : std_logic_vector(15 downto 0);    --! slaves status buffer
        begin
            -- read wires and print
                -- VWIRERD( this, CSn, SCK, DIO, vwireIdx, vwireData, vwireLen, status, response );
            VWIRERD( this, CSn, SCK, DIO, vwireIdx, vwireData, vwireLen, sts, rsp );
            -- only if virtual wires available print to log
            if ( ACCEPT = rsp ) then
                    -- vw2str( idx, data, len)
                Report character(LF) & "     Virtual Wires:" & character(LF) & vw2str(vwireIdx, vwireData, vwireLen);
            end if;
            --slave request good?
            if ( ACCEPT /= rsp ) then
                good := false;
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:VWIRERD:Slave " & rsp2str(rsp) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose > C_MSG_INFO ) then Report sts2str(sts); end if;  --! INFO: print status
            end if;
        end procedure VWIRERD;
        --***************************

    ----------------------------------------------



    ----------------------------------------------
    -- Virtual Wire Helper
    ----------------------------------------------

        --***************************
        -- Virtual Wire: Add Virtual wire
        --   adds to vwIdx/vwData list a new entry
        procedure VW_ADD
            (
                variable this   : inout tESpiBfm;   --! common storage element
                constant name   : in string;        --! Virtual wire name
                constant value  : in bit;           --! virtual wire value
                variable vwIdx  : inout tMemX08;    --! list with virtual wire indexes
                variable vwData : inout tMemX08;    --! list with virtual wire data
                variable vwLen  : inout natural;    --! effective list length
                variable good   : inout boolean     --! successful
            ) is
            constant notValidElem   : tMemX08(0 to 1) := (others => (others => '-'));   -- not valid element
            variable appendElem     : tMemX08(0 to 1);                                  --! shall appended on virtual wire list
            variable vwPosAdd       : natural;                                          --! add element on position
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:VW_ADD"; end if;
            -- same memory allocated (length)?
            if ( vwIdx'length /= vwData'length ) then
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:VW_ADD: vwIdx/vwData have different length"; end if;
                good := false;
                return;
            end if;
            -- element can appended?
            if ( vwLen >= vwIdx'length ) then
                if ( this.verbose > C_MSG_WARN ) then Report "eSpiMasterBfm:VW_ADD: not enough memory to append additional virtual wire" severity warning; end if;
                good := false;
                return;
            end if;
            -- create element to append
                -- newVW( name, value )
            appendElem := newVW( name, value );
            -- is valid?
            if ( appendElem = notValidElem ) then
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:VW_ADD: VW '" & name & "' not recognized" severity error; end if;
                good := false;
                return;
            end if;
            -- add to existing list
            vwPosAdd := vwIdx'left + vwLen; --! append
            for i in 0 to vwLen-1 loop
                -- index exist in list
                if ( vwIdx(vwIdx'left+i) = appendElem(0) ) then
                    -- check if element exist in list, max two transitions for a virtual wire allowed
                    if ( std_match(vwData(vwData'left+i), appendElem(1)) ) then
                        if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:VW_ADD: '" & name & " = " & integer'image(to_integer(unsigned'('0' & to_stdulogic(value)))) & "' exists in list, no add"; end if;
                        return;
                    end if;
                    -- capture add position
                    vwPosAdd := vwIdx'left + i; --! insert
                end if;
            end loop;
            -- Append mode?
            if ( vwPosAdd = vwLen ) then
                vwIdx(vwPosAdd)     := (others => '0'); --! init
                vwData(vwPosAdd)    := (others => '0'); --! init
                vwLen               := vwLen + 1;       --! update length
            end if;
            -- append/insert
            vwIdx(vwPosAdd)     := appendElem(0);                                                           --! index
            vwData(vwPosAdd)    := vwData(vwPosAdd) or to_stdlogicvector(to_bitvector(appendElem(1), '0')); --! data, contents don't cares
            -- append info
            if ( this.verbose > C_MSG_INFO ) then
                Report  "eSpiMasterBfm:VW_ADD: Virtual Wires "                      & character(LF) &
                        "     Index : " & hexStr(vwIdx(vwIdx'left to vwLen-1))      & character(LF) &
                        "     Data  : " & hexStr(vwData(vwData'left to vwLen-1));
            end if;
        end procedure VW_ADD;
        --***************************


        --***************************
        -- Virtual Wire: Waits until is equal
        --   waits until a virtual wire has the given value
        --   @see Table 9: Virtual Wire Index Definition
        procedure WAIT_VW_IS_EQ
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;                        --! slave select
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                signal ALERTn       : in std_logic;                         --! Alert
                constant wireName   : in string;                            --! name of the virtual wire
                constant wireVal    : in bit;                               --! value of the virtual wire
                variable good       : inout boolean                         --! successful?
            ) is
            variable vwireIdx   : tMemX08(0 to 63);                 --! virtual wire index, @see Table 9: Virtual Wire Index Definition
            variable vwireData  : tMemX08(0 to 63);                 --! virtual wire data
            variable vwireLen   : integer range 0 to 64;            --! number of wire pairs
            variable rsp        : tESpiRsp;                         --! Slaves response to performed request
            variable sts        : std_logic_vector(15 downto 0);    --! slaves status buffer
            variable vwIdx      : integer range 0 to 255;           --! current virtual wire
            variable vwDat      : std_logic_vector(7 downto 0);     --! help variable
            variable vwIdxNdl   : integer range 0 to 255;           --! virtual wire index to look for
            variable irqNumRaw  : std_logic_vector(7 downto 0);     --! temporary variable
            variable irqNum     : std_logic_vector(6 downto 0);     --! IRQ number
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:VW_WAIT_IS_EQ"; end if;
            -- check search string
            if ( wireName'length < 4 ) then
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:VW_WAIT_IS_EQ: string not matchable" severity error; end if;
                good := false;
                return;
            end if;
            -- identify wire index
            if ( "IRQ" = wireName(wireName'left to wireName'left+2) ) then  --! IRQ
                -- str2int @see https://stackoverflow.com/questions/7271092/how-to-convert-a-string-to-integer-in-vhdl
                -- convert IRQ to slv; MSB is index, MSB-1... IRQ number
                irqNumRaw   := std_logic_vector(to_unsigned(integer'value(wireName(wireName'left+3 to wireName'right)), irqNumRaw'length));
                vwIdxNdl    := to_integer(unsigned(irqNumRaw(7 downto 7))); --! MSB is virtual wire index
                irqNum      := irqNumRaw(irqNum'range);                     --! rest is IRQ number
            -- todo: add system event wire
            else    --! No match
                if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:VW_WAIT_IS_EQ: VW name '" & wireName & "' not recognized" severity error; end if;
                good := false;
                return;
            end if;
            -- prepare, for wait loop
            rsp := ACCEPT;
            while ( ACCEPT = rsp ) loop
                    -- VWIRERD( this, CSn, SCK, DIO, vwireIdx, vwireData, vwireLen, status, response );
                VWIRERD( this, CSn, SCK, DIO, vwireIdx, vwireData, vwireLen, sts, rsp );
                -- index match?
                for i in 0 to vwireLen-1 loop
                    -- extract from array
                    vwIdx := to_integer(unsigned(vwireIdx(i)));
                    vwDat := vwireData(i);
                    -- match needle index
                    if ( (0 <= vwIdxNdl) and (vwIdxNdl <= 1) ) then     --! IRQ
                        if ( (vwIdx = vwIdxNdl) and (irqNum = vwDat(irqNum'range)) ) then   --! IRQ number matches?
                            if ( to_stdulogic(wireVal) = vwDat(7) ) then                    --! interrupt level found?
                                if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:VW_WAIT_IS_EQ: IRQ" & integer'image(to_integer(unsigned(irqNumRaw))) & "=" & integer'image(to_integer(unsigned(vwDat(7 downto 7)))) & " registered"; end if;
                                return;                                                     --! IRQ number and level matches
                            end if;
                        end if;
                    elsif ( (2 <= vwIdxNdl) and (vwIdxNdl <= 7) ) then  --! System Event Wires
                    -- todo

                    else
                        if ( this.verbose > C_MSG_ERROR ) then Report "eSpiMasterBfm:VW_WAIT_IS_EQ: Virtual Wire Index '" & integer'image(vwIdxNdl) & "' unknown" severity error; end if;
                        good := false;
                        return;
                    end if;
                end loop;
                -- no new wires available, wait for Alert
                if ( '0' = sts(C_STS_VWIRE_AVAIL) ) then
                        -- WAIT_ALERT( this, CSn, SCK, DIO, ALERTn )
                    WAIT_ALERT( this, CSn, SCK, DIO, ALERTn );  --! is left with CSn=0, second procedure is mandatory
                end if;
            end loop;
        end procedure WAIT_VW_IS_EQ;
        --***************************

    ----------------------------------------------



    ----------------------------------------------
    -- Print to Console
    ----------------------------------------------

        --***************************
        -- Prints: Slave Configuration Registers to Console Log
        procedure PRT_CFG_REGS
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;                        --! slave select
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                variable good       : inout boolean                         --! successful
            ) is
            constant adrs   : slv16(0 to 5) := (C_DEV_IDENT, C_GEN_CAP_CFG, C_CH0_CAP_CFG, C_CH1_CAP_CFG, C_CH2_CAP_CFG, C_CH3_CAP_CFG);    --! buffer slave regs
            variable sts    : std_logic_vector(15 downto 0);    --! dummy variable
            variable rsp    : tESpiRsp;                         --! request response status
            variable cfgStr : string(1 to 313);                 --! string for config print to console
            variable cfg    : std_logic_vector(31 downto 0);    --! temp variable for config
            variable tmpStr : string(1 to 10);
        begin
            -- user message
            if ( this.verbose > C_MSG_INFO ) then Report "eSpiMasterBfm:PRT_CFG_REGS"; end if;
            -- template for console print, blanks are filled
            cfgStr  :=  (others => character(NUL)); --! init
            cfgStr  :=  character(LF) &
                        "     eSPI Slave Configuration:"                 & character(LF) &
                        "       DevId                      :           " & character(LF) &
                        "       General                    :           " & character(LF) &
                        "       Peripheral Channel   (Ch0) :           " & character(LF) &
                        "       Virtual Wire Channel (Ch1) :           " & character(LF) &
                        "       OOB Message Channel  (Ch2) :           " & character(LF) &
                        "       Flash Access Channel (Ch3) :           ";
            -- acquire data
            for i in 0 to (adrs'length - 1) loop
                -- prepare
                cfg     := (others => '0');             -- init
                tmpStr  := (others => character(' '));  -- blank string
                -- request slave
                    -- GET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, status, response );
                GET_CONFIGURATION( this, CSn, SCK, DIO, adrs(i), cfg, sts, rsp );
                -- check response and prepare data
                if ( ACCEPT = rsp ) then
                    tmpStr := "0x" & to_hstring(cfg);
                else
                    if ( this.verbose > C_MSG_WARN ) then Report "eSpiMasterBfm:PRT_CFG_REGS Failed read from ADR 0x" & to_hstring(adrs(i)); end if;
                    tmpStr(1 to 4)  := "FAIL";
                    good            := false;
                end if;
                -- insert
                cfgStr(68+i*47+1 to 68+i*47+tmpStr'length) := tmpStr;
            end loop;
            -- print config
            Report cfgStr;
        end procedure PRT_CFG_REGS;
        --***************************

    ----------------------------------------------



end package body eSpiMasterBfm;
--------------------------------------------------------------------------
