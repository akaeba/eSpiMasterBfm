# eSpiMasterBfm
Enhanced SPI Master Bus Functional Model


## Features

The _eSpiMasterBfm_ provides VHDL procedures to interact with an eSPI endpoint. 
Currently are procedures available for:
 * IO Read/Write
 * Memory Read/Write
 * Endpoint Configuration
 

## Enhanced Serial Peripheral Interface (ESPI)
 


## File Listing

| File                                                                                                | Remark            |
| --------------------------------------------------------------------------------------------------- | ----------------- |
| [eSpiMasterBfm.vhd](https://github.com/akaeba/eSpiMasterBfm/blob/master/bfm/eSpiMasterBfm.vhd)      | BFM package       |
| [eSpiMasterBfm_tb.vhd](https://github.com/akaeba/eSpiMasterBfm/blob/master/tb/eSpiMasterBfm_tb.vhd) | Testbench for BFM |


## How-to use



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


### GET_CONFIGURATION

Reads configuration registers from eSPI slave. From the _GET_CONFIGURATION_ procedures exists two variants.
The first one reads the into configuration into variables. The second one prints the configuration into
simulators log.

```vhdl
GET_CONFIGURATION(this, CSn, SCK, DIO, adr, config, status, response);  -- read into variables
GET_CONFIGURATION(this, CSn, SCK, DIO, adr, config, good);              -- print to console
```




## References

 * [Intel eSPI Specification](https://www.intel.com/content/dam/support/us/en/documents/software/chipset-software/327432-004_espi_base_specification_rev1.0_cb.pdf)
