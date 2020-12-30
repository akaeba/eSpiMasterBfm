# eSpiMasterBfm

Enhanced SPI Master Bus Functional Model


## Features

The _eSpiMasterBfm_ provides VHDL procedures to interact with an eSPI endpoint.
Currently are procedures available for:
 * IO Read/Write
 * Memory Read/Write
 * Endpoint Configuration


## Releases

| Version | Date       | Source                                                                                            | Change log                                      |
| ------- | ---------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| latest  |            | <a id="raw-url" href="https://github.com/akaeba/eSpiMasterBfm/archive/master.zip ">latest.zip</a> |                                                 |
| v0.1.0  | 2020-12-30 | <a id="raw-url" href="https://github.com/akaeba/eSpiMasterBfm/archive/v0.1.0.zip ">v0.1.0.zip</a> | Configuration; IO read/write; Memory read/write |


## Example

The full provided function set demonstrates the _[eSpiMasterBfm_tb.vhd](https://github.com/akaeba/eSpiMasterBfm/blob/master/tb/eSpiMasterBfm_tb.vhd)_.
A tiny testbench example shows the snippet below:

```vhdl
library ieee;
  use ieee.std_logic_1164.all;
library work;
  use work.eSpiMasterBfm.all;

entity espi_tb is
end entity espi_tb;

architecture sim of espi_tb is

  -----------------------------
  -- ESPI ITF
  signal CSn    : std_logic;
  signal SCK    : std_logic;
  signal DIO    : std_logic_vector(3 downto 0);
  signal ALERTn : std_logic;
  signal RESETn : std_logic;
  -----------------------------

begin

  -----------------------------
  -- DUT
  --   add ESPI Slave here
  -----------------------------


  -----------------------------
  -- stimuli process
  p_stimuli : process
    variable eSpiBfm : tESpiBfm;                        -- eSPI Master bfm Handle
    variable good    : boolean := true;                 -- test state
    variable slv08   : std_logic_vector(7 downto 0);    -- help variable
  begin
    -- Initializes Endpoint according 'Exit G3' sequence
    --   init( this, RESETn, CSn, SCK, DIO, ALERTn, good, log );
    init( eSpiBfm, RESETn, CSn, SCK, DIO, ALERTn, good, INFO );

    -- write to io-mapped address
    --   IOWR( this, CSn, SCK, DIO, adr, data, good )
    IOWR( eSpiBfm, CSn, SCK, DIO, x"0080", x"47", good );   -- P80

    -- read from io-mapped address
    --   IORD( this, CSn, SCK, DIO, adr, data, good )
    IORD( eSpiBfm, CSn, SCK, DIO, x"0081", slv08, good );   -- P81

    -- write to memory-mapped address
    --   MEMWR32( this, CSn, SCK, DIO, adr, data, good );
    MEMWR32( eSpiBfm, CSn, SCK, DIO, x"00000080", x"47", good );    -- byte write

    -- read from memory-mapped address
    --   MEMRD32( this, CSn, SCK, DIO, adr, data, good );
    MEMRD32( eSpiBfm, CSn, SCK, DIO, x"00000080", slv08, good );    -- byte read

    -- done
    Report "That's it :-)";
    wait;   -- stop continuous run
  end process p_stimuli;
  -----------------------------


  -----------------------------
  -- External Pull Resistors
  SCK    <= 'L';
  DIO    <= (others => 'H');
  ALERTn <= 'H';
  -----------------------------

end architecture sim;
```


## File Listing

The table below lists the major files in this project:

| File                                                                                                                             | Group | Remark                                                         |
| -------------------------------------------------------------------------------------------------------------------------------- | ----- | -------------------------------------------------------------- |
| [eSpiMasterBfm.vhd](https://github.com/akaeba/eSpiMasterBfm/blob/master/bfm/eSpiMasterBfm.vhd)                                   | BFM   | BFM itself, provides procedures to interact with an eSPI Slave |
| [eSpiMasterBfm_tb.vhd](https://github.com/akaeba/eSpiMasterBfm/blob/master/tb/eSpiMasterBfm_tb.vhd)                              | TB    | _eSpiMasterBfm_ testbench, example BFM procedure calls         |
| [eSpiMasterBfm_compile.tcl](https://github.com/akaeba/eSpiMasterBfm/blob/master/tcl/sim/eSpiMasterBfm/eSpiMasterBfm_compile.tcl) | SIM   | compile script for Modelsim                                    |
| [eSpiMasterBfm_runsim.tcl](https://github.com/akaeba/eSpiMasterBfm/blob/master/tcl/sim/eSpiMasterBfm/eSpiMasterBfm_runsim.tcl)   | SIM   | starts simulation                                              |


## [BFM](https://github.com/akaeba/eSpiMasterBfm/blob/master/bfm/eSpiMasterBfm.vhd) procedures

| Category            | Procedures                                             | Example                                                     |
| ------------------- | ------------------------------------------------------ | ----------------------------------------------------------- |
| initialization      | _init_, _RESET_                                        | `init(bfm, RESETn, CSn, SCK, DIO, ALERTn, good)`            |
| slave configuration | _GET_CONFIGURATION_, _SET_CONFIGURATION_, _GET_STATUS_ | `GET_CONFIGURATION(bfm, CSn, SCK, DIO, adr, cfg, sts, rsp)` |
| virtual wire        | _VWIREWR_, _VWIRERD_, _WAIT_VW_IS_EQ_                  | `VWIREWR(bfm, CSn, SCK, DIO, "PLTRST#", '1', good)`         |
| IO write            | _IOWR_BYTE_, _IOWR_WORD_, _IOWR_DWORD_                 | `IOWR(bfm, CSn, SCK, DIO, adr16, dat08, good)`              |
| IO read             | _IORD_BYTE_, _IORD_WORD_, _IORD_DWORD_                 | `IORD(bfm, CSn, SCK, DIO, adr16, dat08, good)`              |
| memory write        | _MEMWR32_                                              | `MEMWR32(bfm, CSn, SCK, DIO, adr32, dat08, good)`           |
| memory read         | _MEMRD32_                                              | `MEMRD32(bfm, CSn, SCK, DIO, adr32, dat08, good)`           |


## Contributors wanted

If you think useful project and also helpful, feel free to fork and contribute.
The licence does not require this, but the project will love it :-). Contributors welcome.


## eSPI Slaves
 * [Intel/Altera _eSPI to LPC Bridge Core_](https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/ug/ug_embedded_ip.pdf)


## References
 * [Intel eSPI Specification](https://www.intel.com/content/dam/support/us/en/documents/software/chipset-software/327432-004_espi_base_specification_rev1.0_cb.pdf)
