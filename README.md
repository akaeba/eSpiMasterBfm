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
| latest  |            | <a id="raw-url" href="https://github.com/akaeba/eSpiMasterBfm/archive/master.zip ">latest.zip</a> | latest                                          |
| v0.1.0  |            |                                                                                                   | Configuration; IO read/write; Memory read/write |


## Example

The full provided function set is demonstrated in _[eSpiStaticSlave_tb.vhd](https://github.com/akaeba/eSpiMasterBfm/blob/master/tb/eSpiStaticSlave_tb.vhd)_.
A tiny testbench example shows th snippet below:

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
    wait;   -- stop continous run
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

| File                                                                                                    | Group | Remark                                                                 |
| ------------------------------------------------------------------------------------------------------- | ----- | ---------------------------------------------------------------------- |
| [eSpiMasterBfm.vhd](https://github.com/akaeba/eSpiMasterBfm/blob/master/bfm/eSpiMasterBfm.vhd)          | BFM   | provides VHDL procedures to interact with an eSPI Slave                |
| [eSpiStaticSlave.vhd](https://github.com/akaeba/eSpiMasterBfm/blob/master/bfm/eSpiStaticSlave.vhd)      | BFM   | ASCII hex request/completion checking slave, supports eSpiMasterBfm TB |
| [eSpiMasterBfm_tb.vhd](https://github.com/akaeba/eSpiMasterBfm/blob/master/tb/eSpiMasterBfm_tb.vhd)     | TB    | checks functionality of _eSpiMasterBfm_                                |
| [eSpiStaticSlave_tb.vhd](https://github.com/akaeba/eSpiMasterBfm/blob/master/tb/eSpiStaticSlave_tb.vhd) | TB    | checks functionality of _eSpiStaticSlave_                              |


## Procedures

### init

Initializes the BFM.
```vhdl
init(this, CSn, SCK, DIO);
```


### RESET

Resets endpoint.
```vhdl
RESET(this, CSn, SCK, DIO);
```



### Endpoint Management

Handles eSPI endpoints configuration and status.


#### GET_CONFIGURATION

Reads configuration registers from eSPI slave. From the _GET_CONFIGURATION_ procedures exists two variants.
The first one reads the into configuration into variables. The second one prints the configuration into
simulators log.

```vhdl
GET_CONFIGURATION(this, CSn, SCK, DIO, adr, config, status, response);  -- read into variables
GET_CONFIGURATION(this, CSn, SCK, DIO, adr, good);                      -- print to console
```


#### SET_CONFIGURATION

Writes into slaves configuration registers.

```vhdl
SET_CONFIGURATION(this, CSn, SCK, DIO, adr, config, status, response);  -- propagates slaves status regs back
SET_CONFIGURATION(this, CSn, SCK, DIO, adr, config, good);              -- evaluated for success via good
```


#### GET_STATUS

Reads slaves status register.

```vhdl
GET_STATUS(this, CSn, SCK, DIO, status, response);  -- read status reg into variable
GET_STATUS(this, CSn, SCK, DIO, good);              -- read status reg and print interpretation to console
```



### Memory-mapped

TODO



### IO-mapped

#### IOWR

Writes to IO mapped address space.

```vhdl
IOWR(this, CSn, SCK, DIO, adr, data, good);         -- default, 8bit data
IOWR_BYTE(this, CSn, SCK, DIO, adr, data, good);    -- 8bit data
IOWR_WORD(this, CSn, SCK, DIO, adr, data, good);    -- 16bit data
IOWR_DWORD(this, CSn, SCK, DIO, adr, data, good);   -- 32bit data
```


#### IORD

Reads from IO mapped address space.

```vhdl
IORD(this, CSn, SCK, DIO, adr, data, good);         -- default, 8bit data
IORD_BYTE(this, CSn, SCK, DIO, adr, data, good);    -- 8bit data
IORD_WORD(this, CSn, SCK, DIO, adr, data, good);    -- 16bit data
IORD_DWORD(this, CSn, SCK, DIO, adr, data, good);   -- 32bit data
```


## References

 * [Intel eSPI Specification](https://www.intel.com/content/dam/support/us/en/documents/software/chipset-software/327432-004_espi_base_specification_rev1.0_cb.pdf)
