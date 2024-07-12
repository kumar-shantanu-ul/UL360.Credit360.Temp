-- Please update version.sql too -- this keeps clean builds in sync
define version=1247
@update_header

UPDATE ct.ps_item SET KG_CO2 = null; 

--- recacled when model runs 

ALTER TABLE CT.PS_ITEM
MODIFY(KG_CO2 NUMBER(20,3)); 


@..\ct\breakdown_type_pkg
@..\ct\breakdown_type_body
@..\ct\hotspot_pkg
@..\ct\hotspot_body
@..\ct\value_chain_report_pkg
@..\ct\value_chain_report_body
@..\ct\supplier_body


@update_tail
