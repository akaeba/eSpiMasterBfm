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
-- @date:   	2020-01-04
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


begin




end architecture sim;
--------------------------------------------------------------------------
