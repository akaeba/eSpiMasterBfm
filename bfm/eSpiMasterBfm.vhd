--************************************************************************
-- @author:     Andreas Kaeberlein
-- @copyright:  Copyright 2021
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
-- @see:        https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/ug/ug_embedded_ip.pdf
-- @see:        https://github.com/akaeba/eSpiMasterBfm
-- @brief:      bus functional model for enhanced SPI (eSPI)
--              provides function to interact with an eSPI
--              slave
--************************************************************************



--------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.realmin;
    use ieee.math_real.realmax;
    use ieee.math_real.round;
library std;
    use std.textio.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- eSpiMasterBfm: eSPI Master Bus functional model package
package eSpiMasterBfm is

    ----------------------------------------------
    -- Typs
    ----------------------------------------------

        --***************************
        -- Arrays
        type tMemX08 is array (natural range <>) of std_logic_vector (7 downto 0);  --! byte array
        type tMemX32 is array (natural range <>) of std_logic_vector (31 downto 0); --! dword array
        --***************************

        --***************************
        -- Virtual Wires Index/Name resolving
        type tSysEventName is array(2 to 7, 0 to 3) of string(1 to 22);     --! System Event Virtual Wires;                     resolves index to name, required by print
        type tServerPfmName is array(64 to 71, 0 to 3) of string(1 to 15);  --! Server Platform Specific Virtual Wire Index;    resolves index to name, required by print
        --***************************

        --***************************
        -- ESPI Slave Response
        type tESpiRsp is
            (
                ACCEPT,             --! Command was successfully received
                DEFER,              --! Only valid in response to a PUT_NP
                NON_FATAL_ERROR,    --! The received command had an error with nonfatal severity
                FATAL_ERROR,        --! The received command had a fatal error that prevented the transaction layer packet from being successfully processed
                WAIT_STATE,         --! Adds one byte-time of delay when responding to a transaction on the bus.
                NO_RESPONSE,        --! The response encoding of all 1's is defined as no response
                NO_DECODE           --! not in eSPI Spec, no decoding possible
            );
        --***************************


        --***************************
        -- Configures the BFM
        type tESpiBfm is record
            sigSkew         : time;                             --! defines Signal Skew to prevent timing errors in back-anno
            verbose         : natural;                          --! message level; 0: no message, 1: errors, 2: error + warnings
            tiout           : time;                             --! time out when master give up an interaction
            tioutAlert      : natural;                          --! number of clock cycles before BFM gives with time out up
            tioutStatusPoll : natural;                          --! tiout how often is Status polled before giving up
            slaveRegs       : tMemX32(0 to 16);                 --! Mirrored Slave Configuration Registers (0x00 - 0x40)
            virtualWires    : tMemX08(0 to 255);                --! Table 9: Virtual Wire Index Definition; 0-1: Interrupt event, 2-7: System Event
            slaveStatus     : std_logic_vector(15 downto 0);    --! Slaves status register
            slaveResponse   : tESpiRsp;                         --! decoded Slave response
        end record tESpiBfm;
        --***************************

        --***************************
        -- BFM message level
        type tMsgLevel is
            (
                NOMSG,      --! no messages are printed to console
                ERROR,      --! errors are logged
                WARNING,    --! errors + warnings are logged
                INFO        --! errors + warnings + info are logged
            );
        --***************************

    ----------------------------------------------


    -----------------------------
    -- Functions (public)
        -- CRC calculation
        function crc8
            (
                constant msg        : in tMemX08;
                constant polynom    : in std_logic_vector(7 downto 0) := x"07"
            )
        return std_logic_vector;
        -- get current set espi clock period
        function tespi
            (
                constant this : in tESpiBfm
            )
        return time;
    -----------------------------


    -----------------------------
    -- Procedures
        -- INIT: initializes espi system
            -- bfm common handle only
            procedure INIT
                (
                    variable this   : inout tESpiBfm    --! common handle
                );
            -- bfm and slave 'Exit G3' sequence
            procedure INIT
                (
                    variable this   : inout tESpiBfm;                       --! common handle
                    signal RESETn   : out std_logic;                        --! reset signal
                    signal CSn      : out std_logic;                        --! slave select
                    signal SCK      : out std_logic;                        --! shift clock
                    signal DIO      : inout std_logic_vector(3 downto 0);   --! bidirectional data
                    signal ALERTn   : in std_logic;                         --! slaves alert pin
                    variable good   : inout boolean;                        --! successful
                    constant log    : in tMsgLevel  := ERROR;               --! BFM log level
                    constant crc    : in boolean    := false;               --! true: CRC is enabled
                    constant maxClk : in boolean    := true;                --! true: enable maximum supported SPI clock, false: reset settings used
                    constant maxDIO : in boolean    := true                 --! true: max supported data lines are used, false: reset setting used
                );

        -- setLogLevel: sets bfm log level
        procedure setLogLevel
            (
                variable this   : inout tESpiBfm;       --! common handle
                constant log    : in tMsgLevel  := INFO --! BFM log level
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
                    variable this       : inout tESpiBfm;                       --! common BFM handle
                    signal CSn          : out std_logic;                        --! slave select
                    signal SCK          : out std_logic;                        --! shift clock
                    signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                    constant adr        : in std_logic_vector(15 downto 0);     --! config address
                    variable config     : out std_logic_vector(31 downto 0);    --! config data
                    variable status     : out std_logic_vector(15 downto 0)     --! status
                );
            -- w/o status, response; instead general good, updates BFMs shadows registers of slaves capabilities regs
            procedure GET_CONFIGURATION
                (
                    variable this   : inout tESpiBfm;                       --! common BFM handle
                    signal CSn      : out std_logic;                        --! slave select
                    signal SCK      : out std_logic;                        --! shift clock
                    signal DIO      : inout std_logic_vector(3 downto 0);   --! data lines
                    constant adr    : in std_logic_vector(15 downto 0);     --! slave registers address
                    variable config : out std_logic_vector(31 downto 0);    --! read value
                    variable good   : inout boolean                         --! successful?
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
                    variable status     : out std_logic_vector(15 downto 0)
                );
            -- w/o status, response; Writes changed registers into BFM shadow registers (slaveRegs) back
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
                    variable status     : out std_logic_vector(15 downto 0)
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
                    constant adr        : in std_logic_vector(31 downto 0); --! memory address
                    constant data       : in tMemX08                        --! arbitrary number of data bytes
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
                    constant adr        : in std_logic_vector(31 downto 0); --! memory address
                    variable data       : out tMemX08                       --! arbitrary number of data bytes
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
                    variable this           : inout tESpiBfm;
                    signal CSn              : out std_logic;                        --! slave select
                    signal SCK              : out std_logic;                        --! shift clock
                    signal DIO              : inout std_logic_vector(3 downto 0);   --! data lines
                    constant virtualWire    : in tMemX08                            --! virtual wire index/data pairs, @see Table 9: Virtual Wire Index Definition
                );
            -- arbitrary vwire instruction, w/o response and status register
            procedure VWIREWR
                (
                    variable this           : inout tESpiBfm;
                    signal CSn              : out std_logic;                        --! slave select
                    signal SCK              : out std_logic;                        --! shift clock
                    signal DIO              : inout std_logic_vector(3 downto 0);   --! data lines
                    constant virtualWire    : in tMemX08;                           --! virtual wire index/data pairs, @see Table 9: Virtual Wire Index Definition
                    variable good           : inout boolean                         --! successful
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
                    variable this           : inout tESpiBfm;
                    signal CSn              : out std_logic;                        --! slave select
                    signal SCK              : out std_logic;                        --! shift clock
                    signal DIO              : inout std_logic_vector(3 downto 0);   --! data lines
                    variable virtualWire    : out tMemX08(0 to 127);                --! virtual wire index/data pairs, @see Table 9: Virtual Wire Index Definition
                    variable virtualWireLen : out integer range 0 to 64             --! number of wire pairs
                );
            -- read wires into BFM buffer
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
                    variable vw     : inout tMemX08;    --! virtual wire index/data pairs, @see Table 9: Virtual Wire Index Definition
                    variable vwLen  : inout natural;    --! effective list length
                    variable good   : inout boolean     --! successful
                );

        -- Virtual Wire: Waits until is equal
        --   waits until a virtual wire has the given value
        --   @see Table 9: Virtual Wire Index Definition
            -- arbitrary number of wires
            procedure WAIT_VW_IS_EQ
                (
                    variable this       : inout tESpiBfm;                       --! common bfm handle
                    signal CSn          : out std_logic;                        --! slave select
                    signal SCK          : out std_logic;                        --! shift clock
                    signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                    signal ALERTn       : in std_logic;                         --! Alert
                    constant vwNeedle   : in tMemX08;                           --! virtual wire index/data pairs to look for
                    variable good       : inout boolean                         --! successful?
                );
            -- single wire
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
        -- BFM
        constant C_BFM_LICENSE  : string := "BSDv3";
        constant C_BFM_AUTHORS  : string := "Andreas Kaeberlein";
        constant C_BFM_VERSION  : string := "v0.1.4";
        --***************************

        --***************************
        -- Message Levels
        constant C_MSG_NO       : integer := 0;
        constant C_MSG_ERROR    : integer := 1;
        constant C_MSG_WARN     : integer := 2;
        constant C_MSG_INFO     : integer := 3;
        --***************************

        --***************************
        -- Time-out
        constant C_TIOUT_CYC_ALERT  : integer := 100;   --! number of clock cycles before BFM gives with time out up
        constant C_TIOUT_STS_POLL   : integer := 20;    --! number of status retries before BFM giving up
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- Early Help Functions
    --   f.e. needed for constant initialization
    ----------------------------------------------

        --***************************
        -- padStr
        --   creates an string with a fixed length, padded with pad
        function padStr
            (
                constant str : in string;       --! input string
                constant pad : in character;    --! pad with
                constant len : in positive      --! resulting length
            )
        return string is
            alias    alignStr : string(1 to str'length) is str; --! make one aligned
            variable padedStr : string(1 to len);               --! padded string
        begin
            -- no padding
            if ( alignStr'length = len ) then
                return alignStr;
            end if;
            -- pad with template
            padedStr := (others => pad);
            -- pad
            padedStr(1 to alignStr'length) := alignStr;
            return padedStr;
        end function padStr;
        --***************************


        --***************************
        -- padStr
        --   creates an string with a fixed length, padded with pad
        function padStr
            (
                constant str : in string;           --! input string
                constant len : in positive          --! resulting length
            )
        return string is
        begin
            -- padStr( str, pad, len )
            return padStr( str, ' ', len );
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
        -- Config Register eSpi Slave
        --  @see Table 20: Slave Registers
        constant C_DEVICE_IDENTIFICATION    : std_logic_vector(15 downto 0) := x"0004";   --! Device Identification
        constant C_GENERAL                  : std_logic_vector(15 downto 0) := x"0008";   --! General Capabilities and Configurations
        constant C_PERIPHERAL_CHANNEL       : std_logic_vector(15 downto 0) := x"0010";   --! Channel 0 Capabilities and Configurations (Peripheral Channel)
        constant C_VIRTUAL_WIRE_CHANNEL     : std_logic_vector(15 downto 0) := x"0020";   --! Channel 1 Capabilities and Configurations (Virtual Wire Channel)
        constant C_OOB_CHANNEL              : std_logic_vector(15 downto 0) := x"0030";   --! Channel 2 Capabilities and Configurations (OOB Channel)
        constant C_FLASH_CHANNEL            : std_logic_vector(15 downto 0) := x"0040";   --! Channel 3 Capabilities and Configurations (Flash Channel)
        --***************************

        --***************************
        -- Capabilities and Configuration Registers
        --  @see 7.2.1.3 Offset 08h: General Capabilities and Configurations
        --  constants are initialized with Specs defaults
        constant C_GENERAL_CRC                          : std_logic_vector(31 downto 31) := "0";        --! CRC Checking Enable: 0b: CRC checking is disabled. 1b: CRC checking is enabled.
        constant C_GENERAL_RSP_MOD                      : std_logic_vector(30 downto 30) := "0";        --! Response Modifier Enable: This bit is set to '1' to enable the use of Response Modifier
        constant C_GENERAL_ALERT_MODE                   : std_logic_vector(28 downto 28) := "0";        --! Alert Mode: 0b: I/O[1] pin is used to signal the Alert event. 1b: Alert# pin is used to signal the Alert event.
        constant C_GENERAL_IO_MODE_SEL                  : std_logic_vector(27 downto 26) := "00";       --! I/O Mode Select:
        constant C_GENERAL_IO_MODE_SEL_SGL              : std_logic_vector(01 downto 00) := "00";       --!   00: Single I/O.
        constant C_GENERAL_IO_MODE_SEL_DUAL             : std_logic_vector(01 downto 00) := "01";       --!   01: Dual I/O.
        constant C_GENERAL_IO_MODE_SEL_QUAD             : std_logic_vector(01 downto 00) := "10";       --!   10: Quad I/O.
        constant C_GENERAL_IO_MODE_SEL_RSV              : std_logic_vector(01 downto 00) := "11";       --!   11: Reserved.
        constant C_GENERAL_IO_MODE_SUP                  : std_logic_vector(25 downto 24) := "--";       --! I/O Mode Support:
        constant C_GENERAL_IO_MODE_SUP_SGL              : std_logic_vector(01 downto 00) := "00";       --!   00: Single I/O.
        constant C_GENERAL_IO_MODE_SUP_SGL_DUAL         : std_logic_vector(01 downto 00) := "01";       --!   01: Single and Dual I/O.
        constant C_GENERAL_IO_MODE_SUP_SGL_QUAD         : std_logic_vector(01 downto 00) := "10";       --!   10: Single and Quad I/O.
        constant C_GENERAL_IO_MODE_SUP_SGL_DUAL_QUAD    : std_logic_vector(01 downto 00) := "11";       --!   11: Single, Dual and Quad I/O
        constant C_GENERAL_OD_ALERT_PIN                 : std_logic_vector(23 downto 23) := "0";        --! Open Drain Alert# Select: 0b: Alert# pin is a driven output. 1b: Alert# pin is an open-drain output.
        constant C_GENERAL_OD_ALERT_SUP                 : std_logic_vector(19 downto 19) := "-";        --! Open Drain Alert# Supported: 0b: Open-drain Alert# pin is not supported. 1b: Open-drain Alert# pin is supported.
        constant C_GENERAL_OP_FREQ_SEL                  : std_logic_vector(22 downto 20) := "000";      --! Operating Frequency: 000: 20 MHz. 001: 25 MHz. 010: 33 MHz. 011: 50 MHz. 100: 66 MHz. others: Reserved.
        constant C_GENERAL_OP_FREQ_SUP                  : std_logic_vector(18 downto 16) := "---";      --! Maximum Frequency Supported: 000: 20 MHz. 001: 25 MHz. 010: 33 MHz. 011: 50 MHz. 100: 66 MHz. others: Reserved.
        constant C_GENERAL_OP_FREQ_20MHz                : std_logic_vector(02 downto 00) := "000";      --! 000: 20 MHz.
        constant C_GENERAL_OP_FREQ_25MHz                : std_logic_vector(02 downto 00) := "001";      --! 001: 25 MHz.
        constant C_GENERAL_OP_FREQ_33MHz                : std_logic_vector(02 downto 00) := "010";      --! 010: 33 MHz.
        constant C_GENERAL_OP_FREQ_50MHz                : std_logic_vector(02 downto 00) := "011";      --! 011: 50 MHz.
        constant C_GENERAL_OP_FREQ_66MHz                : std_logic_vector(02 downto 00) := "100";      --! 100: 66 MHz.
        constant C_GENERAL_MAX_WAIT                     : std_logic_vector(15 downto 12) := "0000";     --! Maximum WAIT STATE Allowed: This is a 1-based field in the granularity of byte time. When "0", it indicates a value of 16 byte time.
        constant C_GENERAL_CHN_SUP                      : std_logic_vector(07 downto 00) := "--------"; --! Channel Supported: Each of the bits when set indicates that the corresponding channel is supported by the slave.
        constant C_GENERAL_CHN_SUP_PERI                 : std_logic_vector(00 downto 00) := "1";        --! Peripheral Channel
        constant C_GENERAL_CHN_SUP_VW                   : std_logic_vector(01 downto 01) := "1";        --! Virtual Wire Channel
        constant C_GENERAL_CHN_SUP_OOB                  : std_logic_vector(02 downto 02) := "1";        --! OOB Message Channel
        constant C_GENERAL_CHN_SUP_FLASH                : std_logic_vector(03 downto 03) := "1";        --! Flash Access Channel
        --***************************

        --***************************
        -- Channel 0 Capabilities and Configurations (Peripheral Channel)
        --  @see 7.2.1.4 Offset 10h: Channel 0 Capabilities and Configurations
        --  constants are initialized with Specs defaults
        constant C_PERI_READY     : std_logic_vector(01 downto 01) := "1";    --! Virtual Wire Channel Ready: 0b: Channel is not ready. 1b: Channel is ready.
        constant C_PERI_ENABLE    : std_logic_vector(00 downto 00) := "1";    --! Virtual Wire Channel Enable: his bit is set to '1' by eSPI master to enable the Virtual Wire channel.
        --***************************

        --***************************
        -- Channel 1 Capabilities and Configurations (Virtual Wire Channel)
        --  @see 7.2.1.5 Offset 20h: Channel 1 Capabilities and Configurations
        --  constants are initialized with Specs defaults
        constant C_VW_READY     : std_logic_vector(01 downto 01) := "1";    --! Virtual Wire Channel Ready: 0b: Channel is not ready. 1b: Channel is ready.
        constant C_VW_ENABLE    : std_logic_vector(00 downto 00) := "1";    --! Virtual Wire Channel Enable: his bit is set to '1' by eSPI master to enable the Virtual Wire channel.
        --***************************

        --***************************
        -- Channel 3 Capabilities and Configurations (Flash Channel)
        --  7.2.1.7 Offset 40h: Channel 3 Capabilities and Configurations
        --  constants are initialized with Specs defaults
        constant C_FLASH_READY  : std_logic_vector(01 downto 01) := "1";    --! Flash Access Channel Ready: 0b: Channel is not ready. 1b: Channel is ready.
        constant C_FLASH_ENABLE : std_logic_vector(00 downto 00) := "1";    --! Flash Access Channel Enable: This bit is set to '1' by eSPI master to enable the Flash Access channel.
        --***************************

        --***************************
        -- Response Fields, Table 4: Response Field Encodings
        constant C_ACCEPT           : std_logic_vector(5 downto 0)  := "001000";    --! Command was successfully received
        constant C_DEFER            : std_logic_vector(7 downto 0)  := "00000001";  --! Only valid in response to a PUT_NP
        constant C_NON_FATAL_ERROR  : std_logic_vector(7 downto 0)  := "00000010";  --! The received command had an error with nonfatal severity
        constant C_FATAL_ERROR      : std_logic_vector(7 downto 0)  := "00000011";  --! The received command had a fatal error that prevented the transaction layer packet from being successfully processed
        constant C_WAIT_STATE       : std_logic_vector(7 downto 0)  := "00001111";  --! Adds one byte-time of delay when responding to a transaction on the bus.
        constant C_NO_RESPONSE      : std_logic_vector(7 downto 0)  := "11111111";  --! The response encoding of all 1's is defined as no response
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
        -- Status Register, Figure 16: Slave's Status Register Definition
        constant C_STS_PC_FREE          : std_logic_vector(00 downto 00) := "-";    --! Peripheral Posted/Completion Rx Queue Free
        constant C_STS_NP_FREE          : std_logic_vector(01 downto 01) := "-";    --! Peripheral Non-Posted Rx Queue Free
        constant C_STS_VWIRE_FREE       : std_logic_vector(02 downto 02) := "-";    --! Virtual Wire Rx Queue Free
        constant C_STS_OOB_FREE         : std_logic_vector(03 downto 03) := "-";    --! OOB Posted Rx Queue Free
        constant C_STS_PC_AVAIL         : std_logic_vector(04 downto 04) := "-";    --! Peripheral Posted/Completion Tx Queue Avail
        constant C_STS_NP_AVAIL         : std_logic_vector(05 downto 05) := "-";    --! Peripheral Non-Posted Tx Queue Avail
        constant C_STS_VWIRE_AVAIL      : std_logic_vector(06 downto 06) := "-";    --! Virtual Wire Tx Queue Avail
        constant C_STS_OOB_AVAIL        : std_logic_vector(07 downto 07) := "-";    --! OOB Posted Tx Queue Avail
        constant C_STS_FLASH_C_FREE     : std_logic_vector(08 downto 08) := "-";    --! Flash Completion Rx Queue Free
        constant C_STS_FLASH_NP_FREE    : std_logic_vector(09 downto 09) := "-";    --! Flash Non-Posted Rx Queue Free
        constant C_STS_FLASH_C_AVAIL    : std_logic_vector(12 downto 12) := "-";    --! Flash Completion Tx Queue Avail
        constant C_STS_FLASH_NP_AVAIL   : std_logic_vector(13 downto 13) := "-";    --! Flash Non-Posted Tx Queue Avail
        --***************************

        --***************************
        -- System Event Wires
        --  @see 5.2.2.2 System Event Virtual Wires
        --  @ https://stackoverflow.com/questions/17160878/how-to-declare-two-dimensional-arrays-and-their-elements-in-vhdl/17161967
        constant C_SYSEVENT_NAME : tSysEventName := (   (padStr("SLP_S3#",              22), padStr("SLP_S4#",     22), padStr("SLP_S5#",        22), padStr("RSV",                    22)),
                                                        (padStr("SUS_STAT#",            22), padStr("PLTRST#",     22), padStr("OOB_RST_WARN",   22), padStr("RSV",                    22)),
                                                        (padStr("OOB_RST_ACK",          22), padStr("RSV",         22), padStr("WAKE#",          22), padStr("PME#",                   22)),
                                                        (padStr("SLAVE_BOOT_LOAD_DONE", 22), padStr("ERROR_FATAL", 22), padStr("ERROR_NONFATAL", 22), padStr("SLAVE_BOOT_LOAD_STATUS", 22)),
                                                        (padStr("SCI#",                 22), padStr("SMI#",        22), padStr("RCIN#",          22), padStr("HOST_RST_ACK",           22)),
                                                        (padStr("HOST_RST_WARN",        22), padStr("SMIOUT#",     22), padStr("NMIOUT#",        22), padStr("RSV",                    22))
                                                    );
        --***************************


        --***************************
        -- Server Platform Wires
        --  @see Table 24 Server Platform Specific Virtual Wire Index
        --  @see https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/ug/ug_embedded_ip.pdf
        constant C_SRV_PFM_NAME : tServerPfmName := (   (padStr("SUS_ACK#",    15), padStr("RSV",           15), padStr("RSV",         15), padStr("RSV",         15)),
                                                        (padStr("SUS_WARN#",   15), padStr("SUS_PWRDN_ACK", 15), padStr("RSV",         15), padStr("SLP_A#",      15)),
                                                        (padStr("SLP_LAN#",    15), padStr("SLP_WLAN#",     15), padStr("RSV",         15), padStr("RSV",         15)),
                                                        (padStr("PCH_TO_EC_0", 15), padStr("PCH_TO_EC_1",   15), padStr("PCH_TO_EC_2", 15), padStr("PCH_TO_EC_3", 15)),
                                                        (padStr("PCH_TO_EC_4", 15), padStr("PCH_TO_EC_5",   15), padStr("PCH_TO_EC_6", 15), padStr("PCH_TO_EC_7", 15)),
                                                        (padStr("EC_TO_PCH_0", 15), padStr("EC_TO_PCH_1",   15), padStr("EC_TO_PCH_2", 15), padStr("EC_TO_PCH_3", 15)),
                                                        (padStr("EC_TO_PCH_4", 15), padStr("EC_TO_PCH_5",   15), padStr("EC_TO_PCH_6", 15), padStr("EC_TO_PCH_7", 15)),
                                                        (padStr("HOST_C10",    15), padStr("RSV",           15), padStr("RSV",         15), padStr("RSV",         15))
                                                    );
        --***************************


        --***************************
        -- Timing Parameters
        --  @see Table 22: AC Timing Specification
        constant C_TINIT    : time := 1 us; --! eSPI Reset# Deassertion to First Transaction (GET_CONFIGURATION)
        --***************************

    ----------------------------------------------



    ----------------------------------------------
    -- Functions
    ----------------------------------------------

        --***************************
        -- get max integer number
        function max
            (
                constant op1    : in integer;   --! operand 1
                constant op2    : in integer    --! operand 2
            )
        return integer is
        begin
            return integer(round(realmax(real(op1), real(op2))));
        end function max;
        --***************************


        --***************************
        -- calc crc
        function crc8
            (
                constant msg        : in tMemX08;
                constant polynom    : in std_logic_vector(7 downto 0) := x"07"
            )
        return std_logic_vector is
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
        -- TO_01
        --   converts slv to 0/1 value
        function TO_01
            (
                constant s      : in std_logic_vector;  --! convert to 0/1
                constant xmap   : in std_logic := '0'   --! default mapping
            )
        return std_logic_vector is
            alias    inp  : std_logic_vector(s'length-1 downto 0) is s;
            variable to01 : std_logic_vector(s'length-1 downto 0);
        begin
            for i in to01'range loop
                to01(i) := to_stdulogic(to_bit(std_ulogic'(inp(i)), to_bit(xmap))); --! converts bit by bit
            end loop;
            return to01;
        end function TO_01;
        --***************************


        --***************************
        -- TO_01
        --   converts array to 0/1 value
        function TO_01
            (
                constant s      : in tMemX08;           --! convert to 0/1
                constant xmap   : in std_logic := '0'   --! default mapping
            )
        return tMemX08 is
            alias    inp  : tMemX08(0 to s'length-1) is s;
            variable to01 : tMemX08(0 to s'length-1);
        begin
            for i in 0 to to01'length-1 loop
                to01(i) := TO_01(inp(i), xmap);
            end loop;
            return to01;
        end function TO_01;
        --***************************


        --***************************
        -- or_dc
        --   bypassing std_ulogic resolution function for don't cares, they are preserved
        function or_dc
            (
                constant i1 : in std_logic_vector;  --! input
                constant i2 : in std_logic_vector
            )
        return std_logic_vector is
            alias    in1 : std_logic_vector(i1'length-1 downto 0) is i1;
            alias    in2 : std_logic_vector(i2'length-1 downto 0) is i2;
            variable slv : std_logic_vector(i1'length-1 downto 0);
        begin
            for i in slv'range loop
                if ( ('-' = in1(i)) and ('-' = in2(i)) ) then
                    slv(i) := '-';
                else
                    slv(i) := to_stdulogic(to_bit(in1(i))) or to_stdulogic(to_bit(in2(i)));
                end if;
            end loop;
            return slv;
        end function or_dc;
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
                        quad := ivalue(4*i to 4*i+3);
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
                            when "----" => result(i+1) := '-';
                            when "UUUU" => result(i+1) := 'U';
                            when "HHHH" => result(i+1) := 'H';
                            when "LLLL" => result(i+1) := 'L';
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
            )
        return string is
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
        -- strtrim
        --   removes leading/trailing blanks from string
        function strtrim
            (
                constant str : in string    --! input string
            )
        return string is
            variable strStart   : positive;
            variable strStop    : positive;
            variable tmpStr     : string(1 to str'length);
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
            tmpStr(1 to (strStop-strStart)+1) := str(strStart to strStop);
            return tmpStr(1 to (strStop-strStart)+1);
        end function strtrim;
        --***************************


        --***************************
        -- strlen
        --   appends string on other string
        function strlen
            (
                constant str : in string    --! input string
            )
        return natural is
            alias    tmp : string(1 to str'length) is str;  --! alignment
            variable idx : integer;
        begin
            if ( 0 = tmp'length ) then  --! empty string
                return 0;
            end if;
            idx := tmp'length;                      --! if no breakout in loop, string has full length
            for i in tmp'range loop                 --! iterate over string
                if ( character(NUL) = tmp(i) ) then --! end of string reached?
                    idx := i - 1;                   --! last valid character is one position before
                    exit;
                end if;
            end loop;
            return idx;
        end function strlen;
        --***************************


        --***************************
        -- strcat
        --   appends string on other string
        function strcat
            (
                constant catstr : in string;    --! input string
                constant appstr : in string     --! string to append
            )
        return string is
            alias cat       : string(1 to catstr'length) is catstr;                        --! make one aligned
            alias app       : string(1 to appstr'length) is appstr;                        --! make one aligned
            variable tmp    : string(1 to catstr'length) := (others => character(NUL));    --! make empty
            variable idx    : integer;                                                     --! append stop index
        begin
            idx := integer(realmin(real(strlen(cat)+strlen(app)), real(tmp'length)));   --! concats app string, if buffer size isn't enough
            tmp(1 to 1+strlen(cat))     := cat(1 to 1+strlen(cat));                     --! copy catstr
            tmp(1+strlen(cat) to idx)   := app(1 to idx-strlen(cat));                   --! concat string
            return tmp;
        end function strcat;
        --***************************


        --***************************
        -- strcat
        --   appends character on other string
        function strcat
            (
                constant catstr     : in string;    --! input string
                constant appchar    : in character  --! character
            )
        return string is
        begin
            return strcat(catstr, "" & appchar);
        end function strcat;
        --***************************


        --***************************
        -- match
        --   returns true if string matches
        function match
            (
                constant str1 : in string;  --! input string 1
                constant str2 : in string   --! input string 2
            )
        return boolean is
            constant cStr1 : string := strtrim(str1);
            constant cStr2 : string := strtrim(str2);
        begin
            -- same length?
            if ( strlen(cStr1) /= strlen(cStr2) ) then
                return false;
            end if;
            -- match?
            if ( upper(cStr1(1 to strlen(cStr1))) = upper(cStr2(1 to strlen(cStr2))) ) then
                return true;
            end if;
            -- no match
            return false;
        end function match;
        --***************************


        --***************************
        -- hexStr
        --   converts byte array into hexadecimal string
        function hexStr ( msg : in tMemX08 )
        return string is
            alias slvs      : tMemX08(0 to msg'length-1) is msg;    --! zero align
            variable str    : string(1 to (msg'length+1)*5+1);      --! 8bit per
        begin
            -- init
            str := (others => NUL);
            -- build hex value
            for i in 0 to slvs'length-1 loop
                str(i*5+1 to i*5+5) := "0x" & to_hstring(slvs(i)) & " ";
            end loop;
            -- return
            return str(1 to (slvs'length-1)*5+4);   --! +4 drops last blank
        end function hexStr;
        --***************************


        --***************************
        -- checkCRC
        --   calculates CRC from msglen-1 and compares with last byte of msg len
        function checkCRC
            (
                constant this   : in tESpiBfm;
                constant msg    : in tMemX08
            )
        return boolean is
            alias m         : tMemX08(0 to msg'length-1) is msg;    --! zero align
            variable ret    : boolean := true;
        begin
            -- CRC check enabled?
            if ( "1" = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CRC'range) ) then
                if ( m(m'length-1) /= crc8(m(0 to m'length-2)) ) then
                    ret := false;
                    if ( this.verbose >= C_MSG_ERROR ) then
                        Report "eSpiMasterBfm:checkCRC is=0x" & to_hstring(m(m'length-1)) & "; exp=0x" & to_hstring(crc8(m(0 to m'length-2))) & ";" severity error;
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
        -- tespi
        --   decodes slave register into a proper time for clock generation
        function tespi
            (
                constant this : in tESpiBfm
            )
        return time is
            variable tclk : time;
        begin
            -- get register setting
            case this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_OP_FREQ_SEL'range) is
                when C_GENERAL_OP_FREQ_20MHz => tclk := 1 sec / 20_000_000;
                when C_GENERAL_OP_FREQ_25MHz => tclk := 1 sec / 25_000_000;
                when C_GENERAL_OP_FREQ_33MHz => tclk := 1 sec / 33_000_000;
                when C_GENERAL_OP_FREQ_50MHz => tclk := 1 sec / 50_000_000;
                when C_GENERAL_OP_FREQ_66MHz => tclk := 1 sec / 66_000_000;
                when others                  => tclk := 1 sec / 20_000_000; --! init frequency is 20MHz
            end case;
            -- release time
            return tclk;
        end function tespi;
        --***************************


        --***************************
        -- rsp2str
        --   print decoded response register to string in a human-readable way
        function rsp2str ( rsp : tESpiRsp ) return string is
        begin
            case rsp is
                when ACCEPT             => return string'("ACCEPT");
                when DEFER              => return string'("DEFER");
                when NON_FATAL_ERROR    => return string'("NON_FATAL_ERROR");
                when FATAL_ERROR        => return string'("FATAL_ERROR");
                when WAIT_STATE         => return string'("WAIT_STATE");
                when NO_RESPONSE        => return string'("NO_RESPONSE");
                when NO_DECODE          => return string'("NO_DECODE");
                when others             => return string'("NO_DECODE");
            end case;
        end function rsp2str;
        --***************************


        --***************************
        -- ct2str
        --   print decoded cycle type in human readable form to string
        function ct2str ( ct : std_logic_vector(7 downto 0) ) return string is
        begin
            if    ( std_match(ct, C_CT_MEMRD32) )           then return string'("MEMRD32");
            elsif ( std_match(ct, C_CT_MEMRD64) )           then return string'("MEMRD64");
            elsif ( std_match(ct, C_CT_MEMWR32) )           then return string'("MEMWR32");
            elsif ( std_match(ct, C_CT_MEMWR64) )           then return string'("MEMWR64");
            elsif ( std_match(ct, C_CT_MSG) )               then return string'("Message");
            elsif ( std_match(ct, C_CT_MSG_W_DAT) )         then return string'("Message with Data");
            elsif ( std_match(ct, C_CT_CPL_OK_WO_DAT) )     then return string'("Successful Completion Without Data");
            elsif ( std_match(ct, C_CT_CPL_OK_W_DAT) )      then return string'("Successful Completion With Data");
            elsif ( std_match(ct, C_CT_CPL_FAIL_W_DAT) )    then return string'("Unsuccessful Completion Without Data");
            else                                                 return string'("UNKNOWN");
            end if;
        end function ct2str;
        --***************************


        --***************************
        -- sts2str
        --   print status register to string in a human-readable way
        function sts2str ( sts : in std_logic_vector(15 downto 0) )
        return string is
            variable ret : string(1 to 1024) := (others => (character(NUL)));   --! make empty
        begin
            ret := strcat(  ret, "     Status           : 0x" & to_hstring(sts)                                                                                    & character(LF) &
                                 "       PC_FREE        : "   & to_hstring(sts(C_STS_PC_FREE'range))        & "       Peripheral Posted/Completion Rx Queue Free"  & character(LF) &
                                 "       NP_FREE        : "   & to_hstring(sts(C_STS_NP_FREE'range))        & "       Peripheral Non-Posted Rx Queue Free"         & character(LF) &
                                 "       VWIRE_FREE     : "   & to_hstring(sts(C_STS_VWIRE_FREE'range))     & "       Virtual Wire Rx Queue Free"                  & character(LF) &
                                 "       OOB_FREE       : "   & to_hstring(sts(C_STS_OOB_FREE'range))       & "       OOB Posted Rx Queue Free"                    & character(LF) &
                                 "       PC_AVAIL       : "   & to_hstring(sts(C_STS_PC_AVAIL'range))       & "       Peripheral Posted/Completion Tx Queue Avail" & character(LF) &
                                 "       NP_AVAIL       : "   & to_hstring(sts(C_STS_NP_AVAIL'range))       & "       Peripheral Non-Posted Tx Queue Avail"        & character(LF) &
                                 "       VWIRE_AVAIL    : "   & to_hstring(sts(C_STS_VWIRE_AVAIL'range))    & "       Virtual Wire Tx Queue Avail"                 & character(LF) &
                                 "       OOB_AVAIL      : "   & to_hstring(sts(C_STS_OOB_AVAIL'range))      & "       OOB Posted Tx Queue Avail"                   & character(LF) &
                                 "       FLASH_C_FREE   : "   & to_hstring(sts(C_STS_FLASH_C_FREE'range))   & "       Flash Completion Rx Queue Free"              & character(LF) &
                                 "       FLASH_NP_FREE  : "   & to_hstring(sts(C_STS_FLASH_NP_FREE'range))  & "       Flash Non-Posted Rx Queue Free"              & character(LF) &
                                 "       FLASH_C_AVAIL  : "   & to_hstring(sts(C_STS_FLASH_C_AVAIL'range))  & "       Flash Completion Tx Queue Avail"             & character(LF) &
                                 "       FLASH_NP_AVAIL : "   & to_hstring(sts(C_STS_FLASH_NP_AVAIL'range)) & "       Flash Non-Posted Tx Queue Avail"             & character(LF)
                         );
            return ret(1 to strlen(ret)-1); --! -1: drops last 'LF'
        end function sts2str;
        --***************************


        --***************************
        -- vw2str
        --   prints virtual wires in a human-readable way
        --   @see Table 9: Virtual Wire Index Definition, https://www.intel.com/content/dam/support/us/en/documents/software/chipset-software/327432-004_espi_base_specification_rev1.0_cb.pdf
        function vw2str
            (
                constant virtualWire    : in tMemX08;           --! virtual wire index/data pairs
                constant maxLen         : in positive := 2048   --! max string length
            )
        return string is
            alias vw                : tMemX08(0 to virtualWire'length-1) is virtualWire;    --! zero align
            constant cBlankPad7     : string(1 to 7)        := "       ";                   --! blank padding for log alignment
            constant cBlankPad5     : string(1 to 5)        := "     ";                     --! blank padding for log alignment
            variable ret            : string(1 to maxLen)   := (others => character(NUL));  --! make empty
            variable strIrqLen      : integer               := -1;                          --! max length of IRQ,                      -1 not in list
            variable strSysEventLen : integer               := -1;                          --! max length of system event,             -1 not in list
            variable strRsvLen      : integer               := -1;                          --! max length of reserved wires,           -1 not in list
            variable strSrvPfmLen   : integer               := -1;                          --! max length of server specific wires,    -1 not in list
            variable strPfmSpLen    : integer               := -1;                          --! max length of platform specific wires,  -1 not in list
            variable strGpioLen     : integer               := -1;                          --! max length of GPIO wires,               -1 not in list
            variable index          : integer;                                              --! idx converted to integer
        begin
            -- no virtual wires available
            if ( 0 = vw'length ) then
                ret := strcat(ret, cBlankPad5 & "NO Virtual Wire data available" & character(LF));
                return ret(1 to strlen(ret)-1); --! -1: drops last 'LF'
            end if;
            -- index/data mismatch
            if ( 0 /= (vw'length mod 2) ) then
                ret := strcat(ret, cBlankPad5 & "Virtual Wire index/data mismatch" & character(LF));
                return ret(1 to strlen(ret)-1); --! -1: drops last 'LF'
            end if;
            -- determine string length of virtual wire types
            for i in 0 to vw'length/2 - 1 loop
                -- convert to integer
                index := to_integer(unsigned(vw(2*i)));
                -- determine length based on category
                if ( (0 <= index) and (index <= 1) ) then                                           --! index=0-1: IRQ
                    strIrqLen := max(strIrqLen, 3 + strlen(integer'image(to_integer(unsigned(vw(2*i+1)(6 downto 0))))));    --! +3 -> IRQ
                elsif ( (C_SYSEVENT_NAME'low <= index) and (index <= C_SYSEVENT_NAME'high) ) then   --! index=2-7: System Event Virtual Wire
                    for j in 0 to 3 loop    --! four wires a packed into one virtual wire nibble
                        if ( '1' = vw(2*i+1)(j+4) ) then  --! valid?
                            strSysEventLen := max(strSysEventLen, strlen(strtrim(C_SYSEVENT_NAME(index, j))));
                        end if;
                    end loop;
                elsif ( (8 <= index) and (index <= 63) ) then   --! index=8-63: Reserved?
                    strRsvLen := max(strRsvLen, 8);             --! +8 'idx=0x00'
                elsif ( (C_SRV_PFM_NAME'low <= index) and (index <= C_SRV_PFM_NAME'high) ) then --! index=64-71: Server Platform Specific Virtual Wire Index
                    for j in 0 to 3 loop                    --! four wires a packed into one virtual wire nibble
                        if ( '1' = vw(2*i+1)(j+4) ) then    --! valid?
                            strSrvPfmLen := max(strSrvPfmLen, strlen(strtrim(C_SRV_PFM_NAME(index, j))));
                        end if;
                    end loop;
                elsif ( (72 <= index) and (index <= 127) ) then
                    strPfmSpLen := max(strPfmSpLen, 4+strlen(integer'image(index)));    --! +4 'idx='
                elsif ( (128 <= index) and (index <= 255) ) then
                    strGpioLen := max(strGpioLen, 4+strlen(integer'image((index-128)*4)));  --! +4 'GPIO'
                else
                    ret := strcat(ret, cBlankPad5 & "Unsupported virtual wire index " & integer'image(index) & character(LF));
                    return ret(1 to strlen(ret)-1); --! -1: drops last 'LF'
                end if;
            end loop;
            -- IRQ wire
            if ( -1 /= strIrqLen ) then
                ret := strcat(ret, cBlankPad5 & "IRQs (0x00-0x01):" & character(LF));   --! header
                for i in 0 to vw'length/2 - 1 loop                      --! look for IRQs in virtual wire list
                    index := to_integer(unsigned(vw(2*i)));             --! convert to integer
                    if ( (0 <= index) and (index <= 1) ) then           --! index=0-1: IRQ
                        ret := strcat( ret, padStr(cBlankPad7 & "IRQ" & integer'image(to_integer(unsigned(vw(2*i+1)(6 downto 0)))), strIrqLen+7) &  --! IRQ number, +7: leading blanks
                                            " : " & integer'image(to_integer(unsigned(vw(2*i+1)(7 downto 7)))) & character(LF)                      --! IRQ level
                                     );
                    end if;
                end loop;
                ret := strcat(ret, LF); --! separate from next header
            end if;
            -- System Event Wire
            if ( -1 /= strSysEventLen ) then
                ret := strcat(ret, cBlankPad5 & "System Event Wire (0x02-0x07):" & character(LF));  --! header
                for i in 0 to vw'length/2 - 1 loop                                  --! look for System Event Wire in virtual wire list
                    index := to_integer(unsigned(vw(2*i)));                         --! convert to integer
                    if ( (C_SYSEVENT_NAME'low <= index) and (index <= C_SYSEVENT_NAME'high) ) then  --! index=2-7: system event wire
                        for j in 0 to 3 loop                    --! four wires a packed into one virtual wire nibble
                            if ( '1' = vw(2*i+1)(j+4) ) then    --! valid?
                                ret := strcat( ret, padStr(cBlankPad7 & strtrim(C_SYSEVENT_NAME(index, j)), strSysEventLen+7) &         --! +7: leading blanks
                                                    " : " & integer'image(to_integer(unsigned(vw(2*i+1)(j downto j)))) & character(LF)  --! wire level
                                             );
                            end if;
                        end loop;
                    end if;
                end loop;
                ret := strcat(ret, LF); --! separate from next header
            end if;
            -- Reserved
            if ( -1 /= strRsvLen ) then
                ret := strcat(ret, cBlankPad5 & "Reserved Wire (0x08-0x3F):" & character(LF));  --! header
                for i in 0 to vw'length/2 - 1 loop                              --! look for Reserved in virtual wire list
                    index := to_integer(unsigned(vw(2*i)));                     --! convert to integer
                    if ( (8 <= index) and (index <= 63) ) then                  --! index=8-63: Reserved?
                        ret := strcat( ret, padStr(cBlankPad7 & "idx=0x" & to_hstring(vw(2*i)), ' ', strRsvLen+7) & --! +7: leading blanks
                                            " : 0x" & to_hstring(vw(2*i+1)) & character(LF)                         --! value
                                     );
                    end if;
                end loop;
                ret := strcat(ret, LF); --! separate from next header
            end if;
            -- Server Platform Specific
            if ( -1 /= strSrvPfmLen ) then
                ret := strcat(ret, cBlankPad5 & "Server Platform Specific Wire (0x40-0x47):" & character(LF));  --! header
                for i in 0 to vw'length/2 - 1 loop                                                  --! look for Server Platform Specific in virtual wire list
                    index := to_integer(unsigned(vw(2*i)));                                         --! convert to integer
                    if ( (C_SRV_PFM_NAME'low <= index) and (index <= C_SRV_PFM_NAME'high) ) then    --! index=64-71: Server Platform Specific Virtual Wire Index
                        for j in 0 to 3 loop                    --! four wires a packed into one virtual wire nibble
                            if ( '1' = vw(2*i+1)(j+4) ) then    --! valid?
                                ret := strcat( ret, padStr(cBlankPad7 & strtrim(C_SRV_PFM_NAME(index, j)), strSrvPfmLen+7) &            --! system wire name, +7: leading blanks
                                                    " : " & integer'image(to_integer(unsigned(vw(2*i+1)(j downto j)))) & character(LF)  --! wire level
                                             );
                            end if;
                        end loop;
                    end if;
                end loop;
                ret := strcat(ret, LF); --! separate from next header
            end if;
            -- Platform specific wires
            if ( -1 /= strPfmSpLen ) then
                ret := strcat(ret, cBlankPad5 & "Platform specific wires (0x48-0x7F):" & character(LF));    --! header
                for i in 0 to vw'length/2 - 1 loop                  --! look for Platform specific wires in virtual wire list
                    index := to_integer(unsigned(vw(2*i)));         --! convert to integer
                    if ( (72 <= index) and (index <= 127) ) then    --! index=72-127: Platform specific wires
                        ret := strcat( ret, padStr(cBlankPad7 & "idx=0x" & to_hstring(vw(2*i)), strPfmSpLen+7) &    --! +7: leading blanks
                                            " : 0x" & to_hstring(vw(2*i+1)) & character(LF)                         --! value
                                     );
                    end if;
                end loop;
                ret := strcat(ret, LF); --! separate from next header
            end if;
            -- GPIO
            if ( -1 /= strGpioLen ) then
                ret := strcat(ret, cBlankPad5 & "GPIO (0x80-0xFF):" & character(LF));   --! header
                for i in 0 to vw'length/2 - 1 loop                  --! look for Platform specific wires in virtual wire list
                    index := to_integer(unsigned(vw(2*i)));         --! convert to integer
                    if ( (128 <= index) and (index <= 255) ) then   --! index=128-255: GPIO wires
                        for j in 0 to 3 loop                    --! four wires a packed into one virtual wire nibble
                            if ( '1' = vw(2*i+1)(j+4) ) then    --! valid?
                                ret := strcat( ret, padStr(cBlankPad7 & "GPIO" & integer'image((index-128)*4+j), strGpioLen+7) &        --! +7: leading blanks
                                                    " : " & integer'image(to_integer(unsigned(vw(2*i+1)(j downto j)))) & character(LF)  --! wire level
                                             );
                            end if;
                        end loop;
                    end if;
                end loop;
                ret := strcat(ret, LF); --! separate from next header
            end if;
            -- all done
            return ret(1 to strlen(ret)-2); --! drop last two line feed
        end function vw2str;
        --***************************


        --***************************
        -- cfgReg2Str
        --   prints configuration registers into string
        function cfgReg2Str ( this : in tESpiBfm ) return string is
            variable str : string(1 to 512) := (others => character(NUL));
        begin
            -- always print
            str := strcat(str, "     eSPI Configuration:"                                                                                               & character(LF));
            str := strcat(str, "       Device Identification      : 0x" & to_hstring(this.slaveRegs(to_integer(unsigned(C_DEVICE_IDENTIFICATION)/4)))   & character(LF));
            str := strcat(str, "       General                    : 0x" & to_hstring(this.slaveRegs(to_integer(unsigned(C_GENERAL)/4)))                 & character(LF));
            -- Peripheral Channel (Ch0)
            case this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CHN_SUP_PERI'range) is
                when "1"    => str := strcat(str, "       Peripheral Channel   (Ch0) : 0x" & to_hstring(this.slaveRegs(to_integer(unsigned(C_PERIPHERAL_CHANNEL)/4)))   & character(LF));
                when "0"    => str := strcat(str, "       Peripheral Channel   (Ch0) : not supported"                                                                   & character(LF));
                when others => str := strcat(str, "       Peripheral Channel   (Ch0) : UNKNOWN"                                                                         & character(LF));
            end case;
            -- Virtual Wire Channel (Ch1)
            case this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CHN_SUP_VW'range) is
                when "1"    => str := strcat(str, "       Virtual Wire Channel (Ch1) : 0x" & to_hstring(this.slaveRegs(to_integer(unsigned(C_VIRTUAL_WIRE_CHANNEL)/4))) & character(LF));
                when "0"    => str := strcat(str, "       Virtual Wire Channel (Ch1) : not supported"                                                                   & character(LF));
                when others => str := strcat(str, "       Virtual Wire Channel (Ch1) : UNKNOWN"                                                                         & character(LF));
            end case;
            -- OOB Message Channel (Ch2)
            case this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CHN_SUP_OOB'range) is
                when "1"    => str := strcat(str, "       OOB Message Channel  (Ch2) : 0x" & to_hstring(this.slaveRegs(to_integer(unsigned(C_OOB_CHANNEL)/4)))  & character(LF));
                when "0"    => str := strcat(str, "       OOB Message Channel  (Ch2) : not supported"                                                           & character(LF));
                when others => str := strcat(str, "       OOB Message Channel  (Ch2) : UNKNOWN"                                                                 & character(LF));
            end case;
            -- Flash Access Channel (Ch3)
            case this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CHN_SUP_FLASH'range) is
                when "1"    => str := strcat(str, "       Flash Access Channel (Ch3) : 0x" & to_hstring(this.slaveRegs(to_integer(unsigned(C_FLASH_CHANNEL)/4)))    & character(LF));
                when "0"    => str := strcat(str, "       Flash Access Channel (Ch3) : not supported"                                                               & character(LF));
                when others => str := strcat(str, "       Flash Access Channel (Ch3) : UNKNOWN"                                                                     & character(LF));
            end case;
            -- interpretation finished
            return str(1 to strlen(str));
        end function cfgReg2Str;
        --***************************


        --***************************
        -- generalReg2Str
        --   prints & interprets general configuration & capabilities register into string
        function generalReg2Str ( this : in tESpiBfm ) return string is
            variable str : string(1 to 1023) := (others => character(NUL));
        begin
            -- Header
            str := strcat(str, "     General Capabilities and Configurations (0x08):" & character(LF));
            -- CRC Checking Enable, Bit31
            str := strcat(str, "       CRC Checking Enable  : " & integer'image(to_integer(unsigned(this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CRC'range)))) & character(LF));
            -- Alert Mode, Bit28
            case this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_ALERT_MODE'range) is
                when "1"    => str := strcat(str, "       Alert Mode           : Alert"    & character(LF));
                when "0"    => str := strcat(str, "       Alert Mode           : I/O[1]"   & character(LF));
                when others => str := strcat(str, "       Alert Mode           : UNKNOWN"  & character(LF));
            end case;
            -- I/O Mode Select, Bit27:26
            case this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) is
                when C_GENERAL_IO_MODE_SEL_SGL  => str := strcat(str, "       I/O Mode Select      : Single I/O"   & character(LF));
                when C_GENERAL_IO_MODE_SEL_DUAL => str := strcat(str, "       I/O Mode Select      : Dual I/O"     & character(LF));
                when C_GENERAL_IO_MODE_SEL_QUAD => str := strcat(str, "       I/O Mode Select      : Quad I/O"     & character(LF));
                when others                     => str := strcat(str, "       I/O Mode Select      : UNKNOWN"      & character(LF));
            end case;
            -- I/O Mode Support, Bit25:24
            case this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SUP'range) is
                when C_GENERAL_IO_MODE_SUP_SGL              => str := strcat(str, "       I/O Mode Support     : Single I/O"                & character(LF));
                when C_GENERAL_IO_MODE_SUP_SGL_DUAL         => str := strcat(str, "       I/O Mode Support     : Single, Dual I/O"          & character(LF));
                when C_GENERAL_IO_MODE_SUP_SGL_QUAD         => str := strcat(str, "       I/O Mode Support     : Single, Quad I/O"          & character(LF));
                when C_GENERAL_IO_MODE_SUP_SGL_DUAL_QUAD    => str := strcat(str, "       I/O Mode Support     : Single, Dual, Quad I/O"    & character(LF));
                when others                                 => str := strcat(str, "       I/O Mode Support     : UNKNOWN"       & character(LF));
            end case;
            -- Open Drain Alert# Select, Bit23
            case this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_OD_ALERT_PIN'range) is
                when "1"    => str := strcat(str, "       Alert Output Pin     : open-drain"    & character(LF));
                when "0"    => str := strcat(str, "       Alert Output Pin     : driven"        & character(LF));
                when others => str := strcat(str, "       Alert Output Pin     : UNKNOWN"       & character(LF));
            end case;
            -- Operating Frequency, Bit22:20
            case this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_OP_FREQ_SEL'range) is
                when C_GENERAL_OP_FREQ_20MHz    => str := strcat(str, "       Operating Frequency  : 20MHz"     & character(LF));
                when C_GENERAL_OP_FREQ_25MHz    => str := strcat(str, "       Operating Frequency  : 25MHz"     & character(LF));
                when C_GENERAL_OP_FREQ_33MHz    => str := strcat(str, "       Operating Frequency  : 33MHz"     & character(LF));
                when C_GENERAL_OP_FREQ_50MHz    => str := strcat(str, "       Operating Frequency  : 50MHz"     & character(LF));
                when C_GENERAL_OP_FREQ_66MHz    => str := strcat(str, "       Operating Frequency  : 66MHz"     & character(LF));
                when others                     => str := strcat(str, "       Operating Frequency  : UNKNOWN"   & character(LF));
            end case;
            -- Open Drain Alert# Supported, Bit19
            case this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_OD_ALERT_SUP'range) is
                when "1"    => str := strcat(str, "       Open Drain Alert#    : supported"     & character(LF));
                when "0"    => str := strcat(str, "       Open Drain Alert#    : not supported" & character(LF));
                when others => str := strcat(str, "       Open Drain Alert#    : UNKNOWN"       & character(LF));
            end case;
            -- Maximum Frequency Supported, Bit18:16
            case this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_OP_FREQ_SUP'range) is
                when C_GENERAL_OP_FREQ_20MHz    => str := strcat(str, "       Maximum Frequency    : 20MHz"     & character(LF));
                when C_GENERAL_OP_FREQ_25MHz    => str := strcat(str, "       Maximum Frequency    : 25MHz"     & character(LF));
                when C_GENERAL_OP_FREQ_33MHz    => str := strcat(str, "       Maximum Frequency    : 33MHz"     & character(LF));
                when C_GENERAL_OP_FREQ_50MHz    => str := strcat(str, "       Maximum Frequency    : 50MHz"     & character(LF));
                when C_GENERAL_OP_FREQ_66MHz    => str := strcat(str, "       Maximum Frequency    : 66MHz"     & character(LF));
                when others                     => str := strcat(str, "       Maximum Frequency    : UNKNOWN"   & character(LF));
            end case;
            -- Maximum WAIT STATE Allowed, Bit15:12
            case to_integer(to_01(unsigned(this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_MAX_WAIT'range)))) is
                when 0      => str := strcat(str, "       Maximum WAIT STATE   : 16Byte"                                                                                                                        & character(LF));
                when others => str := strcat(str, "       Maximum WAIT STATE   : " & integer'image(to_integer(unsigned(this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_MAX_WAIT'range))))  & "Byte" & character(LF));
            end case;
            -- Channel Supported:
            str := strcat(str, "       Peripheral Channel   : " & integer'image(to_integer(unsigned(this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CHN_SUP_PERI'range))))  & character(LF));
            str := strcat(str, "       Virtual Wire Channel : " & integer'image(to_integer(unsigned(this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CHN_SUP_VW'range))))    & character(LF));
            str := strcat(str, "       OOB Message Channel  : " & integer'image(to_integer(unsigned(this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CHN_SUP_OOB'range))))   & character(LF));
            str := strcat(str, "       Flash Access Channel : " & integer'image(to_integer(unsigned(this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CHN_SUP_FLASH'range)))) & character(LF));
            -- interpretation finished
            return str(1 to strlen(str));
        end function generalReg2Str;
        --***************************


        --***************************
        -- newVW
        --   creates virtual wire index/value pair based on name/value
        --   returns array with virtual wire index (idx0) and data (idx1)
        function newVW
            (
                constant name   : in string;    --! virtual wire name
                constant value  : in bit        --! virtual wire value
            )
        return tMemX08 is
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
    -- Common
    ----------------------------------------------

        --***************************
        -- init_cap_reg_08
        --  Offset 08h: General Capabilities and Configurations
        --  This register is also reset by the In-band RESET command.
        procedure init_cap_reg_08
            (
                variable this   : inout tESpiBfm    --! common handle
            )
        is
        begin
            this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))                               := (others => '0');         --! default
            this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CRC'range)          := C_GENERAL_CRC;           --! CRC Checking
            this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_RSP_MOD'range)      := C_GENERAL_RSP_MOD;       --! Response Modifier
            this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_ALERT_MODE'range)   := C_GENERAL_ALERT_MODE;    --! Alert Mode
            this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range)  := C_GENERAL_IO_MODE_SEL;   --! I/O Mode Select
            this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SUP'range)  := C_GENERAL_IO_MODE_SUP;   --! I/O Mode Support
            this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_OD_ALERT_PIN'range) := C_GENERAL_OD_ALERT_PIN;  --! Open Drain Alert#
            this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_OP_FREQ_SEL'range)  := C_GENERAL_OP_FREQ_SEL;   --! Operating Frequency
            this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_OD_ALERT_SUP'range) := C_GENERAL_OD_ALERT_SUP;  --! Open Drain Alert# Supported
            this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_OP_FREQ_SUP'range)  := C_GENERAL_OP_FREQ_SUP;   --! Maximum Frequency Supported
            this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_MAX_WAIT'range)     := C_GENERAL_MAX_WAIT;      --! Maximum WAIT STATE Allowed
            this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CHN_SUP'range)      := C_GENERAL_CHN_SUP;    --! Channel Supported
        end procedure init_cap_reg_08;
        --***************************


        --***************************
        -- init, bfm only
        procedure INIT
            (
                variable this   : inout tESpiBfm    --! common handle
            )
        is
        begin
            -- common handle
            this.sigSkew            := 0 ns;                        --! no skew between clock edge and data defined
            this.verbose            := C_MSG_NO;                    --! all messages disabled
            this.tiout              := 100 us;                      --! 100us master time out for wait
            this.tioutAlert         := C_TIOUT_CYC_ALERT;           --! number of clock cycles before BFM gives up with waiting for ALERTn
            this.tioutStatusPoll    := C_TIOUT_STS_POLL;            --! number of clock cycles before BFM gives up with waiting for ALERTn
            this.slaveRegs          := (others => (others => '0')); --! defined value, not according spec
            this.slaveStatus        := (others => 'X');             --! invalid until first read
            this.slaveResponse      := NO_DECODE;                   --! no data to decode
            -- Slave Registers
            init_cap_reg_08( this );    --! Slaves General Capabilities and Configurations
        end procedure INIT;
        --***************************


        --***************************
        -- init
        procedure INIT
            (
                variable this   : inout tESpiBfm;                       --! common handle
                signal RESETn   : out std_logic;                        --! reset signal
                signal CSn      : out std_logic;                        --! slave select
                signal SCK      : out std_logic;                        --! shift clock
                signal DIO      : inout std_logic_vector(3 downto 0);   --! bidirectional data
                signal ALERTn   : in std_logic;                         --! slaves alert pin
                variable good   : inout boolean;                        --! successful
                constant log    : in tMsgLevel  := ERROR;               --! BFM log level
                constant crc    : in boolean    := false;               --! true: CRC is enabled
                constant maxClk : in boolean    := true;                --! true: enable maximum supported SPI clock, false: reset settings used
                constant maxDIO : in boolean    := true                 --! true: max supported data lines are used, false: reset setting used
            )
        is
            variable pgood  : boolean;                          --! internal procedure good
            variable slv32  : std_logic_vector(31 downto 0);    --! temporary 32bit variable
            variable vw     : tMemX08(0 to 127);                --! virtual wire index/data pairs, @see Table 9: Virtual Wire Index Definition, max. 64 virtual wires
            variable vwLen  : integer range 0 to 64;            --! number of wire pairs
        begin
            -- init bfm storage element
                -- init ( this )
            init( this );
            -- message level
            setLogLevel( this, log );
            -- BFM info
            Report  "eSpiMasterBfm"                         & character(LF) &
                    "       License : "  & C_BFM_LICENSE    & character(LF) &
                    "       Authors : "  & C_BFM_AUTHORS    & character(LF) &
                    "       Version : "  & C_BFM_VERSION;
            -- reset startup sequence
            RESETn  <= '0';             --! send core to reset
            CSn     <= '1';             --! deselect device
            SCK     <= '0';             --! rising edge active clock
            DIO     <= (others => 'Z'); --! lines are in TB pulled
            wait for 2*tespi( this );   --! apply reset
            RESETn  <= '1';             --! disable reset
            wait for C_TINIT;           --! slave initialization time
            -- *****
            -- General capabilities
            --  @see Exit from G3, 4.)
            pgood := true;
                -- GET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, good )
            GET_CONFIGURATION( this, CSn, SCK, DIO, C_GENERAL, slv32, pgood );  --! General Capabilities and Configurations
            if not ( pgood ) then
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Failed to get register 0x" & to_hstring(C_GENERAL) severity error; end if;
                good := false;
                return;
            end if;
            -- enable according "Exit G3" sequence
            -- CRC enabled?
            if ( crc ) then
                slv32(C_GENERAL_CRC'range) := "1";  --! CRC checking is enabled
            end if;
            -- Maximum Supported Clock?
            if ( maxClk ) then
                slv32(C_GENERAL_OP_FREQ_SEL'range) := slv32(C_GENERAL_OP_FREQ_SUP'range);   --! maximum supported frequency is used
            end if;
            -- Use maximum number of DIO lines
            if ( maxDIO ) then
                -- decode available transfer mode to highest IO selection
                case slv32(C_GENERAL_IO_MODE_SUP'range) is
                    when C_GENERAL_IO_MODE_SUP_SGL              => slv32(C_GENERAL_IO_MODE_SEL'range) := C_GENERAL_IO_MODE_SEL_SGL;     --! single supported; select single
                    when C_GENERAL_IO_MODE_SUP_SGL_DUAL         => slv32(C_GENERAL_IO_MODE_SEL'range) := C_GENERAL_IO_MODE_SEL_DUAL;
                    when C_GENERAL_IO_MODE_SUP_SGL_QUAD         => slv32(C_GENERAL_IO_MODE_SEL'range) := C_GENERAL_IO_MODE_SEL_QUAD;
                    when C_GENERAL_IO_MODE_SUP_SGL_DUAL_QUAD    => slv32(C_GENERAL_IO_MODE_SEL'range) := C_GENERAL_IO_MODE_SEL_QUAD;    --! single, dual, quad supported; select quad
                    when others                                 => slv32(C_GENERAL_IO_MODE_SEL'range) := C_GENERAL_IO_MODE_SEL_RSV;
                end case;
            end if;
            -- Set General Cap Register
            --  @see Exit from G3, 5.)
                -- SET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, good )
            SET_CONFIGURATION( this, CSn, SCK, DIO, C_GENERAL, slv32, pgood );    --! update general cap reg
            if not ( pgood ) then
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Setting Register 0x" & to_hstring(C_GENERAL) & " = 0x" & to_hstring(slv32) & " failed" severity error; end if;
                good := false;
                return;
            end if;
            -- *****
            -- Virtual Wire channel is enabled, if supported
            --  @see Exit from G3, 6.)
            if ( C_GENERAL_CHN_SUP_VW = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CHN_SUP_VW'range) ) then
                -- get virtual wire channel config
                    -- GET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, good )
                GET_CONFIGURATION( this, CSn, SCK, DIO, C_VIRTUAL_WIRE_CHANNEL, slv32, pgood ); --! Virtual Wire Capabilities and Configurations
                if not ( pgood ) then
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Failed to get register 0x" & to_hstring(C_VIRTUAL_WIRE_CHANNEL) severity error; end if;
                    good := false;
                    return;
                end if;
                -- enable virtual wire channel
                slv32(C_VW_ENABLE'range) := C_VW_ENABLE;    --! enable channel
                    -- SET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, good )
                SET_CONFIGURATION( this, CSn, SCK, DIO, C_VIRTUAL_WIRE_CHANNEL, slv32, pgood ); --! update virtual wire cap reg
                if not ( pgood ) then
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Setting Register 0x" & to_hstring(C_VIRTUAL_WIRE_CHANNEL) & " = 0x" & to_hstring(slv32) & " failed" severity error; end if;
                    good := false;
                    return;
                end if;
            end if;
            -- *****
            -- Once the Flash controller is ready, the Flash Access Channel is enabled if supported.
            --  @see Exit from G3, 7.)
            if ( C_GENERAL_CHN_SUP_FLASH = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CHN_SUP_FLASH'range) ) then
                -- get virtual wire channel config
                    -- GET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, good )
                GET_CONFIGURATION( this, CSn, SCK, DIO, C_FLASH_CHANNEL, slv32, pgood );    --! Flash Channel Capabilities and Configurations
                if not ( pgood ) then
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Failed to get register 0x" & to_hstring(C_FLASH_CHANNEL) severity error; end if;
                    good := false;
                    return;
                end if;
                -- enable virtual wire channel
                slv32(C_FLASH_ENABLE'range) := C_FLASH_ENABLE;  --! enable channel
                    -- SET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, good )
                SET_CONFIGURATION( this, CSn, SCK, DIO, C_FLASH_CHANNEL, slv32, pgood );    --! update flash channel cap reg
                if not ( pgood ) then
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Setting Register 0x" & to_hstring(C_FLASH_CHANNEL) & " = 0x" & to_hstring(slv32) & " failed" severity error; end if;
                    good := false;
                    return;
                end if;
            end if;
            -- *****
            -- Chipset waits for the SLAVE_BOOT_LOAD_DONE Virtual Wire message from eSPI slave before continuing
            --  @see Exit from G3, 8.)
            vwLen   := 0;
            vw      := (others => (others => '0'));
                -- VW_ADD( this, name, value, vw, vwLen, good )
            VW_ADD( this, "SLAVE_BOOT_LOAD_STATUS", '1', vw, vwLen, pgood );
            VW_ADD( this, "SLAVE_BOOT_LOAD_DONE",   '1', vw, vwLen, pgood );
                -- WAIT_VW_IS_EQ( this, CSn, SCK, DIO, ALERTn, vw, good )
            WAIT_VW_IS_EQ( this, CSn, SCK, DIO, ALERTn, vw(0 to vwLen-1), pgood );
            if not ( pgood ) then
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Failed wait for SLAVE_BOOT_LOAD_STATUS/SLAVE_BOOT_LOAD_DONE" severity error; end if;
                good := false;
                return;
            end if;
            -- *****
            -- Chipset sends in-band Virtual Wire messages to leave sleep states
            --  @see Exit from G3, 9.)
            vwLen   := 0;
            vw      := (others => (others => '0'));
                -- VW_ADD( this, name, value, vw, vwLen, good )
            VW_ADD( this, "SLP_S5#", '1', vw, vwLen, pgood );
            VW_ADD( this, "SLP_S4#", '1', vw, vwLen, pgood );
            VW_ADD( this, "SLP_S3#", '1', vw, vwLen, pgood );
                -- VWIREWR( this, CSn, SCK, DIO, virtualWire, good );
            VWIREWR( this, CSn, SCK, DIO, vw(0 to vwLen-1), pgood );
            if not ( pgood ) then
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Failed to deassert sleep states" severity error; end if;
                good := false;
                return;
            end if;
            -- *****
            -- SUS_STAT# de-assertion
            --  @see Exit from G3, 10.)
            vwLen   := 0;
            vw      := (others => (others => '0'));
                -- VW_ADD( this, name, value, vw, vwLen, good )
            VW_ADD( this, "SUS_STAT#", '0', vw, vwLen, pgood );
                -- VWIREWR( this, CSn, SCK, DIO, virtualWire, good );
            VWIREWR( this, CSn, SCK, DIO, vw(0 to vwLen-1), pgood );
            if not ( pgood ) then
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Failed to deassert suspend status" severity error; end if;
                good := false;
                return;
            end if;
            -- *****
            -- PLTRST# deassertion
            --  @see Exit from G3, 11.)
            vwLen   := 0;
            vw      := (others => (others => '0'));
                -- VW_ADD( this, name, value, vw, vwLen, good )
            VW_ADD( this, "PLTRST#", '1', vw, vwLen, pgood );
                -- VWIREWR( this, CSn, SCK, DIO, virtualWire, good );
            VWIREWR( this, CSn, SCK, DIO, vw(0 to vwLen-1), pgood );
            if not ( pgood ) then
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Failed to deassert PLTRST" severity error; end if;
                good := false;
                return;
            end if;
            -- *****
            -- Peripheral Channel
            --  @see Exit from G3, 12.)
            if ( C_GENERAL_CHN_SUP_PERI = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_CHN_SUP_PERI'range) ) then
                    -- GET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, good )
                GET_CONFIGURATION( this, CSn, SCK, DIO, C_PERIPHERAL_CHANNEL, slv32, pgood );   --! Peripheral Capabilities and Configurations
                if not ( pgood ) then
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Failed to get register 0x" & to_hstring(C_PERIPHERAL_CHANNEL) severity error; end if;
                    good := false;
                    return;
                end if;
                -- enable peripheral channel, should enabled as default
                slv32(C_PERI_ENABLE'range) := C_PERI_ENABLE;    --! enable channel
                    -- SET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, good )
                SET_CONFIGURATION( this, CSn, SCK, DIO, C_PERIPHERAL_CHANNEL, slv32, pgood );    --! update virtual wire cap reg
                if not ( pgood ) then
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Setting Register 0x" & to_hstring(C_PERIPHERAL_CHANNEL) & " = 0x" & to_hstring(slv32) & " failed" severity error; end if;
                    good := false;
                    return;
                end if;
            end if;
            -- *****
            -- Device Identification
                -- GET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, good )
            GET_CONFIGURATION( this, CSn, SCK, DIO, C_DEVICE_IDENTIFICATION, slv32, pgood );   --! Peripheral Capabilities and Configurations
            if not ( pgood ) then
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:init: Failed to get register 0x" & to_hstring(C_DEVICE_IDENTIFICATION) severity error; end if;
                good := false;
                return;
            end if;
            -- *****
            -- Print Configuration Regs
            if ( this.verbose >= C_MSG_INFO ) then
                Report "eSpiMasterBfm:init:"        & character(LF) & character(LF) &
                            cfgReg2Str( this )      & character(LF) &
                            generalReg2Str( this );
            end if;
        end procedure INIT;
        --***************************


        --***************************
        -- setLogLevel
        --  sets bfm log level
        procedure setLogLevel
            (
                variable this   : inout tESpiBfm;       --! common handle
                constant log    : in tMsgLevel  := INFO --! BFM log level
            )
        is
        begin
            case log is
                when NOMSG      => this.verbose := C_MSG_NO;    --! no messages are printed to console
                when ERROR      => this.verbose := C_MSG_ERROR; --! errors are logged
                when WARNING    => this.verbose := C_MSG_WARN;  --! errors + warnings are logged
                when INFO       => this.verbose := C_MSG_INFO;  --! errors + warnings + info are logged
                when others     => this.verbose := C_MSG_NO;    --! default
            end case;
        end procedure setLogLevel;
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
                variable this   : inout tESpiBfm;                       --! common handle
                variable msg    : inout tMemX08;
                signal SCK      : out std_logic;                        --! shift clock
                signal DIO      : inout std_logic_vector(3 downto 0)    --! bidirectional data
            )
        is
            constant tSpiClk : time := tespi(this); --! get current SPI period
        begin
            -- iterate over message bytes
            for i in msg'low to msg'high loop
                -- iterate over bits in a single message byte
                for j in msg(i)'high downto msg(i)'low loop
                    -- dispatch mode
                    if ( C_GENERAL_IO_MODE_SEL_SGL = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) ) then
                    -- one bit per cycle transfered
                        SCK     <= '0';             --! falling edge
                        DIO(0)  <= msg(i)(j);       --! assign data
                        wait for tSpiClk/2;         --! half clock cycle
                        SCK     <= '1';             --! rising edge
                        wait for tSpiClk/2;         --! half clock cycle
                    elsif ( C_GENERAL_IO_MODE_SEL_DUAL = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) ) then
                    -- two bits per clock cycle are transfered
                        if ( 0 = (j+1) mod 2 ) then
                            SCK             <= '0'; --! falling edge
                            DIO(1 downto 0) <= msg(i)(j downto j-1);
                            wait for tSpiClk/2;     --! half clock cycle
                            SCK             <= '1'; --! rising edge
                            wait for tSpiClk/2;     --! half clock cycle
                        end if;
                    elsif ( C_GENERAL_IO_MODE_SEL_QUAD = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) ) then
                    -- four bits per clock cycle are transfered
                        if ( 0 = (j+1) mod 4 ) then
                            SCK             <= '0'; --! falling edge
                            DIO(3 downto 0) <= msg(i)(j downto j-3);
                            wait for tSpiClk/2;     --! half clock cycle
                            SCK             <= '1'; --! rising edge
                            wait for tSpiClk/2;     --! half clock cycle
                        end if;
                    else
                        -- unsupported transfer mode
                        if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:spiTx: unsupported transfer mode 0x" & to_hstring(this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range)) severity error; end if;
                        return;
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
            )
        is
            constant tSpiClk : time := tespi(this); --! get current SPI period
        begin
            -- one clock cycle drive high
            SCK     <= '0';     --! falling edge
            if ( C_GENERAL_IO_MODE_SEL_SGL = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) ) then
            -- one bits per clock cycle are transfered
                DIO(0)  <= '1';
            elsif ( C_GENERAL_IO_MODE_SEL_DUAL = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) ) then
            -- two bits per clock cycle are transfered
                DIO(1 downto 0) <= (others => '1');
            elsif ( C_GENERAL_IO_MODE_SEL_QUAD = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) ) then
            -- four bits per clock cycle are transfered
                DIO <= (others => '1');
            else
                -- unsupported transfer mode
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:spiTar: unsupported transfer mode 0x" & to_hstring(this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range)) severity error; end if;
                return;
            end if;
            wait for tSpiClk/2; --! half clock cycle
            SCK     <= '1';     --! rising edge
            wait for tSpiClk/2; --! half clock cycle
            -- one clock cycle tristate
            SCK     <= '0';     --! falling edge
            if ( C_GENERAL_IO_MODE_SEL_SGL = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) ) then
            -- one bits per clock cycle are transfered
                DIO(0)  <= 'Z';
            elsif ( C_GENERAL_IO_MODE_SEL_DUAL = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) ) then
            -- two bits per clock cycle are transfered
                DIO(1 downto 0) <= (others => 'Z');
            elsif ( C_GENERAL_IO_MODE_SEL_QUAD = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) ) then
            -- four bits per clock cycle are transfered
                DIO <= (others => 'Z');
            else
                -- unsupported transfer mode
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:spiTx unsupported transfer mode 0x" & to_hstring(this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range)) severity error; end if;
                return;
            end if;
            wait for tSpiClk/2; --! half clock cycle
            SCK     <= '1';     --! rising edge
            wait for tSpiClk/2; --! half clock cycle
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
            )
        is
            constant tSpiClk    : time := tespi(this);          --! get current SPI period
            variable slv1       : std_logic_vector(0 downto 0); --! help
        begin
            -- iterate over message bytes
            for i in msg'low to msg'high loop
                -- iterate over bits in a single message byte
                for j in msg(i)'high downto msg(i)'low loop
                    -- dispatch mode
                    if ( C_GENERAL_IO_MODE_SEL_SGL = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) ) then
                    -- one bit per clock cycle transferred
                        SCK                 <= '0';                                                 --! falling edge
                        wait for tSpiClk/2;                                                         --! half clock cycle
                        SCK                 <= '1';                                                 --! rising edge
                        slv1(0 downto 0)    := std_logic_vector(TO_01(unsigned(DIO(1 downto 1))));  --! help
                        msg(i)(j)           := slv1(0);                                             --! capture data from line
                        wait for tSpiClk/2;                                                         --! half clock cycle
                    elsif ( C_GENERAL_IO_MODE_SEL_DUAL = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) ) then
                    -- two bits per clock cycle are transfered
                        if ( 0 = (j+1) mod 2 ) then
                            SCK                     <= '0';                                                 --! falling edge
                            wait for tSpiClk/2;                                                             --! half clock cycle
                            SCK                     <= '1';                                                 --! rising edge
                            msg(i)(j downto j-1)    := std_logic_vector(TO_01(unsigned(DIO(1 downto 0))));  --! capture data from line
                            wait for tSpiClk/2;                                                             --! half clock cycle
                        end if;
                    elsif ( C_GENERAL_IO_MODE_SEL_QUAD = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range) ) then
                    -- four bits per clock cycle are transfered
                        if ( 0 = (j+1) mod 4 ) then
                            SCK                     <= '0';                                                 --! falling edge
                            wait for tSpiClk/2;                                                             --! half clock cycle
                            SCK                     <= '1';                                                 --! rising edge
                            msg(i)(j downto j-3)    := std_logic_vector(TO_01(unsigned(DIO(3 downto 0))));  --! capture data from line
                            wait for tSpiClk/2;                                                             --! half clock cycle
                        end if;
                    else
                        -- unsupported transfer mode
                        if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:spiRx: unsupported transfer mode 0x" & to_hstring(this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_IO_MODE_SEL'range)) severity error; end if;
                        return;
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
                constant intRxByte  : in integer                            --! interrupts procedure after byte count
            )
        is
            constant tSpiClk    : time := tespi(this);      --! get current SPI period
            variable crcMsg     : tMemX08(0 to msg'length); --! message with calculated CRC
            variable rxStart    : integer;                  --! start index in message
            variable rxStop     : integer;                  --! stop index in message
            variable dropCRC    : boolean;                  --! if true CRC is from return message removed
            variable termCon    : boolean;                  --! terminates connection to slave
            variable prtRx      : boolean;                  --! print RX packet to console log
        begin
            -- entry message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:spiXcv"; end if;
            -- some checks
            if ( (msg'length < txByte) or (msg'length < rxByte) ) then
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:spiXcv: Not enough memory allocated" severity error; end if;
                this.slaveResponse := FATAL_ERROR;
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
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:spiXcv: Something went wrong" severity error; end if;
                this.slaveResponse := FATAL_ERROR;
                return;
            end if;
            -- only send if number of tx bytes specified, otherwise in the middle of a packet
            if ( -1 /= txByte ) then
                -- prepare data
                crcMsg(0 to txByte-1)    := msg(0 to txByte-1);          --! copy request
                crcMsg(txByte)           := crc8(crcMsg(0 to txByte-1)); --! append CRC
                -- print send message to console
                if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:spiXcv:Tx: " & hexStr(crcMsg(0 to txByte)); end if;
                -- start
                CSn <= '0';                                         --! enable Slave
                spiTx(this, crcMsg(0 to txByte), SCK, DIO);         --! write to slave
                spiTar(this, SCK, DIO);                             --! change direction (write-to-read), two cycles
                spiRx(this, crcMsg(0 to 0), SCK, DIO);              --! read only response field
                while ( WAIT_STATE = decodeRsp(crcMsg(0)) ) loop    --! wait for response ready
                    spiRx(this, crcMsg(0 to 0), SCK, DIO);          --! read from slave
                end loop;
                this.slaveResponse := decodeRsp(crcMsg(0)); --! decode response
            end if;
            -- acquire RX packet
            if ( ACCEPT = this.slaveResponse ) then --! all fine
                -- fetch pending bytes
                spiRx(this, crcMsg(rxStart+1 to rxStop), SCK, DIO);
            elsif ( DEFER = this.slaveResponse ) then   --! defer (1Byte) returns slave status (2Byte) and CRC (1Byte)
                -- fetch pending bytes
                rxStop  := 3;                               --! in defer (1Byte) returns slave status (2Byte) and CRC (1Byte)
                spiRx(this, crcMsg(1 to rxStop), SCK, DIO); --! read from slave,
                -- mark as finished packet, if it was planed as interrupted packet, after DEFER new read cycle
                dropCRC := true;                            --! only one byte fetched from slave
                termCon := true;                            --! connection to slave can closed
                prtRx   := true;
            elsif ( NO_RESPONSE = this.slaveResponse ) then
                rxStop  := 0;
                dropCRC := false;   --! only one byte fetched from slave
                termCon := true;    --! connection to slave can closed
                prtRx   := true;    --! print no response to console
            else
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:spiXcv: unexpected response '" & rsp2str(this.slaveResponse) & "'" severity error; end if;
                termCon := true;    --! close slaves connection
            end if;
            -- return CRC?
            if ( dropCRC ) then
                -- check crc
                if (not checkCRC(this, crcMsg(0 to rxStop))) then
                    this.slaveResponse := FATAL_ERROR;  --! Table 4: Response Field Encodings, It is also the default response when fatal CRC error is detected on the command packet; Here: also used for response
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:spiXcv:Rx:CRC failed" severity error; end if;
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
                wait for tSpiClk/2; --! half clock cycle
                CSn <= '1';
                wait for tSpiClk;   --! limits CSn bandwidth to SCK
            end if;
            -- print receive message to console
            if ( prtRx ) then
                if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:spiXcv:Rx: " & hexStr(crcMsg(0 to rxStop)); end if;
            end if;
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
                constant numRxByte  : in integer                            --! response length in bytes
            )
        is
        begin
            -- map to interruptible transceiver procedure
                -- spiXcv( this, msg, CSn, SCK, DIO, txByte, rxByte, intRxByte )
            spiXcv( this, msg, CSn, SCK, DIO, numTxByte, numRxByte, numRxByte );
        end procedure spiXcv;
        --***************************

    ----------------------------------------------


    ----------------------------------------------
    -- eSPI Slave Management
    ----------------------------------------------

        --***************************
        -- RESET: sends reset sequence to slave
        --  @see 9.3.2 In-band RESET Command
        procedure RESET
            (
                variable this       : inout tESpiBfm;
                signal CSn          : out std_logic;
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0)    --! bidirectional data
            )
        is
            constant tSpiClk : time := 1 sec / 20_000_000;  --! It is sent with the 20MHz speed or lower.
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:RESET"; end if;
            -- select slave
            CSn <= '0';
            DIO <= (others => '1');
            wait for tSpiClk/2;
            -- do reset sequence
            for i in 0 to 15 loop
                SCK <= '1';
                wait for tSpiClk/2;
                SCK <= '0';
                wait for tSpiClk/2;
            end loop;
            CSn <= '1';
            DIO <= (others => 'Z');
            -- Reset master registers according spec
            --   eSPI Interface Base Specification, 2016, Revision 1.0, 327432-002, p. 128
            --   008h-00Bh: General Capabilities and Configurations to default reset value
            init_cap_reg_08( this );
            -- make captures slave status invalid
            this.slaveStatus := (others => 'X');
            -- limits CSn bandwidth to SCK
            wait for tSpiClk;
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
                variable status     : out std_logic_vector(15 downto 0)
            )
        is
            variable msg    : tMemX08(0 to 6);                                      --! eSpi message buffer
            variable cfg    : std_logic_vector(config'range) := (others => '0');    --! internal buffer
            variable sts    : std_logic_vector(status'range) := (others => '0');    --! internal buffer
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:GET_CONFIGURATION"; end if;
            -- default assignments
            status              := (others => '0');
            config              := (others => '0');
            this.slaveResponse  := FATAL_ERROR;
            -- check address for 32bit alignment
            if ( 0 /= (unsigned(adr) mod 4) ) then
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:GET_CONFIGURATION: address 0x" & to_hstring(adr) & "not 32Bit aligned" severity error; end if;
                return;
            end if;
            -- build command
            msg     := (others => (others => '0')); --! clear
            msg(0)  := C_GET_CONFIGURATION;         --! Command
            msg(1)  := adr(15 downto 8);            --! high byte address
            msg(2)  := adr(7 downto 0);             --! low byte address
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
            spiXcv(this, msg, CSn, SCK, DIO, 3, 7); --! CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = this.slaveResponse ) then
                this.slaveRegs(to_integer(unsigned(adr)/4)) := msg(4) & msg(3) & msg(2) & msg(1);    --! extract and assemble config for store in bfm
                config                                      := msg(4) & msg(3) & msg(2) & msg(1);    --! extract and assemble config
                this.slaveStatus                            := msg(6) & msg(5);                      --! bfm internal
                status                                      := this.slaveStatus;                     --! propagate
            end if;
        end procedure GET_CONFIGURATION;
        --***************************


        --***************************
        -- GET_CONFIGURATION
        --   @see Figure 22: GET_CONFIGURATION Command
        procedure GET_CONFIGURATION
            (
                variable this   : inout tESpiBfm;                       --! common BFM handle
                signal CSn      : out std_logic;                        --! slave select
                signal SCK      : out std_logic;                        --! shift clock
                signal DIO      : inout std_logic_vector(3 downto 0);   --! data lines
                constant adr    : in std_logic_vector(15 downto 0);     --! slave registers address
                variable config : out std_logic_vector(31 downto 0);    --! read value
                variable good   : inout boolean                         --! successful?
            )
        is
            variable sts : std_logic_vector(15 downto 0);   --! wrapper variable for status
            variable cfg : std_logic_vector(31 downto 0);   --! wrapper for config
        begin
            -- get configuration
            GET_CONFIGURATION( this, CSn, SCK, DIO, adr, cfg, sts );
            -- in case of no output print to console
            if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(sts); end if; --! INFO: print status
            -- Function is good?
            if ( ACCEPT /= this.slaveResponse ) then
                good    := false;
                config  := (others => 'X');
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:GET_CONFIGURATION:Slave " & rsp2str(this.slaveResponse) severity error; end if;
            else
                config  := cfg;
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
                variable status     : out std_logic_vector(15 downto 0)
            )
        is
            variable msg    : tMemX08(0 to 6);                                      --! eSpi message buffer
            variable cfg    : std_logic_vector(config'range) := (others => '0');    --! internal buffer
            variable sts    : std_logic_vector(status'range) := (others => '0');    --! internal buffer
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:SET_CONFIGURATION"; end if;
            -- default
            status              := (others => '0');
            this.slaveResponse  := FATAL_ERROR;
            -- check address for 32bit alignment
            if ( 0 /= (unsigned(adr) mod 4) ) then
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:SET_CONFIGURATION: address 0x" & to_hstring(adr) & "not 32Bit aligned" severity error; end if;
                return;
            end if;
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
            spiXcv(this, msg, CSn, SCK, DIO, 7, 3); --! CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = this.slaveResponse ) then
                this.slaveRegs(to_integer(unsigned(adr)/4)) := config;              --! bfm internal
                this.slaveStatus                            := msg(2) & msg(1);     --! status
                status                                      := this.slaveStatus;    -- external
            end if;
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
            )
        is
            variable sts : std_logic_vector(15 downto 0);   --! wrapper variable for status
        begin
            -- get configuration
            SET_CONFIGURATION( this, CSn, SCK, DIO, adr, config, sts );
            -- in case of no output print to console
            if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(sts); end if; --! INFO: print status
            -- Slave good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:SET_CONFIGURATION:Slave " & rsp2str(this.slaveResponse) severity error; end if;
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
                variable status     : out std_logic_vector(15 downto 0)
            )
        is
            variable msg    : tMemX08(0 to 2);  --! eSpi message buffer
        begin
            -- assemble command
            msg     := (others => (others => '0')); --! clear
            msg(0)  := C_GET_STATUS;
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
            spiXcv(this, msg, CSn, SCK, DIO, 1, 3); --! CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = this.slaveResponse ) then
                this.slaveStatus := msg(2) & msg(1); --! status
            else
                this.slaveStatus := (others => 'X');
            end if;
            -- propagate response
            status      := this.slaveStatus;
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
            )
        is
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stucking
        begin
            -- acquire status
                -- GET_STATUS(this, CSn, SCK, DIO, status, response, good)
            GET_STATUS(this, CSn, SCK, DIO, sts);
            -- in case of no output print to console
            if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(sts); end if; --! INFO: print status
            -- Slave request good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:GET_STATUS:Slave " & rsp2str(this.slaveResponse) severity error; end if;
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
                variable data       : out   tMemX08                         --! read data, 1/2/4 Bytes supported
            )
        is
            variable tiout      : natural;                          --! counter for tiout
            variable msg        : tMemX08(0 to data'length + 6);    --! +1Byte Response, +3Byte Header, +2Byte Status
            variable dlen_slv   : std_logic_vector(11 downto 0);    --! data field length
            variable dlen       : integer range 0 to 1024;          --! data length of completion packet
            variable cycTyp     : std_logic_vector(7 downto 0);     --! cycle type, @see:
            variable tag        : std_logic_vector(3 downto 0);     --! tag, @see:
            variable slv16      : std_logic_vector(15 downto 0);    --! temporary variable
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:RD_DEFER_PC_AVAIL: Acquires read data after DEFER"; end if;
            -- check for PC_AVAIL
            tiout   := 0;
            while ( ("0" = this.slaveStatus(C_STS_PC_AVAIL'range)) and tiout < this.tioutStatusPoll ) loop  --! no PC_AVAIL, wait for it
                -- check slave status
                    -- GET_STATUS ( this, CSn, SCK, DIO, status )
                GET_STATUS ( this, CSn, SCK, DIO, slv16 ); --! status captures BFM internally
                if ( ACCEPT /= this.slaveResponse ) then
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:RD_DEFER_PC_AVAIL: GET_STATUS failed with '" & rsp2str(this.slaveResponse) & "'" severity error; end if;
                    this.slaveResponse := FATAL_ERROR;  --! make to fail
                    exit;                               --! leave loop
                end if;
                -- inc tiout counter
                tiout := tiout + 1;
            end loop;
            -- check for reach tiout
            if ( (tiout = this.tioutStatusPoll) and ("0" = this.slaveStatus(C_STS_PC_AVAIL'range)) ) then
                this.slaveResponse := NO_RESPONSE;  --! no data available
                if ( this.verbose >= C_MSG_WARN ) then Report "eSpiMasterBfm:RD_DEFER_PC_AVAIL: No data available in allowed response time" severity warning; end if;
            end if;
            -- fetch data from slave
            if ( ((ACCEPT = this.slaveResponse) or (DEFER = this.slaveResponse)) and ("1" = this.slaveStatus(C_STS_PC_AVAIL'range)) ) then   --! no ero and data is available
                -- user message
                if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:RD_DEFER_PC_AVAIL: PC_AVAIL"; end if;
                -- assemble Posted completion message
                msg     := (others => (others => '0')); --! init message array
                msg(0)  := C_GET_PC;                    --! request posted completion
                -- @see: Figure 36: Peripheral Memory Read Packet Format
                -- @see: Figure 39: Peripheral Memory or I/O Completion With and Without Data Packet Format
                -- numRxByte: +1Byte Response, +3Byte Header, +2Byte Status
                    -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte, response)
                spiXcv(this, msg, CSn, SCK, DIO, 1, data'length+6);    --! CRC added and checked by transceiver procedure
                -- slave has the data?
                if ( ACCEPT = this.slaveResponse ) then
                    -- disassemble read packet, @see: Figure 39: Peripheral Memory or I/O Completion With and Without Data Packet Format
                    cycTyp              := msg(1);                                              --! cycle type
                    tag                 := msg(2)(7 downto 4);                                  --! tag
                    dlen_slv            := msg(2)(3 downto 0) & msg(3);                         --! intermediate
                    dlen                := to_integer(unsigned(dlen_slv));                      --! data length
                    data                := msg(4 to data'length + 4 - 1);                       --! data
                    this.slaveStatus    := msg(4 + data'length + 2) & msg(4 + data'length + 1); --! status register
                    -- Some Info
                    if ( this.verbose >= C_MSG_INFO ) then
                        -- print to console log
                        Report                                                                character(LF) &
                                "     PC Details:"                                          & character(LF) &
                                "       Cycle Type : "      & ct2str(cycTyp)                & character(LF) &
                                "       Tag        : 0x"    & to_hstring(tag)               & character(LF) &
                                "       Length     : "      & integer'image(dlen)   & "d";
                    end if;
                    -- check
                    if ( dlen /= data'length ) then
                        if ( this.verbose >= C_MSG_WARN ) then Report "eSpiMasterBfm:RD_DEFER_PC_AVAIL: Request not completely completed, pad with zeros" severity warning; end if;
                    end if;
                end if;
            else
                this.slaveStatus := (others => 'X');    --! make invalid
            end if;
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
            )
        is
            constant tSpiClk : time := tespi(this); --! get current SPI period
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:WAIT_ALERT"; end if;
            -- wait for alert
            while ( true ) loop
                if ( "1" = this.slaveRegs(to_integer(unsigned(C_GENERAL)/4))(C_GENERAL_ALERT_MODE'range) ) then
                    if ( '0' = to_bit(std_ulogic(ALERTn), '1') ) then
                        wait for tSpiClk/2;             --! limit bandwidth
                        CSn <= '0';                     --! ACK alert
                        wait until rising_edge(ALERTn); --! wait for slave; true: from low value ('0' or 'L') to high value ('1' or 'H').
                        if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:WAIT_ALERT: ALERTn signals alert"; end if;
                        exit;                           --! go on with status
                    end if;
                else
                    if ( '0' = to_bit(std_ulogic(DIO(1)), '1') ) then
                        wait for tSpiClk/2;
                        CSn <= '0';
                        wait until rising_edge(DIO(1));
                        if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:WAIT_ALERT: DIO[1] signals alert"; end if;
                        exit;
                    end if;
                end if;
                wait for tSpiClk/2;
            end loop;
            wait for tSpiClk;   --! limit bandwidth
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
                constant data       : in tMemX08
            )
        is
            variable msg        : tMemX08(0 to data'length + 9);    --! 4Byte Address, Length 1Byte, Length/Tag 1Byte, Cycle Type 1Byte, CMD 1Byte, CRC 1Byte
            variable dLenSlv    : std_logic_vector(11 downto 0);    --! needed for 'PUT_MEMWR32_SHORT'
            variable msgLen     : natural := 0;                     --! message length can vary
            variable rsp        : tESpiRsp;                         --! Slaves response to performed request
            variable sts        : std_logic_vector(15 downto 0);    --! status
            variable tiout      : natural := this.tioutStatusPoll;  --! status retry time out
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:MEMWR32"; end if;
            -- check for NP_FREE
            --   poll status if not free
            while ( "1" /= this.slaveStatus(C_STS_NP_FREE'range) ) loop
                    -- GET_STATUS ( this, CSn, SCK, DIO, status )
                GET_STATUS ( this, CSn, SCK, DIO, sts );
                -- Slave request good?
                if ( ACCEPT /= this.slaveResponse ) then
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:MEMWR32:Slave " & rsp2str(this.slaveResponse) severity error; end if;
                    return;
                end if;
                -- tiout?
                tiout := tiout - 1; -- decrement time out counter
                if ( 0 = tiout ) then
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:MEMWR32:Slave:GET_STATUS retry time out reached, giving up..." severity error; end if;
                    this.slaveResponse  := FATAL_ERROR;
                    return;
                end if;
            end loop;
            -- prepare
            msg := (others => (others => '0'));                                         --! init message array
            -- determine instruction type
            if ( (1 = data'length) or (2 = data'length) or (4 = data'length ) ) then    --! PUT_MEMWR32_SHORT; Figure 35: Short Peripheral Memory or Short I/O Write Packet Format (Master Initiated only)
                -- user message
                if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:MEMWR32: PUT_MEMWR32_SHORT"; end if;
                -- build instruction
                dLenSlv := std_logic_vector(to_unsigned(data'length - 1, dLenSlv'length));  --! number of bytes
                msg(0)  := C_PUT_MEMWR32_SHORT & dLenSlv(1 downto 0);
                msgLen  := msgLen + 1;
            else                                                                        --! PUT_NP; Figure 34: Peripheral Memory Write Packet Format
                -- user message
                if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:MEMWR32: PUT_PC"; end if;
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
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte)
            spiXcv(this, msg, CSn, SCK, DIO, msgLen, 3);    --! CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = this.slaveResponse ) then
                this.slaveStatus := msg(2) & msg(1); --! status
            else
                this.slaveStatus := (others => 'X');
            end if;
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
            )
        is
            variable dBuf   : tMemX08(0 to 0);                  --! captures single data word
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stucking
        begin
            -- fill in data
            dBuf(0) := data;
                -- MEMWR32(this, CSn, SCK, DIO, adr, data)
            MEMWR32(this, CSn, SCK, DIO, adr, dBuf);
            -- Slave request good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:MEMWR32:Slave " & rsp2str(this.slaveResponse) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(sts); end if; --! INFO: print status
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
            )
        is
            variable sts    : std_logic_vector(15 downto 0);    --! needed for stucking
        begin
                -- MEMWR32(this, CSn, SCK, DIO, adr, data)
            MEMWR32(this, CSn, SCK, DIO, adr, data);
            -- Slave request good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:MEMWR32:Slave " & rsp2str(this.slaveResponse) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(sts); end if; --! INFO: print status
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
                variable data       : out tMemX08
            )
        is
            variable msg        : tMemX08(0 to data'length + 9);    --! 4Byte Address, Length 1Byte, Length/Tag 1Byte, Cycle Type 1Byte, CMD 1Byte, CRC 1Byte
            variable dataLenSlv : std_logic_vector(11 downto 0);    --! needed for 'PUT_MEMWR32_SHORT'
            variable msgLen     : integer := 0;                     --! message length can vary
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:MEMRD32"; end if;
            -- init
            msg                 := (others => (others => '0'));
            this.slaveResponse  := FATAL_ERROR;
            -- determine instruction type
            if ( (1 = data'length) or (2 = data'length) or (4 = data'length ) ) then    --! CMD: PUT_MEMWR32_SHORT
                -- user message
                if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:MEMRD32: PUT_MEMRD32_SHORT instruction"; end if;
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
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:MEMRD32: NOT IMPLEMENTED CALL " severity error; end if;
                this.slaveResponse := FATAL_ERROR;
                return;
            end if;
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte)
            spiXcv(this, msg, CSn, SCK, DIO, msgLen, data'length+3);    --! xByte Data, +1Byte Response, +2Byte Status, CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = this.slaveResponse ) then
                data                := msg(1 to data'length);                   --! extract data from message
                this.slaveStatus    := msg(data'length+2) & msg(data'length+1); --! status
            else
                this.slaveStatus    := (others => 'X');
            end if;
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
            )
        is
            variable dBuf   : tMemX08(0 to 0);
        begin
                -- MEMRD32(this, CSn, SCK, DIO, adr, data, status, response)
            MEMRD32(this, CSn, SCK, DIO, adr, dBuf);
            -- Slave request good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:MEMRD32:Slave " & rsp2str(this.slaveResponse) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(this.slaveStatus); end if; --! INFO: print status
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
                constant data       : in tMemX08                            --! write data, 1/2/4 Bytes supported
            )
        is
            variable msg    : tMemX08(0 to data'length + 3);    --! CMD 1Byte, 2Byte Address
            variable msgLen : natural := 0;                     --! message length can vary
            variable sts    : std_logic_vector(15 downto 0);    --! status
            variable tiout  : natural := this.tioutStatusPoll;  --! status retry time out
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:IOWR: PUT_IOWR_SHORT"; end if;
            -- check length
            if not ( (1 = data'length) or (2 = data'length) or (4 = data'length ) ) then    --! PUT_IOWR_SHORT; Figure 26: Master Initiated Short Non-Posted Transaction
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IOWR: data length " & integer'image(data'length) & " unsupported; Only 1/2/4 Bytes allowed" severity error; end if;
                return;
            end if;
            -- check for NP_FREE
            --   poll status if not free
            while ( "1" /= this.slaveStatus(C_STS_NP_FREE'range) ) loop
                    -- GET_STATUS ( this, CSn, SCK, DIO )
                GET_STATUS ( this, CSn, SCK, DIO, sts );
                -- Slave request good?
                if ( ACCEPT /= this.slaveResponse ) then
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IOWR:Slave " & rsp2str(this.slaveResponse) severity error; end if;
                    return;
                end if;
                -- tiout?
                tiout := tiout - 1; -- decrement time out counter
                if ( 0 = tiout ) then
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IOWR:Slave:GET_STATUS retry time out reached, giving up..." severity error; end if;
                    this.slaveResponse := FATAL_ERROR; --! retry reached
                    return;
                end if;
            end loop;
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
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte)
            spiXcv(this, msg, CSn, SCK, DIO, msgLen, 3);   --! CRC added and checked by transceiver procedure
            -- process slaves response
            if ( ACCEPT = this.slaveResponse ) then
                this.slaveStatus := msg(2) & msg(1); --! status
            else
                this.slaveStatus := (others => 'X');
            end if;
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
            )
        is
            variable dBuf   : tMemX08(0 to 0);
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:IOWR_BYTE"; end if;
            -- fill in data
            dBuf(0) := data;
                -- IOWR( this, CSn, SCK, DIO, adr, data )
            IOWR( this, CSn, SCK, DIO, adr, dBuf );
            -- Slave request good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IOWR:Slave " & rsp2str(this.slaveResponse) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(this.slaveStatus); end if; --! INFO: print status
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
            )
        is
            variable dBuf       : tMemX08(0 to 1);
            variable adr_word   : std_logic_vector(adr'range);      --! word aligned address
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:IOWR_WORD"; end if;
            -- check alignment
            if ( "0" /= adr(0 downto 0) ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IOWR_WORD: not WORD (16bit) aligned address." severity error; end if;
                return;
            end if;
            -- prepare
            adr_word    := adr(adr'left downto adr'right + 1) & "0";    --! align addresses to data width
            dBuf(0)     := data(7 downto 0);                            --! fill in data
            dBuf(1)     := data(15 downto 8);                           --!
                -- IOWR( this, CSn, SCK, DIO, adr, data )
            IOWR( this, CSn, SCK, DIO, adr_word, dBuf );
            -- Slave request good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IOWR_WORD:Slave " & rsp2str(this.slaveResponse) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(this.slaveStatus); end if; --! INFO: print status
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
            )
        is
            variable dBuf       : tMemX08(0 to 3);
            variable adr_dword  : std_logic_vector(adr'range);      --! word aligned address
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:IOWR_DWORD"; end if;
            -- check alignment
            if ( "00" /= adr(1 downto 0) ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IOWR_DWORD: not DWORD (32bit) aligned address." severity error; end if;
                return;
            end if;
            -- prepare
            adr_dword   := adr(adr'left downto adr'right + 2) & "00";   --! align addresses to data width
            dBuf(0)     := data(7 downto 0);                            --! fill in data
            dBuf(1)     := data(15 downto 8);                           --!
            dBuf(2)     := data(23 downto 16);                          --!
            dBuf(3)     := data(31 downto 24);                          --!
                -- IOWR( this, CSn, SCK, DIO, adr, data )
            IOWR( this, CSn, SCK, DIO, adr_dword, dBuf );
            -- Slave request good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IOWR:Slave " & rsp2str(this.slaveResponse) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(this.slaveStatus); end if; --! INFO: print status
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
            )
        is
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
                constant adr        : in std_logic_vector(15 downto 0); --! IO space address, 16Bits
                variable data       : out tMemX08                       --! read data, 1/2/4 Bytes supported
            )
        is
            variable msg    : tMemX08(0 to data'length + 6);    --! +1Byte Response, +3Byte Header, +2Byte Status
            variable tiout  : natural := 0;                     --! tiout counter
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:IORD: PUT_IORD_SHORT"; end if;
            -- check length
            if not ( (1 = data'length) or (2 = data'length) or (4 = data'length ) ) then    --! PUT_IOWR_SHORT; Figure 26: Master Initiated Short Non-Posted Transaction
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IORD: data length " & integer'image(data'length) & " unsupported; Only 1/2/4 Bytes allowed" severity error; end if;
                this.slaveResponse := FATAL_ERROR;  --! invalid data length used
                return;                             --! leave procedure
            end if;
            -- prepare data packet
            msg     := (others => (others => '0'));                                             --! init message array
            msg(0)  := C_PUT_IORD_SHORT & std_logic_vector(to_unsigned(data'length - 1, 2));    --! CPUT_IORD_SHORT w/ 1/2/4 data bytes
            msg(1)  := adr(15 downto 8);
            msg(2)  := adr(7 downto 0);
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte)
            spiXcv(this, msg, CSn, SCK, DIO, 3, data'length+3);    --! CRC added and checked by transceiver procedure
            -- slave has the data?
            if ( ACCEPT = this.slaveResponse ) then --! data is in response
                -- data ready
                this.slaveStatus    := msg(data'length+2) & msg(data'length+1); --! status register
                data                := msg(1 to data'length - 1 + 1);           --! data bytes
            elsif ( DEFER = this.slaveResponse ) then   --! Wait, Figure 25: Deferred Master Initiated Non-Posted Transaction
                -- wait for data
                this.slaveStatus    := msg(2) & msg(1); --! status
                    -- RD_DEFER_PC_AVAIL( this, CSn, SCK, DIO, data )
                RD_DEFER_PC_AVAIL( this, CSn, SCK, DIO, data );
            else
                this.slaveStatus := (others => 'X');    --! invalid
            end if;
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
            )
        is
            variable dBuf   : tMemX08(0 to 0);
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:IORD_BYTE"; end if;
            -- prepare
            dBuf := (others => (others => '0'));    -- init
                -- IORD( this, CSn, SCK, DIO, adr, data )
            IORD( this, CSn, SCK, DIO, adr, dBuf );
            -- Slave request good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                data := (others => '0');    --! make invalid
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IORD:Slave " & rsp2str(this.slaveResponse) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(this.slaveStatus); end if; --! INFO: print status
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
            )
        is
            variable dBuf       : tMemX08(0 to 1);
            variable adr_word   : std_logic_vector(adr'range);      --! word aligned address
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:IORD_WORD"; end if;
            -- check alignment
            if ( "0" /= adr(0 downto 0) ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IORD_WORD: not WORD (16bit) aligned address." severity error; end if;
                return;
            end if;
            -- prepare
            adr_word    := adr(adr'left downto adr'right + 1) & "0";    --! align addresses to data width
            dBuf        := (others => (others => '0'));                 --! init
                -- IORD( this, CSn, SCK, DIO, adr, data, )
            IORD( this, CSn, SCK, DIO, adr_word, dBuf );
            -- Slave request good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                data := (others => '0');    --! make invalid
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IORD:Slave " & rsp2str(this.slaveResponse) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(this.slaveStatus); end if; --! INFO: print status
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
            )
        is
            variable dBuf       : tMemX08(0 to 3);
            variable adr_dword  : std_logic_vector(adr'range);      --! word aligned address
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:IORD_WORD"; end if;
            -- check alignment
            if ( "00" /= adr(1 downto 0) ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IORD_DWORD: not DWORD (32bit) aligned address." severity error; end if;
                return;
            end if;
            -- prepare
            adr_dword   := adr(adr'left downto adr'right + 2) & "00";   --! align addresses to data width
            dBuf        := (others => (others => '0'));                 --! init
                -- IORD( this, CSn, SCK, DIO, adr, data )
            IORD( this, CSn, SCK, DIO, adr_dword, dBuf );
            -- Slave request good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                data := (others => '0');    --! make invalid
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:IORD:Slave " & rsp2str(this.slaveResponse) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(this.slaveStatus); end if; --! INFO: print status
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
            )
        is
        begin
                -- IORD_BYTE( this, CSn, SCK, DIO, adr, data, good )
            IORD_BYTE( this, CSn, SCK, DIO, adr, data, good );          --! default IORD is byte operation
        end procedure IORD;
        --***************************

    ----------------------------------------------



    ----------------------------------------------
    -- Virtual Channel
    ----------------------------------------------

        --***************************
        -- Updates VW shadow registers
        --   @see Table 9: Virtual Wire Index Definition
        procedure VW_UPDATE_BFM
            (
                variable this           : inout tESpiBfm;   --! common handle
                constant virtualWire    : in tMemX08;       --! virtual wire index/data pairs
                variable good           : inout boolean     --! successful
            )
        is
            constant vw : tMemX08(0 to virtualWire'length-1) := virtualWire;    --! zero align
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:VW_UPDATE_BFM"; end if;
            -- nothing to update?
            if ( 0 = vw'length ) then
                return;
            end if;
            -- only index/value pairs
            if ( 0 /= (vw'length mod 2) ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:VW_UPDATE_BFM: corrupted virtual wire data, no index/value pairs" severity error; end if;
                return;
            end if;
            -- process data and update BFM shadow registers
            -- first: index
            -- second: data
            for i in 0 to vw'length/2 - 1 loop
                -- IRQ (indexes: 0-1)
                if ( (0 <= to_integer(to_01(unsigned(vw(2*i))))) and  (to_integer(to_01(unsigned(vw(2*i)))) <= 1) ) then
                    this.virtualWires(to_integer(to_01(unsigned(vw(2*i))))) := vw(2*i+1);   --! store in BFM
                -- Packed Wires (indexes: 2-7, 64-71, 128-255)
                elsif   (       ((C_SYSEVENT_NAME'low <= to_integer(to_01(unsigned(vw(2*i))))) and (to_integer(to_01(unsigned(vw(2*i)))) <= C_SYSEVENT_NAME'high))  --! index=2-7: system event wire
                            or  ((C_SRV_PFM_NAME'low <= to_integer(to_01(unsigned(vw(2*i)))))  and (to_integer(to_01(unsigned(vw(2*i)))) <= C_SRV_PFM_NAME'high))   --! index=64-71: Server Platform Specific Virtual Wire
                            or  ((128 <= to_integer(to_01(unsigned(vw(2*i)))))                 and (to_integer(to_01(unsigned(vw(2*i)))) <= 255))                   --! index=128-255: GPIO wires
                        ) then
                    -- iterate over packed virtual wires
                    for j in 0 to 3 loop
                        if ( '1' = vw(2*i+1)(j+4) ) then
                            this.virtualWires(to_integer(to_01(unsigned(vw(2*i)))))(j+4) := '1';
                            this.virtualWires(to_integer(to_01(unsigned(vw(2*i)))))(j)   := vw(2*i+1)(j);
                        end if;
                    end loop;
                -- Binary
                elsif   (       ((8 <= to_integer(to_01(unsigned(vw(2*i)))))    and (to_integer(to_01(unsigned(vw(2*i)))) <= 63))   --! index=8-63: Reserved?
                            or  ((72 <= to_integer(to_01(unsigned(vw(2*i)))))   and (to_integer(to_01(unsigned(vw(2*i)))) <= 127))  --! index=72-127: Platform specific wires, uninterpreted
                        ) then
                    this.virtualWires(to_integer(to_01(unsigned(vw(2*i))))) := vw(2*i+1);
                --! Unsupported
                else
                    good := false;
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:VW_UPDATE_BFM: Unsupported virtual wire index " & integer'image(to_integer(to_01(unsigned(vw(2*i))))) severity error; end if;
                    return;
                end if;
            end loop;
            -- print updated Wires to console
            if ( this.verbose >= C_MSG_INFO ) then
                    -- vw2str( virtualWires )
                Report "eSpiMasterBfm:VW_UPDATE_BFM" & character(LF) & vw2str(vw);
            end if;
        end procedure VW_UPDATE_BFM;
        --***************************


        --***************************
        -- Virtual Wire Channel Write
        -- PUT_VWIRE
        --   @see Figure 41: Virtual Wire Packet Format, Master Initiated Virtual Wire Transfer
        procedure VWIREWR
            (
                variable this           : inout tESpiBfm;
                signal CSn              : out std_logic;                        --! slave select
                signal SCK              : out std_logic;                        --! shift clock
                signal DIO              : inout std_logic_vector(3 downto 0);   --! data lines
                constant virtualWire    : in tMemX08                            --! virtual wire index/data pairs, @see Table 9: Virtual Wire Index Definition
            )
        is
            alias vw        : tMemX08(0 to virtualWire'length-1) is virtualWire;    --! zero align
            variable msg    : tMemX08(0 to vw'length + 2);                          --! CMD: 1Byte, Wire Count: 1Byte
            variable msgLen : natural := 0;                                         --! message length can vary
            variable pgood  : boolean;                                              --! help variable
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:VWIREWR: PUT_VWIRE instruction"; end if;
            -- nothing to update?
            if ( 0 = vw'length ) then
                return;
            end if;
            -- only index/value pairs
            if ( 0 /= (vw'length mod 2) ) then
                this.slaveResponse := FATAL_ERROR;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:VW_UPDATE_BFM: corrupted virtual wire data, no index/value pairs" severity error; end if;
                return;
            end if;
            -- virtual wires transfer length, TODO: get from Slave config
            if ( vw'length/2 > 63 ) then
                this.slaveResponse := FATAL_ERROR;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:VWIREWR: maximal length for vwire commands of 64 exceeded" severity error; end if;
            end if;
            -- init
            msg := (others => (others => '0'));
            -- assemble command
            msg(0)                              := C_PUT_VWIRE;
            msg(1)                              := "00" & std_logic_vector(to_unsigned(vw'length/2-1, 6));  --! set length of vwire message, 0-based count
            msgLen                              := msgLen+2;
            msg(msgLen to msgLen+vw'length/2)   := TO_01(vw);                                               --! add data, filter out all don't cares
            msgLen                              := msgLen+vw'length/2+1;
            -- send and get response
                -- spiXcv(this, msg, CSn, SCK, DIO, numTxByte, numRxByte)
            spiXcv(this, msg, CSn, SCK, DIO, msgLen, 3);    --! CRC added and checked by transceiver procedure
            -- update BFM
            pgood := true;
            if ( ACCEPT = this.slaveResponse ) then
                    -- VW_UPDATE_BFM( this, vw, good )
                VW_UPDATE_BFM( this, vw, pgood );
                -- Success?
                if not ( pgood ) then
                    this.slaveResponse := FATAL_ERROR;
                end if;
            end if;
            -- get slaves response
            if ( ACCEPT = this.slaveResponse ) then
                this.slaveStatus := msg(2) & msg(1); --! status
            else
                this.slaveStatus := (others => 'X');
            end if;
        end procedure VWIREWR;
        --***************************


        --***************************
        -- Virtual Wire Channel Write, w/o status/response register
        -- PUT_VWIRE
        --   @see Figure 41: Virtual Wire Packet Format, Master Initiated Virtual Wire Transfer
        procedure VWIREWR
            (
                variable this           : inout tESpiBfm;
                signal CSn              : out std_logic;                        --! slave select
                signal SCK              : out std_logic;                        --! shift clock
                signal DIO              : inout std_logic_vector(3 downto 0);   --! data lines
                constant virtualWire    : in tMemX08;                           --! virtual wire index/data pairs, @see Table 9: Virtual Wire Index Definition
                variable good           : inout boolean                         --! successful
            )
        is
        begin
            -- call more general function
                -- VWIREWR( this, CSn, SCK, DIO, virtualWire );
            VWIREWR( this, CSn, SCK, DIO, virtualWire );
            -- Slave response good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:VWIREWR:Slave " & rsp2str(this.slaveResponse) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(this.slaveStatus); end if; --! INFO: print status
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
            )
        is
            variable vw     : tMemX08(0 to 1);  --! virtual wire index, @see Table 9: Virtual Wire Index Definition, max. 64 virtual wires
            variable vwLen  : integer;
            variable pgood  : boolean;
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:VWIREWR"; end if;
            -- build virtual wire
            vwLen   := 0;
            pgood   := true;
            VW_ADD( this, name, value, vw, vwLen, pgood );  --! build virtual wire
            -- write to endpoint
            if ( good ) then
                VWIREWR( this, CSn, SCK, DIO, vw(0 to vwLen-1), pgood );
            end if;
            -- successful?
            if ( pgood ) then
                if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:VWIREWR: " & name & " = " & integer'image(to_integer(unsigned'('0' & to_stdulogic(value)))); end if;
            else
                if ( this.verbose >= C_MSG_WARN ) then Report "eSpiMasterBfm:VWIREWR: " & name & " Failed" severity warning; end if;
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
                variable this           : inout tESpiBfm;
                signal CSn              : out std_logic;                        --! slave select
                signal SCK              : out std_logic;                        --! shift clock
                signal DIO              : inout std_logic_vector(3 downto 0);   --! data lines
                variable virtualWire    : out tMemX08(0 to 127);                --! virtual wire index/data pairs, @see Table 9: Virtual Wire Index Definition
                variable virtualWireLen : out integer range 0 to 64             --! number of wire pairs
            )
        is
            variable msg        : tMemX08(0 to 2*64 + 1 + 2);       --! max. 64 Wires in same packet, +1 response, +2 status
            variable wireCnt    : natural;                          --! number of virtual wires
            variable pgood      : boolean;                          --! help variable
            variable slv16      : std_logic_vector(15 downto 0);    --! help variable
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:VWIRERD"; end if;
            -- init
            virtualWire := (others => (others => '0'));
            wireCnt     := 0;
            pgood       := true;
            -- check for virtual message available
                -- GET_STATUS ( this, CSn, SCK, DIO, status )
            GET_STATUS ( this, CSn, SCK, DIO, slv16 );
            if ( (ACCEPT = this.slaveResponse) and ("1" = this.slaveStatus(C_STS_VWIRE_AVAIL'range)) ) then
                -- message
                if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:VWIRERD:GET_VWIRE"; end if;
                -- acquire count of virtual wires
                msg     := (others => (others => '0')); -- clear
                msg(0)  := C_GET_VWIRE;
                    -- spiXcv( this, msg, CSn, SCK, DIO, txByte, rxByte, intRxByte );
                spiXcv( this, msg, CSn, SCK, DIO, 1, msg'length, 2 );
                -- Slave Accepted Request?
                if ( ACCEPT = this.slaveResponse ) then
                    -- extract wire count
                    wireCnt := to_integer(unsigned(msg(1)(5 downto 0))) + 1;    --! 0-based counter
                    if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:VWIRERD: number available wires = " & integer'image(wireCnt); end if;
                    -- fetch rest of packet
                        -- spiXcv( this, msg, CSn, SCK, DIO, txByte, rxByte, intRxByte );
                    spiXcv( this, msg, CSn, SCK, DIO, -1, 2+2*wireCnt+2, 2 );   --! +2: two bytes in first request, *2: per virtual wire 2byte, +2: Status register has two bytes
                    -- align
                    VW_UPDATE_BFM( this, msg(2 to 2*wireCnt+2-1), pgood );  --! internal storage
                    -- success?
                    if ( pgood ) then
                        virtualWire(0 to 2*wireCnt-1)   := msg(2 to 2*wireCnt+2-1); --! data to output
                        this.slaveStatus                := msg((wireCnt-1)*2 + 2 + 3) & msg((wireCnt-1)*2 + 2 + 2); --! +1 Response, +1 wire count, +1/+2 status bytes
                    else
                        this.slaveResponse := FATAL_ERROR;
                    end if;
                else
                    this.slaveResponse := FATAL_ERROR;
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:VWIRERD:GET_VWIRE: Slave Not accepted Request" severity error; end if;
                end if;
            else
                if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:VWIRERD: no virtual wires available"; end if;
            end if;
            -- assign to output
            virtualWireLen  := 2*wireCnt;
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
            )
        is
            variable vw     : tMemX08(0 to 127);                --! virtual wire index/data pairs, @see Table 9: Virtual Wire Index Definition
            variable vwLen  : integer range 0 to 64;            --! number of wire pairs
        begin
            -- read wires and print
                -- VWIRERD( this, CSn, SCK, DIO, vwireIdx, vwireData, vwireLen );
            VWIRERD( this, CSn, SCK, DIO, vw, vwLen );
            --slave request good?
            if ( ACCEPT /= this.slaveResponse ) then
                good := false;
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:VWIRERD:Slave " & rsp2str(this.slaveResponse) severity error; end if;
            else
                -- in case of no output print to console
                if ( this.verbose >= C_MSG_INFO ) then Report character(LF) & sts2str(this.slaveStatus); end if; --! INFO: print status
            end if;
        end procedure VWIRERD;
        --***************************

    ----------------------------------------------



    ----------------------------------------------
    -- Virtual Wire Helper
    ----------------------------------------------

        --***************************
        -- Virtual Wire: Add Virtual wire
        --   adds to virtual wire list a new index/data pair
        procedure VW_ADD
            (
                variable this   : inout tESpiBfm;   --! common storage element
                constant name   : in string;        --! Virtual wire name
                constant value  : in bit;           --! virtual wire value
                variable vw     : inout tMemX08;    --! virtual wire index, @see Table 9: Virtual Wire Index Definition
                variable vwLen  : inout natural;    --! effective list length
                variable good   : inout boolean     --! successful
            )
        is
            constant notValidElem   : tMemX08(0 to 1) := (others => (others => '-'));   --! not valid element
            variable appendElem     : tMemX08(0 to 1);                                  --! shall appended on virtual wire list
            variable vwPosAdd       : natural;                                          --! add element on position
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:VW_ADD"; end if;
            -- element can appended?
            if ( vwLen > vw'length ) then
                if ( this.verbose >= C_MSG_WARN ) then Report "eSpiMasterBfm:VW_ADD: not enough memory to append additional virtual wire" severity warning; end if;
                good := false;
                return;
            end if;
            -- create element to append
                -- newVW( name, value )
            appendElem := newVW( name, value );
            -- is valid?
            if ( appendElem = notValidElem ) then
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:VW_ADD: VW '" & name & "' not recognized" severity error; end if;
                good := false;
                return;
            end if;
            -- add to existing list
            vwPosAdd := vw'left + vwLen;    --! append
            for i in 0 to vwLen/2 - 1 loop
                -- index exist in list
                if ( vw(vw'left+2*i) = appendElem(0) ) then
                    -- check if element exist in list, max two transitions for a virtual wire allowed
                    if ( std_match(to_01(vw(vw'left+2*i+1)), appendElem(1)) ) then
                        if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:VW_ADD: '" & name & " = " & integer'image(to_integer(unsigned'('0' & to_stdulogic(value)))) & "' exists in list, no add"; end if;
                        return;
                    end if;
                    -- capture add position
                    vwPosAdd := vw'left + 2*i;  --! insert
                end if;
            end loop;
            -- Append mode?
            if ( vwPosAdd = vwLen ) then
                vw(vwPosAdd)    := (others => '0'); --! index
                vw(vwPosAdd+1)  := (others => '-'); --! data, can be packed in case of system event wires, therefore dc
                vwLen           := vwLen + 2;       --! update length
            end if;
            -- append/insert
            vw(vwPosAdd)    := appendElem(0);                           --! index
            vw(vwPosAdd+1)  := or_dc(vw(vwPosAdd+1), appendElem(1));    --! data, contents don't cares
            -- append info
            if ( this.verbose >= C_MSG_INFO ) then
                Report  "eSpiMasterBfm:VW_ADD: Virtual Wires "  & character(LF) &
                        "     Index/Data pairs : "              & hexStr(to_01(vw(vw'left to vwLen-1)));    --! dc's converted to '0', in eSPI '0'
            end if;
        end procedure VW_ADD;
        --***************************


        --***************************
        -- Virtual Wire: Waits until is equal
        --   waits until a virtual wire has the given value
        --   @see Table 9: Virtual Wire Index Definition
        procedure WAIT_VW_IS_EQ
            (
                variable this       : inout tESpiBfm;                       --! common bfm handle
                signal CSn          : out std_logic;                        --! slave select
                signal SCK          : out std_logic;                        --! shift clock
                signal DIO          : inout std_logic_vector(3 downto 0);   --! data lines
                signal ALERTn       : in std_logic;                         --! Alert
                constant vwNeedle   : in tMemX08;                           --! virtual wire index/data pairs to look for
                variable good       : inout boolean                         --! successful?
            )
        is
            variable waitDone   : boolean;  --! waiting for wires finished
            variable pgood      : boolean;  --! state of internal called procedures
        begin
            -- user message
            if ( this.verbose >= C_MSG_INFO ) then Report "eSpiMasterBfm:WAIT_VW_IS_EQ"; end if;
            -- nothing to update?
            if ( 0 = vwNeedle'length ) then
                if ( this.verbose >= C_MSG_WARN ) then Report "eSpiMasterBfm:WAIT_VW_IS_EQ: empty list provided"; end if;
                return;
            end if;
            -- only index/value pairs
            if ( 0 /= (vwNeedle'length mod 2) ) then
                if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:WAIT_VW_IS_EQ: corrupted virtual wire data, no index/value pairs" severity error; end if;
                good := false;
                return;
            end if;
            -- print virtual wires to wait for
            if ( this.verbose >= C_MSG_INFO ) then
                    -- vw2str( virtualWires )
                Report  "eSpiMasterBfm:WAIT_VW_IS_EQ: Wait for " & strtrim(vw2str(vwNeedle));
            end if;
            -- prepare
            waitDone    := false;   --! wait/poll for wires not finished
            pgood       := true;
            while ( pgood and (not waitDone) ) loop
                -- fetch new wires
                    -- VWIRERD( this, CSn, SCK, DIO, good )
                VWIRERD( this, CSn, SCK, DIO, pgood );  --! saves automatic into BFMs virtual wire buffer
                -- VWIRERD good?
                if ( not pgood ) then
                    if ( this.verbose >= C_MSG_ERROR ) then Report "eSpiMasterBfm:WAIT_VW_IS_EQ: virtual wire read failed" severity error; end if;
                    good := false;
                    return;
                end if;
                -- check bfm buffer
                for i in 0 to vwNeedle'length/2 - 1 loop
                    -- match?
                    if ( not std_match(this.virtualWires(to_integer(to_01(unsigned(vwNeedle(2*i))))), vwNeedle(2*i+1)) ) then
                        exit;   --! wait for new virtual wires
                    end if;
                    -- alls list elements processed
                    if ( i = vwNeedle'length/2 - 1) then
                        waitDone := true;
                        exit;
                    end if;
                end loop;
                -- wait for next virtual wire list only when "needle" list isn't completed
                if ( false = waitDone ) then
                    -- go to wait for ALERT only if no new wires are signaled in the slave status register
                    if ( "0" = this.slaveStatus(C_STS_VWIRE_AVAIL'range) ) then
                            -- WAIT_ALERT( this, CSn, SCK, DIO, ALERTn )
                        WAIT_ALERT( this, CSn, SCK, DIO, ALERTn );  --! wait for new wires
                    end if;
                end if;
            end loop;
        end procedure WAIT_VW_IS_EQ;
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
            )
        is
            variable vw     : tMemX08(0 to 1);  --! virtual wire index
            variable vwLen  : natural;          --! length of virtual wire
            variable pgood  : boolean := true;  --! internal good
        begin
            -- init
            vw      := (others => (others => '0'));
            vwLen   := 0;
            -- add wire
                -- VW_ADD( this, name, value, virtualWire, virtualWireLen, good );
            VW_ADD( this, wireName, wireVal, vw, vwLen, pgood );
            -- wires successful created?
            if ( pgood ) then
                -- go in wait
                    -- WAIT_VW_IS_EQ( this, CSn, SCK, DIO, ALERTn, vwNeedle good )
                WAIT_VW_IS_EQ( this, CSn, SCK, DIO, ALERTn , vw(0 to vwLen-1), good );
            else
                good := false;
            end if;
        end procedure WAIT_VW_IS_EQ;
        --***************************

    ----------------------------------------------


end package body eSpiMasterBfm;
--------------------------------------------------------------------------
