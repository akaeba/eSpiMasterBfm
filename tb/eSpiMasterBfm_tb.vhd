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
        constant doTest9    : boolean := true;  --! test9:  VWIRE XPLTRST
        constant doTest10   : boolean := true;  --! test10: PRT_CFG_REGS, prints configuration regs to console
        constant doTest11   : boolean := true;  --! test11: VWIRERD

    -----------------------------


    -----------------------------
    -- Signals
        -- DUT
        signal CSn      : std_logic;
        signal SCK      : std_logic;
        signal DIO      : std_logic_vector(3 downto 0);
        signal ALERTn   : std_logic;
        signal XRESET   : std_logic;
        -- ESPI Static Slave
        signal slvGood  : boolean;              --! all request to slave good?
        signal REQMSG   : string(1 to 150);     --! request message
        signal CMPMSG   : string(1 to 150);     --! complete message, if request was ok
        signal LDMSG    : std_logic;            --! load message on rising edge
    -----------------------------

begin

    ----------------------------------------------
    -- stimuli process
    p_stimuli : process
        -- tb help variables
            variable good       : boolean := true;
            variable tmpBool    : boolean := true;
        -- DUT
            variable eSpiMasterBfm  : tESpiBfm;                                         --! eSPI Master bfm Handle
            variable eSpiMsg        : tMemX08(0 to 9);                                  --! eSPI Message
            variable config         : std_logic_vector(31 downto 0) := (others => '0'); --! slave configuration
            variable status         : std_logic_vector(15 downto 0) := (others => '0'); --! slave status
            variable response       : tESpiRsp;                                         --! slave response
            variable slv8           : std_logic_vector(7 downto 0);                     --! help
            variable memX08         : tMemX08(0 to 2);                                  --! help
            -- temp
            variable vwireIdx   : tMemX08(0 to 63);                 --! virtual wire index, @see Table 9: Virtual Wire Index Definition, max. 64 virtual wires
            variable vwireData  : tMemX08(0 to 63);                 --! virtual wire data
            variable vwireLen   : integer range 0 to 64;            --! number of wire pairs
    begin

        -------------------------
        -- Init
        -------------------------
            Report "Init...";
            init(eSpiMasterBfm, CSn, SCK, DIO); --! init eSpi Master
            eSpiMasterBfm.verbose := 3;         --! enable errors + warning messages
            XRESET  <= '0';
            LDMSG   <= '0';
            REQMSG  <= (others => character(NUL));
            CMPMSG  <= (others => character(NUL));
            wait for 1 us;
            XRESET  <= '1';
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
            wait for eSpiMasterBfm.TSpiClk/2;
            -- set 1
            eSpiMsg(0) := x"47";
            eSpiMsg(1) := x"12";
            eSpiMsg(2) := x"08";
            eSpiMsg(3) := x"15";
            slv8 := crc8(eSpiMsg(0 to 3));  --! calc crc
            assert ( slv8 = x"4E" ) report "  Error: CRC calculation failed, expected 0x4E" severity warning;
            if not ( slv8 = x"4E" ) then good := false; end if;
            wait for eSpiMasterBfm.TSpiClk/2;
            -- set 2
            eSpiMsg(0) := x"21";
            eSpiMsg(1) := x"00";
            eSpiMsg(2) := x"04";
            slv8 := crc8(eSpiMsg(0 to 2));  --! calc crc
            assert ( slv8 = x"34" ) report "  Error: CRC calculation failed, expected 0x46" severity warning;
            if not ( slv8 = x"34" ) then good := false; end if;
            wait for eSpiMasterBfm.TSpiClk/2;
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
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
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
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
            -- Request BFM
            SET_CONFIGURATION( eSpiMasterBfm, CSn, SCK, DIO, x"0008", x"80000000", good );  --! General Capabilities and Configuration 0x08, enable CRC
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
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
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
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
                -- Request BFM
            MEMWR32 ( eSpiMasterBfm, CSn, SCK, DIO, x"00000080", x"47", good ); --! write single byte to address 0x80
            wait for 4*eSpiMasterBfm.TSpiClk;                                   --! divide wait
            -- Memory write non-short command
            Report "         multiple Byte write";
                -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 25) <= "00010003000000800123454A"   & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 23) <= "0F0F0F08010000000F0309"     & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
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
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
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
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
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
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
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
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
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
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
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
        -- Test9: VWIRE XPLTRST
        -------------------------
        if ( doTest9 or DO_ALL_TEST ) then
            Report "Test9: VWIRE XPLTRST";
            Report "  XPLTRST = 0";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 11) <= "0400031110" & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 9)  <= "084F03C0"   & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
            -- Request BFM
                -- VW_PLTRST( this, CSn, SCK, DIO, XPLTRST, good )
            VW_PLTRST( eSpiMasterBfm, CSn, SCK, DIO, '0', good );
            wait for 1 us;
            Report "  XPLTRST = 1";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 11) <= "0400032289" & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 9)  <= "084F03C0"   & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
            -- Request BFM
                -- VW_PLTRST( this, CSn, SCK, DIO, XPLTRST, good )
            VW_PLTRST( eSpiMasterBfm, CSn, SCK, DIO, '1', good );
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test10: PRT_CFG_REGS
        -------------------------
        if ( doTest10 or DO_ALL_TEST ) then
            Report "Test10: PRT_CFG_REGS";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            -- Slave Cfg Regs
            --                      ADR=0x04                             ADR=0x08                             ADR=0x10                             ADR=0x20                             ADR=0x30                             ADR=0x40
            REQMSG(1 to 54) <=  "21000434"         & character(LF) & "21000810"         & character(LF) & "21001058"         & character(LF) & "210020C8"         & character(LF) & "210030B8"         & character(LF) & "210040EF" & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 88) <=  "0878563412000042" & character(LF) & "08111111110000B5" & character(LF) & "0822222222000054" & character(LF) & "083333333300000B" & character(LF) & "0844444444000091" & character(LF) & "FF"       & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
            tmpBool         := true;
            -- Request BFM
                -- PRT_CFG_REGS( this, CSn, SCK, DIO, good )
            PRT_CFG_REGS( eSpiMasterBfm, CSn, SCK, DIO, tmpBool );
            assert ( tmpBool = false ) report "PRT_CFG_REGS:  One access needs to fail" severity warning;
            if not ( tmpBool = false ) then good := false; end if;
            wait for 1 us;
        end if;
        -------------------------


        -------------------------
        -- Test11: VWIRERD
        -------------------------
        if ( doTest11 or DO_ALL_TEST ) then
            Report "Test11: VWIRERD - Status Wires";
            -- load message
            REQMSG          <= (others => character(NUL));
            CMPMSG          <= (others => character(NUL));
            REQMSG(1 to 10) <= "25FB"       & character(LF) & "051B"                    & character(NUL);   --! sent Request        (BFM to Slave)
            CMPMSG(1 to 32) <= "084F03C0"   & character(LF) & "0802059904C006500F03E9"  & character(NUL);   --! received response   (Slave to BFM)
            LDMSG           <= '1';
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
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
            wait for eSpiMasterBfm.TSpiClk/2;
            LDMSG           <= '0';
            wait for eSpiMasterBfm.TSpiClk/2;
            -- Request BFM
                -- VWIRERD( this, CSn, SCK, DIO, vwireIdx, vwireData, vwireLen, status, response );
            VWIRERD( eSpiMasterBfm, CSn, SCK, DIO, good );
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
                        XRESET => XRESET,   --! reset
                        REQMSG => REQMSG,   --! request message
                        CMPMSG => CMPMSG,   --! complete message, if request was ok
                        LDMSG  => LDMSG,    --! load message on rising edge
                        GOOD   => slvGood   --! all request messages were good, set with XRESET
                    );
    ----------------------------------------------


    ----------------------------------------------
    -- Pull Resistors
    DIO <= (others => 'H');
    ----------------------------------------------

end architecture sim;
--------------------------------------------------------------------------
