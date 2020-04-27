--************************************************************************
-- @author:  	Andreas Kaeberlein
-- @copyright:	Copyright 2020
-- @credits: 	AKAE
--
-- @license:  	BSDv3
-- @maintainer:	Andreas Kaeberlein
-- @email:		andreas.kaeberlein@web.de
--
-- @file:       eSpiMasterBfm_tb.vhd
-- @note:       VHDL'93
-- @date:   	2020-04-01
--
-- @see:		
-- @brief:      tests eSpiMasterBfm package functionality
--************************************************************************



--------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;			--! for UNIFORM, TRUNC
library work;
	use work.eSpiMasterBfm.all;		--! package under test
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
        constant loopIter	: integer := 20;    --! number of test loop iteration
        constant doTest0	: boolean := true;  --! test0: 
		constant doTest1	: boolean := true;  --! test1: 
    -----------------------------
	
	
    -----------------------------
    -- Signals
        -- DUT
		signal CSn	: std_logic; 
		signal SCK 	: std_logic; 
		signal DIO 	: std_logic_vector(3 downto 0);
		-- Test IOWR_SHORT
		signal IOWR_SHORT_B0		: std_logic_vector(73 downto 0);
		signal IOWR_SHORT_B0_SFR	: std_logic_vector(IOWR_SHORT_B0'range);
		signal ioWrB0Load			: std_logic;
		
	-----------------------------
	
	

begin

    ----------------------------------------------
    -- stimuli process
    p_stimuli : process
        -- tb help variables
            variable good   : boolean	:= true;
		-- DUT
			variable eSpiMasterBfm	: tESpiBfm;						--! eSPI Master bfm Handle
			variable eSpiMsg		: tESpiMsg(0 to 9);				--! eSPI Message
			variable slv8			: std_logic_vector(7 downto 0);	--! help
    begin

        -------------------------
        -- Init
        -------------------------
            Report "Init...";
			init(eSpiMasterBfm, CSn, SCK, DIO);	--! init eSpi Master
			eSpiMasterBfm.verbose := 2;			--! enable errors + warning messages
			ioWrB0Load		<= '0';
			IOWR_SHORT_B0	<= (others => '0');
        
		-------------------------

		
        -------------------------
        -- Test0: Check CRC8 Function
		-- SRC: http://www.sunshine2k.de/coding/javascript/crc/crc_js.html
        -------------------------
		if ( doTest0 or DO_ALL_TEST ) then
			Report "Test0: Check CRC8 Function";
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
			slv8 := crc8(eSpiMsg(0 to 8));	--! calc crc
            assert ( slv8 = x"F4" ) report "  Error: CRC calculation failed, expected 0xF4" severity warning;
            if not ( slv8 = x"F4" ) then good := false; end if;
			wait for eSpiMasterBfm.TSpiClk/2;
			-- set 1
			eSpiMsg(0) := x"47"; 
			eSpiMsg(1) := x"12"; 
			eSpiMsg(2) := x"08"; 
			eSpiMsg(3) := x"15";
			slv8 := crc8(eSpiMsg(0 to 3));	--! calc crc
            assert ( slv8 = x"4E" ) report "  Error: CRC calculation failed, expected 0x4E" severity warning;
            if not ( slv8 = x"4E" ) then good := false; end if;
			wait for eSpiMasterBfm.TSpiClk/2;
			-- set 2
			eSpiMsg(0) := x"21"; 
			eSpiMsg(1) := x"00"; 
			eSpiMsg(2) := x"04"; 
			slv8 := crc8(eSpiMsg(0 to 2));	--! calc crc
            assert ( slv8 = x"46" ) report "  Error: CRC calculation failed, expected 0x46" severity warning;
            if not ( slv8 = x"46" ) then good := false; end if;
			wait for eSpiMasterBfm.TSpiClk/2;
			wait for 1 us;
		end if;
		-------------------------
		
		
        -------------------------
        -- Test1: Master Initiated Short Non-Posted Transaction, PUT_IOWR_SHORT
		-- SRC: http://www.sunshine2k.de/coding/javascript/crc/crc_js.html
        -------------------------
		if ( doTest1 or DO_ALL_TEST ) then
			Report "Test1: Master Initiated Short Non-Posted Transaction, PUT_IOWR_SHORT";
				-- prepare Shift reg
			IOWR_SHORT_B0	<= (others => 'Z');
			ioWrB0Load		<= '0';
			wait for eSpiMasterBfm.TSpiClk/2;
			ioWrB0Load		<= '1';
			wait for eSpiMasterBfm.TSpiClk/2;
			ioWrB0Load		<= '0';
				-- procedure IOWR_SHORT ( this, CSn, SCK, DIO, adr, data );
			IOWR_SHORT( eSpiMasterBfm, CSn, SCK, DIO, x"0815", x"47" );
				-- check command
			if ( "010001" & "01" /= IOWR_SHORT_B0_SFR(IOWR_SHORT_B0_SFR'left downto IOWR_SHORT_B0_SFR'left-7) ) then
				Report "  Failed Command PUT_IOWR_SHORT" severity error;
				good := false;
			end if;
				-- check address
			if ( x"0815" /= IOWR_SHORT_B0_SFR(IOWR_SHORT_B0_SFR'left-8 downto IOWR_SHORT_B0_SFR'left-23) ) then
				Report "  Failed IOWR_SHORT address" severity error;
				good := false;
			end if;



			
			
			
		end if;
		-------------------------
		
		
		



        -------------------------
        -- Report TB
        -------------------------
            Report "End TB...";     -- sim finished
            if (good) then
                Report "Test SUCCESSFULL";
            else
                Report "Test FAILED" severity error;
            end if;
            wait;                   -- stop process continuous run
        -------------------------

    end process p_stimuli;
    ----------------------------------------------
	
	
    ----------------------------------------------
    -- IOWR_SHORT: Shift Register
    p_IOWR_SHORT_byte_0 : process (SCK, CSn, ioWrB0Load)
        variable clk : std_logic := '0';
    begin
        -- parallel load
		if ( rising_edge(ioWrB0Load) ) then
			IOWR_SHORT_B0_SFR	<= IOWR_SHORT_B0;
		else
			if ( rising_edge(SCK) and CSn = '0' ) then
				IOWR_SHORT_B0_SFR	<= IOWR_SHORT_B0_SFR(IOWR_SHORT_B0_SFR'left-1 downto IOWR_SHORT_B0_SFR'right) & DIO(0);
				DIO(1)				<= IOWR_SHORT_B0_SFR(IOWR_SHORT_B0_SFR'left);
			end if;
		end if;
    end process p_IOWR_SHORT_byte_0;
    ----------------------------------------------
	

end architecture sim;
--------------------------------------------------------------------------
