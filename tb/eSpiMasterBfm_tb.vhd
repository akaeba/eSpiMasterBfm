--************************************************************************
-- @author:     Andreas Kaeberlein
-- @copyright:  Copyright 2020
-- @credits:    AKAE
--
-- @license:    BSDv3
-- @maintainer: Andreas Kaeberlein
-- @email:      andreas.kaeberlein@web.de
--
-- @file:       eSpiMasterBfm_tb.vhd
-- @note:       VHDL'93
-- @date:       2020-04-01
--
-- @see:        https://github.com/akaeba/eSpiMasterBfm
-- @brief:      tests eSpiMasterBfm package functionality
--************************************************************************



--------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;         --! for UNIFORM, TRUNC
library work;
    use work.eSpiMasterBfm.all;     --! package under test
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- testbench
entity eSpiMasterBfm_tb is
generic (
            DO_ALL_TEST : boolean   := false        --! switch for enabling all tests
        );
end entity eSpiMasterBfm_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of eSpiMasterBfm_tb is

    -----------------------------
    -- Constant
        -- Test
        constant loopIter   : integer := 20;    --! number of test loop iteration
        constant doTest0    : boolean := true;  --! test0:  CRC8
        constant doTest1    : boolean := true;  --! test1:  GET_CONFIGURATION
        constant doTest2    : boolean := true;  --! test2:  SET_CONFIGURATION
        constant doTest3    : boolean := true;  --! test3:  GET_STATUS
        constant doTest4    : boolean := true;  --! test4:  MEMWR32
        constant doTest5    : boolean := true;  --! test5:  MEMRD32
        constant doTest6    : boolean := true;  --! test6:  RESET
        constant doTest7    : boolean := true;  --! test7:  IOWR
        constant doTest8    : boolean := true;  --! test8:  IORD
        constant doTest9    : boolean := true;  --! test9:  VWIRE Name
        constant doTest10   : boolean := true;  --! test10: VWIRERD
        constant doTest11   : boolean := true;  --! test11: VW_ADD, adds virtual wires to a list
        constant doTest12   : boolean := true;  --! test12: WAIT_VW_IS_EQ
        constant doTest13   : boolean := true;  --! test13: init, applies 'Exit G3 Sequence'
    -----------------------------


    -----------------------------
    -- Signals
        -- DUT
        signal CSn      : std_logic;
        signal SCK      : std_logic;
        signal DIO      : std_logic_vector(3 downto 0);
        signal ALERTn   : std_logic;
        signal RESETn   : std_logic;
        -- ESPI Static Slave
        signal slvGood  : boolean;              --! all request to slave good?
        signal REQMSG   : string(1 to 150);     --! request message
        signal CMPMSG   : string(1 to 150);     --! complete message, if request was ok
        signal LDMSG    : std_logic;            --! load message on rising edge
        -- Help
        signal foo      : std_logic;            --! init applies reset
    -----------------------------

begin

    ----------------------------------------------
    -- stimuli process
    p_stimuli : process
        -- tb help variables
            variable good       : boolean := true;
        -- DUT
            variable eSpiMasterBfm  : tESpiBfm;                                         --! eSPI Master bfm Handle
            variable eSpiMsg        : tMemX08(0 to 9);                                  --! eSPI Message
            variable config         : std_logic_vector(31 downto 0) := (others => '0'); --! slave configuration
            variable status         : std_logic_vector(15 downto 0) := (others => '0'); --! slave status
            variable response       : tESpiRsp;                                         --! slave response
            variable slv8           : std_logic_vector(7 downto 0);                     --! help
            variable memX08         : tMemX08(0 to 2);                                  --! help
            variable vwireIdx       : tMemX08(0 to 63);                                 --! virtual wire index, @see Table 9: Virtual Wire Index Definition, max. 64 virtual wires
            variable vwireData      : tMemX08(0 to 63);                                 --! virtual wire data
            variable vwireLen       : integer range 0 to 64;                            --! number of wire pairs

    begin

        -------------------------
        -- Init
        -------------------------
            Report "Init...";
            RESETn  <= '0';
            CSn     <= '1';
            SCK     <= '0';
            DIO     <= (others => 'Z');
            LDMSG   <= '0';
            REQMSG  <= (others => character(NUL));
            CMPMSG  <= (others => character(NUL));
            -- init( this )
            init( eSpiMasterBfm );  --! BFM common data handle only
                -- setLogLevel( this, log )
            setLogLevel( eSpiMasterBfm, INFO );     --! errors + warning + info messages
            wait for 1 us;
            RESETn  <= '1';
            wait for 1 us;
        -------------------------


        -------------------------
        -- Test0: Check CRC8 Function
        -- SRC: http://www.sunshine2k.de/coding/javascript/crc/crc_js.html
        -------------------------
        if ( doTest0 or DO_ALL_TEST ) then
            Report "Test0: Check CRC8";
            -- set 0
            eSpiMsg(0) := x"31";
            eSpiMsg(1) := x"32";
            eSpiMsg(2) := x"33";
            eSpiMsg(3) := x"34";
            eSpiMsg(4) := x"35";
            eSpiMsg(5) := x"36";
            eSpiMsg(6) := x"37";
            eSpiMsg(7) := x"38";
            eSpiMsg(8) := x"39";
            slv8 := crc8(eSpiMsg(0 to 8));  --! calc crc
            assert ( slv8 = x"F4" ) report "  Error: CRC calculation failed, expected 0xF4" severity warning;
            if not ( slv8 = x"F4" ) then good := false; end if;
            wait for decodeClk( eSpiMasterBfm )/2;
            -- set 1
            eSpiMsg(0) := x"47";
            eSpiMsg(1) := x"12";
            eSpiMsg(2) := x"08";
            eSpiMsg(3) := x"15";
            slv8 := crc8(eSpiMsg(0 to 3));  --! calc crc
            assert ( slv8 = x"4E" ) report "  Error: CRC calculation failed, expected 0x4E" severity warning;
            if not ( slv8 = x"4E" ) then good := false; end if;
            wait for decodeClk( eSpiMasterBfm )/2;
            -- set 2
            eSpiMsg(0) := x"21";
            eSpiMsg(1) := x"00";
            eSpiMsg(2) := x"04";
            slv8 := crc8(eSpiMsg(0 to 2));  --! calc crc
            assert ( slv8 = x"34" ) report "  Error: CRC calculation failed, expected 0x46" severity warning;
            if not ( slv8 = x"34" ) then good := false; end if;
            wait for decodeClk( eSpiMasterBfm )/2;
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test1: GET_CONFIGURATION
        -------------------------
        if ( doTest1 or DO_ALL_TEST ) then
            Report "Test1: GET_CONFIGURATION";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 9)  <= "21000434"               & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 23) <= "0F0F0F08010000000F0309" & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
            GET_CONFIGURATION( eSpiMasterBfm, CSn, SCK, DIO, x"0004", config, status, response );   --! read from Slave
            -- check
                -- config
            assert ( x"00000001" = config ) report "GET_CONFIGURATION:  Expected config 0x00000001" severity warning;
            if not ( x"00000001" = config ) then good := false; end if;
                -- status
            assert ( x"030F" = status ) report "GET_CONFIGURATION:  Expected status 0x030F" severity warning;
            if not ( x"030F" = status ) then good := false; end if;
                -- response
            assert ( ACCEPT = response ) report "GET_CONFIGURATION:  Expected 'ACCEPT' slave response" severity warning;
            if not ( ACCEPT = response ) then good := false; end if;
            -- divide wait
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test2: SET_CONFIGURATION
        -------------------------
        if ( doTest2 or DO_ALL_TEST ) then
            Report "Test2: SET_CONFIGURATION";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 17) <= "2200080000008088"   & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 15) <= "0F0F0F080F039B"     & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
                -- SET_CONFIGURATION( this, CSn, SCK , DIO, adr, config, status, response );
            SET_CONFIGURATION( eSpiMasterBfm, CSn, SCK, DIO, x"0008", x"80000000", status, response );
                -- status
            assert ( x"030F" = status ) report "SET_CONFIGURATION:  Expected status 0x030F" severity warning;
            if not ( x"030F" = status ) then good := false; end if;
                -- response
            assert ( ACCEPT = response ) report "SET_CONFIGURATION:  Expected 'ACCEPT' slave response" severity warning;
            if not ( ACCEPT = response ) then good := false; end if;
            -- divide wait
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test3: GET_STATUS
        -------------------------
        if ( doTest3 or DO_ALL_TEST ) then
            Report "Test3: GET_STATUS";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 5)  <= "25FB"           & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 15) <= "0F0F0F080F039B" & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
            GET_STATUS ( eSpiMasterBfm, CSn, SCK, DIO, good );      --! get status from slave
            -- divide wait
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test4: MEMWR32
        -------------------------
        if ( doTest4 or DO_ALL_TEST ) then
            Report "Test4: MEMWR32";
            Report "         single Byte write";
            -- Memory write with short command
                -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 15) <= "4C0000008047F9"         & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 23) <= "0F0F0F08010000000F0309" & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
                -- Request BFM
            MEMWR32 ( eSpiMasterBfm, CSn, SCK, DIO, x"00000080", x"47", good ); --! write single byte to address 0x80
            wait for 4*decodeClk( eSpiMasterBfm );                                   --! divide wait
            -- Memory write non-short command
            Report "         multiple Byte write";
                -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 25) <= "00010003000000800123454A"   & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 23) <= "0F0F0F08010000000F0309"     & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
                -- Request BFM
            memX08(0)   := x"01";   --! prepare data to write
            memX08(1)   := x"23";
            memX08(2)   := x"45";
            MEMWR32 ( eSpiMasterBfm, CSn, SCK, DIO, x"00000080", memX08, good );    --! write to memory
            -- divide wait
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test5: MEMRD32
        -------------------------
        if ( doTest5 or DO_ALL_TEST ) then
            Report "Test5: MEMRD32";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 13) <= "480000008058"           & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 23) <= "0F0F0F08010000000F0309" & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
            MEMRD32 ( eSpiMasterBfm, CSn, SCK, DIO, x"00000080", slv8, good );  --! read single byte from address 0x80
            -- check
            assert ( x"01" = slv8 ) report "MEMRD32:  Read value unequal 0x01" severity warning;
            if not ( x"01" = slv8 ) then good := false; end if;
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test6: Reset
        -------------------------
        if ( doTest6 or DO_ALL_TEST ) then
            Report "Test6: In-band Reset";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 5)  <= "FFFF"   & character(NUL);       --! sent Request        (BFM to Slave)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
                -- RESET ( this, CSn, SCK, DIO );
            RESET ( eSpiMasterBfm, CSn, SCK, DIO );
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test7: IOWR
        -------------------------
        if ( doTest7 or DO_ALL_TEST ) then
            Report "Test7: IOWR";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 11) <= "44008047A7"     & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 15) <= "0F0F0F084F03C0" & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
            IOWR ( eSpiMasterBfm, CSn, SCK, DIO, x"0080", x"47", good );    --! write data byte 0x47 to IO space adr 0x80 (Port 80)
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test8: IORD
        -------------------------
        if ( doTest8 or DO_ALL_TEST ) then
            Report "Test8: IORD";
            Report "  Slave Responds directly";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 9)  <= "4000800F"               & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 23) <= "0F0F0F08010000000F0309" & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
            slv8 := (others => 'X');                                    --! make invalid
            IORD ( eSpiMasterBfm, CSn, SCK, DIO, x"0080", slv8, good ); --! read data byte from io space adr 0x80
            -- check
            assert ( x"01" = slv8 ) report "IORD:  Read value unequal 0x01" severity warning;
            if not ( x"01" = slv8 ) then good := false; end if;
            wait for 1 us;
            Report "  Slave Responds responds with DEFER";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 14) <= "4000800F"   & character(LF) & "0107"                & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 26) <= "015F03AD"   & character(LF) & "080F0001154F039F"    & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
            slv8 := (others => 'X');                                    --! make invalid
            IORD ( eSpiMasterBfm, CSn, SCK, DIO, x"0080", slv8, good ); --! read data byte from io space adr 0x80
            -- check
            assert ( x"15" = slv8 ) report "IORD:  Read value unequal 0x15" severity warning;
            if not ( x"15" = slv8 ) then good := false; end if;
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test9: VWIRE Name
        -------------------------
        if ( doTest9 or DO_ALL_TEST ) then
            Report "Test9: VWIRE Name";
            Report "  XSUSSTAT = 1";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 11) <= "0400031110" & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 9)  <= "084F03C0"   & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
                -- VWIREWR( this, CSn, SCK, DIO, name, value, good  )
            VWIREWR( eSpiMasterBfm, CSn, SCK, DIO, "SUS_STAT#", '1', good );
            wait for 1 us;
            Report "  XPLTRST = 1";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 11) <= "0400032289" & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 9)  <= "084F03C0"   & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
                -- VWIREWR( this, CSn, SCK, DIO, name, value, good  )
            VWIREWR( eSpiMasterBfm, CSn, SCK, DIO, "PLTRST#", '1', good );
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test10: VWIRERD
        -------------------------
        if ( doTest10 or DO_ALL_TEST ) then
            Report "Test10: VWIRERD - Status Wires";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 10) <= "25FB"       & character(LF) & "051B"                    & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 32) <= "084F03C0"   & character(LF) & "0802059904C006500F03E9"  & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
                -- VWIRERD( this, CSn, SCK, DIO, vwireIdx, vwireData, vwireLen, status, response );
            VWIRERD( eSpiMasterBfm, CSn, SCK, DIO, good );
            Report "Test11: VWIRERD - IRQ4";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 10) <= "25FB"       & character(LF) & "051B"            & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 24) <= "084F03C0"   & character(LF) & "080000840F0325"  & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
                -- VWIRERD( this, CSn, SCK, DIO, vwireIdx, vwireData, vwireLen, status, response );
            VWIRERD( eSpiMasterBfm, CSn, SCK, DIO, good );
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test11: VW_ADD
        -------------------------
        if ( doTest11 or DO_ALL_TEST ) then
            Report "Test11: VW_ADD - Composes List of Virtual Wires";
            vwireLen := 0;
            VW_ADD( eSpiMasterBfm, "PLTRST#",                   '1', vwireIdx, vwireData, vwireLen, good ); --! 'PLTRST#' and 'SUS_STAT#' same index
            VW_ADD( eSpiMasterBfm, "IRQ12",                     '1', vwireIdx, vwireData, vwireLen, good );
            VW_ADD( eSpiMasterBfm, "SUS_STAT#",                 '0', vwireIdx, vwireData, vwireLen, good );
            VW_ADD( eSpiMasterBfm, "SLAVE_BOOT_LOAD_STATUS",    '1', vwireIdx, vwireData, vwireLen, good );
            wait for 100 ns;
            -- wire length
            assert ( 3 = vwireLen ) Report "VW_ADD: Wrong list length" severity warning;
            if not ( 3 = vwireLen ) then good := false; end if;
            -- wire 0 (PLTRST#/SUS_STAT#)
            assert ( x"03" = vwireIdx(0) )  Report "VW_ADD:Wire0: Wrong Index" severity warning;
            if not ( x"03" = vwireIdx(0) )  then good := false; end if;
            assert ( x"32" = vwireData(0) ) Report "VW_ADD:Wire0: Wrong Data" severity warning;
            if not ( x"32" = vwireData(0) ) then good := false; end if;
            -- wire 1 (IRQ12)
            assert ( x"00" = vwireIdx(1) )  Report "VW_ADD:Wire1: Wrong Index" severity warning;
            if not ( x"00" = vwireIdx(1) )  then good := false; end if;
            assert ( x"8C" = vwireData(1) ) Report "VW_ADD:Wire1: Wrong Data" severity warning;
            if not ( x"8C" = vwireData(1) ) then good := false; end if;
            -- wire 1 (SLAVE_BOOT_LOAD_STATUS)
            assert ( x"05" = vwireIdx(2) )  Report "VW_ADD:Wire2: Wrong Index" severity warning;
            if not ( x"05" = vwireIdx(2) )  then good := false; end if;
            assert ( x"88" = vwireData(2) ) Report "VW_ADD:Wire2: Wrong Data" severity warning;
            if not ( x"88" = vwireData(2) ) then good := false; end if;
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test12: WAIT_VW_IS_EQ
        -------------------------
        if ( doTest12 or DO_ALL_TEST ) then
            Report "Test12: WAIT_VW_IS_EQ - Waits until the Virtual Wires with Value are read";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 10) <= "25FB"       & character(LF) & "051B"            & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 24) <= "084F03C0"   & character(LF) & "080000840F0325"  & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG           <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
                -- WAIT_VW_IS_EQ( this, CSn, SCK, DIO, ALERTn, wireName, wireVal, good )
            WAIT_VW_IS_EQ( eSpiMasterBfm, CSn, SCK, DIO, ALERTn, "IRQ4", '1', good );
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test13: init
        -------------------------
        if ( doTest13 or DO_ALL_TEST ) then
            Report "Test13: init with 'Exit G3 Sequence'";
            -- load message
            REQMSG              <= (others => character(NUL));
            CMPMSG              <= (others => character(NUL));
            REQMSG(1 to 130)    <= "21000810"           & character(LF) & "220008030000003B"    & character(LF) & "210020C8"            & character(LF) & "220020010700007C"    & character(LF) & "25FB"        & character(LF) & "051B"            & character(LF) & "0400027730"  & character(LF) & "0400031017"  & character(LF) & "0400032289"  & character(LF) & "21001058"            & character(LF) & "22001013110000BE"    & character(LF) & "21000434"            & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 146)    <= "08030000000F035B"   & character(LF) & "080F039B"            & character(LF) & "08000700000F0309"    & character(LF) & "080F039B"            & character(LF) & "084F03C0"    & character(LF) & "080005994F0303"  & character(LF) & "084F03C0"    & character(LF) & "084F03C0"    & character(LF) & "084F03C0"    & character(LF) & "08131100004F03CE"    & character(LF) & "084F03C0"            & character(LF) & "08010000004F0352"    & character(NUL);   --! received response   (Slave to BFM)
            LDMSG               <= '1';
            wait for decodeClk( eSpiMasterBfm )/2;
            LDMSG               <= '0';
            wait for decodeClk( eSpiMasterBfm )/2;
            -- Request BFM
                -- init( this, RESETn, CSn, SCK, DIO, ALERTn, good, log );
            init( eSpiMasterBfm, foo, CSn, SCK, DIO, ALERTn, good, INFO );
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Report TB
        -------------------------
            Report "End TB...";     -- sim finished
            if ( good and slvGood ) then
                Report "Test SUCCESSFULL";
            else
                Report "Test FAILED" severity error;
            end if;
            wait;                   -- stop process continuous run
        -------------------------

    end process p_stimuli;
    ----------------------------------------------


    ----------------------------------------------
    -- eSPI Message Recorder
    i_eSpiStaticSlave : entity work.eSpiStaticSlave
        generic map (
                        MAXMSGLEN => REQMSG'length  --! max length of ascii hex request and answer string
                    )
        port map    (
                        SCK    => SCK,      --! shift clock
                        MOSI   => DIO(0),   --! Single mode, data in from Master
                        MISO   => DIO(1),   --! Single mode, data out to master
                        XCS    => CSn,      --! slave select
                        XALERT => ALERTn,   --! Alert
                        XRESET => RESETn,   --! reset
                        REQMSG => REQMSG,   --! request message
                        CMPMSG => CMPMSG,   --! complete message, if request was ok
                        LDMSG  => LDMSG,    --! load message on rising edge
                        GOOD   => slvGood   --! all request messages were good, set with RESETn
                    );
    ----------------------------------------------


    ----------------------------------------------
    -- Pull Resistors
    DIO     <= (others => 'H');
    ALERTn  <= 'H';
    ----------------------------------------------

end architecture sim;
--------------------------------------------------------------------------
