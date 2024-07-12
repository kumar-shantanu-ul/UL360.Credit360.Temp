-- Please update version.sql too -- this keeps clean builds in sync
define version=405
@update_header

UPDATE portlet SET script_path = REPLACE(script_path,'/csr/site/portal/Credit360.Portlets.', '/csr/site/portal/Portlets/');

INSERT INTO PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'Region picker', 'Credit360.Portlets.RegionPicker', '/csr/site/portal/Portlets/RegionPicker.js');

@update_tail
