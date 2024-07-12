-- Please update version.sql too -- this keeps clean builds in sync
define version=682
@update_header

INSERT INTO csr.PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH, DEFAULT_STATE) VALUES (csr.portlet_id_seq.nextval, 'My forms', 'Credit360.Portlets.MySheets', '/csr/site/portal/Portlets/MySheets.js', '{"portletHeight":400}');

INSERT INTO csr.CUSTOMER_PORTLET(portlet_id, app_sid) SELECT csr.portlet_id_seq.currval, app_sid FROM CUSTOMER;

@update_tail


