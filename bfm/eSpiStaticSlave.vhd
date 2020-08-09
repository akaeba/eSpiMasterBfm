--************************************************************************
-- @author:     Andreas Kaeberlein
-- @copyright:  Copyright 2020
-- @credits:    AKAE
--
-- @license:    BSDv3
-- @maintainer: Andreas Kaeberlein
-- @email:      andreas.kaeberlein@web.de
--
-- @file:       eSpiStaticSlave.vhd
-- @note:       VHDL'93
-- @date:       2020-28-06
--
-- @see:        https://github.com/akaeba/eSpiMasterBfm
-- @brief:      receives telegrams and checks again the golden sample
--              if the request is correct answers the module with an
--              response telegram
--************************************************************************



--
-- Important Hints
-- ===============
--
--   String Termination
--   ------------------
--     * NUL:   end of string
--     * NL:    in case of multiple chip select toggles (CS), new line
--              enters the next CSn sequence
--



--------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
-- eSpiStaticSlave: receives and generates telegrams
entity eSpiStaticSlave is
generic (
            MAXMSGLEN   : positive  := 100  --! max length of ascii hex request and answer string
        );
port    (
            -- ESPI
            SCK     : in    std_logic;              --! shift clock
            MOSI    : in    std_logic;              --! Single mode, data in from Master;   DIO(0)
            MISO    : out   std_logic;              --! Single mode, data out to master;    DIO(1)
            XCS     : in    std_logic;              --! slave select
            XALERT  : inout std_logic;              --! Alert
            XRESET  : in    std_logic;              --! reset
            -- Message control
            REQMSG  : in    string(1 to MAXMSGLEN); --! request message
            CMPMSG  : in    string(1 to MAXMSGLEN); --! complete message, if request was ok
            LDMSG   : in    std_logic;              --! load message on rising edge
            -- Status
            GOOD    : out   boolean                 --! all request messages were good, set with XRESET
        );
end entity eSpiStaticSlave;
--------------------------------------------------------------------------



--------------------------------------------------------------------------
architecture sim of eSpiStaticSlave is

    -----------------------------
    -- Functions
    -----------------------------
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
                when '0'    => result :=  x"0";
                when '1'    => result :=  x"1";
                when '2'    => result :=  x"2";
                when '3'    => result :=  x"3";
                when '4'    => result :=  x"4";
                when '5'    => result :=  x"5";
                when '6'    => result :=  x"6";
                when '7'    => result :=  x"7";
                when '8'    => result :=  x"8";
                when '9'    => result :=  x"9";
                when 'A'    => result :=  x"A";
                when 'B'    => result :=  x"B";
                when 'C'    => result :=  x"C";
                when 'D'    => result :=  x"D";
                when 'E'    => result :=  x"E";
                when 'F'    => result :=  x"F";
                when 'a'    => result :=  x"A";
                when 'b'    => result :=  x"B";
                when 'c'    => result :=  x"C";
                when 'd'    => result :=  x"D";
                when 'e'    => result :=  x"E";
                when 'f'    => result :=  x"F";
                when others => result :=  "XXXX";
            end case;
            return result;
        end function chr2slv;
        --***************************
    -----------------------------


    -----------------------------
    -- Type
    -----------------------------
        type t_tEspiSlv is  (
                                CMD_S,  --! Command phase
                                TAR_S,  --! Turn-around
                                RSP_S,  --! Response phase
                                NOMSG_S --! no message available
                            );
    -----------------------------


    -----------------------------
    -- Constant
    -----------------------------
        constant C_TAR_CYCLES : integer := 2;   --! set number of cycles in turn-around phase
    -----------------------------

begin

    ----------------------------------------------
    -- eSPI Message Recorder
    p_espiSlave : process (SCK, XCS, XRESET, LDMSG)
        variable requestMsg         : string(REQMSG'range);         --! request message; created by BFM
        variable completeMsg        : string(CMPMSG'range);         --! complete message; evaluated be BFM
        variable numReqSegs         : natural;                      --! by 'LF' divided segments of request message
        variable numCpltSegs        : natural;                      --! by 'LF' divided segments of complete message
        variable reqMsgStartIdx     : integer;                      --! in current segment start pointer of message to receive
        variable reqMsgStopIdx      : integer;                      --! in current segment stop pointer of message to receive
        variable cpltSegStartIdx    : integer;
        variable cpltSegStopIdx     : integer;
        variable reqBitsPend        : integer;                      --! number of pending command nibbles
        variable reqBitsCap         : integer;
        variable reqMsgCap          : string(REQMSG'range);         --! recorded request
        variable totalSeg           : natural;                      --! total number of segment
        variable currentSeg         : natural;                      --! current number of segment
        variable stage              : t_tEspiSlv;                   --! transmission stage
        variable tarPend            : integer := C_TAR_CYCLES;      --! turn-around
        variable SFR                : std_logic_vector(3 downto 0); --! shift-forward-register
        variable str1               : string(1 to 1);               --! help variable for slv to char conversion
        variable rspBitsSend        : integer;                      --! counts sent bits
    begin
        if ( '0' = XRESET ) then    --! init ESPI
            MISO        <= 'Z';
            XALERT      <= 'Z';
            GOOD        <= true;
            stage       := NOMSG_S;
            tarPend     := C_TAR_CYCLES;

        elsif ( rising_edge(LDMSG) ) then   --! prepare message sequence
            -- prepare
            requestMsg      := REQMSG;  --! copy to internal
            completeMsg     := CMPMSG;
            numCpltSegs     := 0;       --! temporary segment counter
            numReqSegs      := 0;
            totalSeg        := 0;       --! control counter
            currentSeg      := 0;
            reqMsgStartIdx  := 0;       --! init message pointer
            reqMsgStopIdx   := 0;
            cpltSegStartIdx := 0;
            cpltSegStopIdx  := 0;
            reqMsgCap       := (others => character(NUL));
            -- count Segments
            --  some ESPI requests consists out of multiple requests and responses, this mimic counts this
                -- request Message
            for i in requestMsg'range loop
                if ( character(NUL) = requestMsg(i) ) then
                    numReqSegs := numReqSegs + 1;
                    exit;
                elsif ( character(LF) = requestMsg(i) ) then
                    numReqSegs := numReqSegs + 1;
                end if;
            end loop;
                -- response message
            for i in completeMsg'range loop
                if ( character(NUL) = completeMsg(i) ) then
                    numCpltSegs := numCpltSegs + 1;
                    exit;
                elsif ( character(LF) = completeMsg(i) ) then
                    numCpltSegs := numCpltSegs + 1;
                end if;
            end loop;
            -- perform check
            if ( numReqSegs /= numCpltSegs ) then
                GOOD        <= false;   --! something went wrong
                totalSeg    := 0;       --! make invalid
                stage       := NOMSG_S; --! no transmit
                Report "Request and Response Message have different number of segments, CSn activations; TX=" & integer'image(numReqSegs) & " RX=" & integer'image(numCpltSegs) & ";" severity warning;
            else
                stage       := CMD_S;       --! ready to transmit
                totalSeg    := numReqSegs;  --! copy
            end if;

        else    --! bring it on the line
            if ( falling_edge(XCS) ) then
                -- update from last transmission
                reqMsgStartIdx  := reqMsgStopIdx + 1;
                cpltSegStartIdx := cpltSegStopIdx + 1;
                currentSeg      := currentSeg + 1;
                -- check segment
                if ( currentSeg > totalSeg ) then
                    GOOD <= false;  --! something went wrong
                    Report "More XCS divided telegrams requested then expected" severity warning;
                end if;
                -- determine new stop indexes
                for i in reqMsgStartIdx to requestMsg'length loop
                    if ( character(NUL) = requestMsg(i) or character(LF) = completeMsg(i) ) then
                        reqMsgStopIdx := i;
                        exit;
                    end if;
                end loop;
                for i in cpltSegStartIdx to completeMsg'length loop
                    if ( character(NUL) = completeMsg(i) or character(LF) = completeMsg(i) ) then
                        cpltSegStopIdx := i;
                        exit;
                    end if;
                end loop;
                -- prepare bit counter
                reqBitsPend := 4 * (reqMsgStopIdx - reqMsgStartIdx);    --! Request Phase
                reqBitsCap  := 0;
                rspBitsSend := 4 * (cpltSegStopIdx - cpltSegStartIdx);  --! response phase
                -- make empty
                reqMsgCap   := (others => character(NUL));

            elsif ( XCS = '0' ) then
                -- receive command
                if ( CMD_S = stage ) then
                    if ( rising_edge(SCK) ) then
                        -- update counter
                        reqBitsPend := reqBitsPend - 1;
                        reqBitsCap  := reqBitsCap + 1;
                        -- capture data
                        SFR := SFR(2 downto 0) & MOSI;
                        -- convert to string and store
                        if ( 0 = reqBitsCap mod 4 ) then
                            str1                    := to_hstring(SFR);
                            reqMsgCap(reqBitsCap/4) := str1(1);
                        end if;
                        -- compare
                        if ( 0 = reqBitsPend ) then
                            for i in 0 to (reqBitsCap/4 - 1) loop
                                if ( reqMsgCap(i+1) /= requestMsg(reqMsgStartIdx+i) ) then
                                    Report "Request: IS=0x" & reqMsgCap(1 to reqBitsCap/4) & "; EXP=0x" & requestMsg(reqMsgStartIdx to reqMsgStartIdx + reqBitsCap/4 - 1) & ";" severity warning;
                                    GOOD    <= false;   --! request failed
                                    stage   := NOMSG_S; --! no answer
                                    exit;
                                else
                                    stage   := TAR_S;   --! send response
                                end if;
                            end loop;
                        end if;
                    end if;
                end if;
                -- wait TAR
                if ( TAR_S = stage ) then
                    if ( falling_edge(SCK) ) then
                        if ( 0 = tarPend ) then
                            stage   := RSP_S;
                            tarPend := C_TAR_CYCLES;
                        end if;
                        tarPend := tarPend - 1;
                    end if;
                end if;
                -- send response
                if ( RSP_S = stage ) then
                    if ( falling_edge(SCK) ) then
                        if ( cpltSegStartIdx <= cpltSegStopIdx) then
                            -- reload SFR
                            if ( 0 = (rspBitsSend mod 4) ) then
                                if ( 0 < rspBitsSend ) then
                                    SFR := chr2slv(completeMsg(cpltSegStartIdx));   --! load new quadruple
                                end if;
                                cpltSegStartIdx := cpltSegStartIdx + 1;             --! prepare for next load
                            else
                                SFR := SFR(2 downto 0) & '0';
                            end if;
                            -- release to line
                            MISO <= SFR(3);
                            -- check for end of transmission
                            if ( 0 < rspBitsSend ) then
                                rspBitsSend := rspBitsSend - 1;
                            else
                                -- single/multi CSn request?
                                if ( currentSeg > totalSeg ) then   --! Single CSn
                                    stage := NOMSG_S;
                                else                                --! multi CSN
                                    stage := CMD_S;
                                end if;
                                MISO    <= 'Z';
                            end if;
                        end if;
                    end if;
                end if;
            else
                tarPend := C_TAR_CYCLES;    --! restore for next cycle
                MISO    <= 'Z';             --! line disable
            end if;
        end if;
    end process p_espiSlave;
    ----------------------------------------------


    ----------------------------------------------
    -- Pull Resistors
    MISO    <= 'H';
    XALERT  <= 'H';
    ----------------------------------------------

end architecture sim;
--------------------------------------------------------------------------
