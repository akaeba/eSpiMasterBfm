--************************************************************************
-- @author:  	Andreas Kaeberlein
-- @copyright:	Copyright 2020
-- @credits: 	AKAE
--
-- @license:  	BSDv3
-- @maintainer:	Andreas Kaeberlein
-- @email:		andreas.kaeberlein@web.de
--
-- @file:       eSpiStaticSlave_tb.vhd
-- @note:       VHDL'93
-- @date:   	2020-08-03
--
-- @see:		https://github.com/akaeba/eSpiMasterBfm
-- @brief:      tests eSpiStaticSlave
--************************************************************************



--------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;			--! for UNIFORM, TRUNC
library work;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- testbench
entity eSpiStaticSlave_tb is
generic (
            DO_ALL_TEST : boolean   := false        --! switch for enabling all tests
        );
end entity eSpiStaticSlave_tb;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of eSpiStaticSlave_tb is

    -----------------------------
    -- Constant
        -- Test
		constant loopIter	: integer 	:= 20;    	--! number of test loop iteration
        constant doTest0	: boolean 	:= true;  	--! test0: CRC8
		-- DUT
		constant TP			: time		:= 20 ns;	--! clock period
		constant MAXMSGLEN	: integer	:= 100;
	
	-----------------------------
    
	
	-----------------------------
    -- Signals
        -- DUT
		signal SCK		: std_logic;
		signal MOSI		: std_logic;
		signal MISO		: std_logic;
		signal XCS		: std_logic;
		signal XALERT	: std_logic;
		signal XRESET	: std_logic;
		signal REQMSG	: string(1 to MAXMSGLEN);
		signal CMPMSG	: string(1 to MAXMSGLEN);
		signal LDMSG	: std_logic;
		signal MAGOOD	: std_logic;
	-----------------------------

begin

    ----------------------------------------------
    -- DUT
	   DUT : entity work.eSpiStaticSlave
		generic map (
						MAXMSGLEN => MAXMSGLEN
					)
		port map 	(
						SCK    => SCK,
						MOSI   => MOSI,
						MISO   => MISO,
						XCS    => XCS,
						XALERT => XALERT,
						XRESET => XRESET,
						REQMSG => REQMSG,
						CMPMSG => CMPMSG,
						LDMSG  => LDMSG,
						GOOD   => MAGOOD
					);
	----------------------------------------------


    ----------------------------------------------
    -- stimuli process
    p_stimuli : process
        -- tb help variables
            variable good   : boolean	:= true;
		-- DUT
    begin

        -------------------------
        -- Init
        -------------------------
            Report "Init...";
			SCK		<= '0';
			MOSI	<= 'Z';
			XCS		<= '1';
			XALERT	<= 'Z';
			XRESET	<= '0';
			REQMSG	<= (others => character(NUL));
			CMPMSG	<= (others => character(NUL));
			LDMSG	<= '0';
			wait for 5*TP;
			XRESET	<= '1';
			wait for 5*TP;
		-------------------------		
		
		
        -------------------------
        -- Test0: Check CRC8 Function
        -------------------------
		if ( doTest0 or DO_ALL_TEST ) then
			Report "Test0: Send/Receive Single Byte";
			-- load message
			REQMSG(1 to 2) 	<= "54";
			CMPMSG(1 to 2)	<= "AA";
			LDMSG			<= '1';
			wait for TP;
			LDMSG			<= '0';
			-- check transfer
			XCS	<= '0';
			-- send 0x55 to slave
			for i in 0 to 7 loop
				if ( 0 = (i mod 2) ) then
					MOSI <= '0';
				else
					MOSI <= '1';
				end if;
				wait for TP/2;
				SCK	<= '1';
				wait for TP/2;
				SCK	<= '0';
			end loop;
			MOSI <= 'Z';
			
			
			
		
		
			wait for 10*TP;
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
