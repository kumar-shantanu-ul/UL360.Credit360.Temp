-- Please update version.sql too -- this keeps clean builds in sync
define version=528
@update_header

INSERT INTO portlet (portlet_id, name, type, script_path)
	VALUES (portlet_id_seq.nextval, 'Document', 'Credit360.Portlets.Document', '/csr/site/portal/Portlets/Document.js');

@update_tail
