-- Please update version.sql too -- this keeps clean builds in sync
-- Check the portlet ID is still the "next" one.
define version=2279
@update_header

BEGIN
INSERT INTO csr.portlet (
     PORTLET_ID, NAME, TYPE, SCRIPT_PATH
 ) VALUES (
     1047,
     'Data Submitted Gauge',
     'Credit360.Portlets.DataSubmittedGauge',
     '/csr/site/portal/Portlets/DataSubmittedGauge.js'
 );
END;
/

@update_tail
