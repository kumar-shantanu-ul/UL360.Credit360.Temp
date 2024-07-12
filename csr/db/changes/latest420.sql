-- Please update version.sql too -- this keeps clean builds in sync
define version=420
@update_header

ALTER TABLE CUSTOMER ADD (
	TRUCOST_COMPANY_ID	 		NUMBER(10),
	LAST_TRUCOST_REPORT_ID 		NUMBER(10),
	CURRENT_TRUCOST_REPORT_ID 	NUMBER(10)
);


INSERT INTO PORTLET 
(PORTLET_ID, NAME, TYPE, SCRIPT_PATH) 
VALUES 
(portlet_id_seq.nextval, 'Trucost Peer Comparison', 'Credit360.Portlets.Trucost.PeerComparison', '/trucost/site/portlets/peerComparison.js');



@update_tail
