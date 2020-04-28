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
		constant doTest1	: boolean := true;  --! test1: GET_CONFIGURATION
		constant doTest2	: boolean := false; --! test2:
    -----------------------------
	
	
    -----------------------------
    -- Signals
        -- DUT
		signal CSn	: std_logic; 
		signal SCK 	: std_logic; 
		signal DIO 	: std_logic_vector(3 downto 0);
		-- Test IOWR_SHORT
		signal IOWR_SHORT_B0		: std_logic_vector(73 downto 0) 		:= (others => 'Z');
		signal IOWR_SHORT_B0_SFR	: std_logic_vector(IOWR_SHORT_B0'range)	:= (others => 'Z');
		signal ioWrB0Load			: std_logic;
		-- Test Message Recorder
		signal espiRecCmd	: string(1 to 50);	--! expected command string, NULL terminated
		signal espiRecRsp	: string(1 to 50);	--! response, null terminated
		signal espiCmdCmp	: std_logic;		--! command compare successful
	-----------------------------
	
    -----------------------------
    -- Functions
	-----------------------------

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
		
        --***************************   
        -- Convert to SLV4
        -- SRC: https://forums.xilinx.com/t5/Simulation-and-Verification/VHDL-Testbench-Unable-to-read-HEX-data-from-data-file/td-p/1084330
		function chr2slv (c : character) return std_logic_vector is
			variable result : std_logic_vector(3 downto 0);
		begin
			case c is
				when '0' 	=> result :=  x"0";
				when '1' 	=> result :=  x"1";
				when '2' 	=> result :=  x"2";
				when '3' 	=> result :=  x"3";
				when '4' 	=> result :=  x"4";
				when '5' 	=> result :=  x"5";
				when '6' 	=> result :=  x"6";
				when '7' 	=> result :=  x"7";
				when '8' 	=> result :=  x"8";
				when '9' 	=> result :=  x"9";
				when 'A' 	=> result :=  x"A";
				when 'B' 	=> result :=  x"B";
				when 'C' 	=> result :=  x"C";
				when 'D' 	=> result :=  x"D";
				when 'E' 	=> result :=  x"E";
				when 'F' 	=> result :=  x"F";
				when 'a' 	=> result :=  x"A";
				when 'b' 	=> result :=  x"B";
				when 'c' 	=> result :=  x"C";
				when 'd' 	=> result :=  x"D";
				when 'e' 	=> result :=  x"E";
				when 'f' 	=> result :=  x"F";
				when others => result :=  "XXXX";
			end case;
			return result;
		end function chr2slv;
		--*************************** 

	-----------------------------
	
	
	
begin

    ----------------------------------------------
    -- stimuli process
    p_stimuli : process
        -- tb help variables
            variable good   : boolean	:= true;
		-- DUT
			variable eSpiMasterBfm	: tESpiBfm;							--! eSPI Master bfm Handle
			variable eSpiMsg		: tESpiMsg(0 to 9);					--! eSPI Message
			variable slv8			: std_logic_vector(7 downto 0);		--! help
			variable slv32			: std_logic_vector(31 downto 0);	--! help
    begin

        -------------------------
        -- Init
        -------------------------
            Report "Init...";
			init(eSpiMasterBfm, CSn, SCK, DIO);	--! init eSpi Master
			eSpiMasterBfm.verbose := 2;			--! enable errors + warning messages
			ioWrB0Load		<= '0';
			IOWR_SHORT_B0	<= (others => '0');
			
			wait for 1 us;
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
            assert ( slv8 = x"34" ) report "  Error: CRC calculation failed, expected 0x46" severity warning;
            if not ( slv8 = x"34" ) then good := false; end if;
			wait for eSpiMasterBfm.TSpiClk/2;
			wait for 1 us;
		end if;
		-------------------------
		
		
		-------------------------
        -- Test1: GET_CONFIGURATION Command
		-- SRC: http://www.sunshine2k.de/coding/javascript/crc/crc_js.html
        -------------------------
		if ( doTest1 or DO_ALL_TEST ) then
			Report "Test1: GET_CONFIGURATION Command";
			-- prepare message recorder
			espiRecCmd(1 to 9)	<= "21000434" 				& character(NUL);
			espiRecRsp(1 to 23)	<= "0F0F0F08010000000F0309" & character(NUL);
			GET_CONFIGURATION( eSpiMasterBfm, CSn, SCK, DIO, x"0004", slv32 );	--! read from Slave
		
		

		
		
		
		
		end if;
		-------------------------
		
		
		-------------------------
        -- Test2: Master Initiated Short Non-Posted Transaction, PUT_IOWR_SHORT
		-- SRC: http://www.sunshine2k.de/coding/javascript/crc/crc_js.html
        -------------------------
		if ( doTest2 or DO_ALL_TEST ) then
			Report "Test2: Master Initiated Short Non-Posted Transaction, PUT_IOWR_SHORT";
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
    -- eSPI Message Recorder 
	p_espiSlave : process (SCK, CSn)
		variable	cmdBitsPend	: integer;						--! number of pending command nibbles
		variable	cmdBitsCap	: integer;
		variable	stage		: integer range 0 to 2;
		variable	rcvCmd		: string(espiRecCmd'range);
		variable	SFR			: std_logic_vector(3 downto 0);
		variable	str1		: string(1 to 1);
		variable	tarPend		: integer;
		variable	rspBitsSend	: integer;
	begin
		if ( falling_edge(CSn) ) then
			stage 		:= 0;		--! start with command receive
			espiCmdCmp	<= '0';
			cmdBitsCap	:= 0;
			rcvCmd		:= (others => character(NUL));
			tarPend		:= 2;
			rspBitsSend	:= 0;
			-- determine string length
			for i in espiRecCmd'range loop
				if ( character(NUL) = espiRecCmd(i) ) then
					cmdBitsPend := (i-1) * 4;
					exit;
				end if;
			end loop;
		elsif ( CSn = '0' ) then
			-- receive command
			if ( 0 = stage ) then
				if ( rising_edge(SCK) ) then
					-- update counter
					cmdBitsPend := cmdBitsPend - 1;
					cmdBitsCap	:= cmdBitsCap + 1;
					-- capture data
					SFR	:= SFR(2 downto 0) & DIO(0);
					-- convert to string and store
					if ( 0 = cmdBitsCap mod 4 ) then
						str1					:= to_hstring(SFR);
						rcvCmd(cmdBitsCap/4)	:= str1(1);
					end if;
					-- compare
					if ( 0 = cmdBitsPend ) then
						for i in 1 to cmdBitsCap/4 loop
							if ( rcvCmd(i) /= espiRecCmd(i) ) then
								Report "Received command and expected command unequal" & character(lf) & "RCV = " & rcvCmd & character(lf) & "EXP = " & espiRecCmd;
								espiCmdCmp <= '1';
								exit;
							end if;
						end loop;
						stage := 1;
					end if;
				end if;
			end if;
			-- wait TAR
			if ( 1 = stage ) then
				if ( falling_edge(SCK) ) then
					if ( 0 = tarPend ) then
						stage := 2;
					end if;
					tarPend := tarPend - 1;
				end if;
			end if;
			-- send response
			if ( 2 = stage ) then
				if ( falling_edge(SCK) ) then
					if ( character(NUL) /= espiRecRsp(rspBitsSend/4 + 1)) then
						if ( 0 = rspBitsSend mod 4) then
							SFR := chr2slv(espiRecRsp(rspBitsSend/4 + 1));
						else
							SFR	:= SFR(2 downto 0) & '0';
						end if;
						DIO(1)	<= SFR(3);
						rspBitsSend := rspBitsSend + 1;
					else
						DIO(1)	<= 'Z';
					end if;
				end if;
			end if;
		else
			DIO	<= (others => 'Z');
		end if;
	end process p_espiSlave;
	----------------------------------------------
	
	
    ----------------------------------------------
    -- Pull Resistors
	DIO	<= (others => 'H');
	----------------------------------------------
	
end architecture sim;
--------------------------------------------------------------------------
