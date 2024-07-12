-- Please update version.sql too -- this keeps clean builds in sync
define version=556
@update_header

update ALERT_TYPE_PARAM set description = 'From e-mail' WHERE DESCRIPTION = 'From email';

BEGIN
INSERT INTO PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'Region list', 'Credit360.Portlets.RegionList', '/csr/site/portal/Portlets/RegionList.js');
END;
/

@update_tail
