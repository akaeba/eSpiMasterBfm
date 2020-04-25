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
			init(eSpiMasterBfm, CSn, SCK, DIO);		--! init eSpi Master
        
		
		
		
		-------------------------

		
        -------------------------
        -- Test0: Check CRC8 Function
		-- SRC: http://www.sunshine2k.de/coding/javascript/crc/crc_js.html
        -------------------------
		if ( doTest0 or DO_ALL_TEST ) then
			Report "Test0: Check CRC8 Function";
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
			eSpiMsg(0) := x"47"; 
			eSpiMsg(1) := x"12"; 
			eSpiMsg(2) := x"08"; 
			eSpiMsg(3) := x"15";
			slv8 := crc8(eSpiMsg(0 to 3));	--! calc crc
            assert ( slv8 = x"4E" ) report "  Error: CRC calculation failed, expected 0x4E" severity warning;
            if not ( slv8 = x"4E" ) then good := false; end if;
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
				-- procedure IOWR_SHORT ( this, CSn, SCK, DIO, adr, data );
			IOWR_SHORT( eSpiMasterBfm, CSn, SCK, DIO, x"0815", x"47" );
			
			
			



			
			
			
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



end architecture sim;
--------------------------------------------------------------------------
