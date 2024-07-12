-- -- Please update version.sql too -- this keeps clean builds in sync
define version=2431
@update_header

INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, DEFAULT_STATE, SCRIPT_PATH) 
VALUES (1049,'Load saved record','Credit360.Portlets.RecordLoader',EMPTY_CLOB(),'/csr/site/portal/portlets/RecordLoader.js');

@update_tail
