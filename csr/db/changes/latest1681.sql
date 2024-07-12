-- Please update version.sql too -- this keeps clean builds in sync
define version=1681
@update_header

-- Copy templated report name to securable object
UPDATE security.securable_object so
   SET name = (
		SELECT REPLACE(name, '/', '\') tr
		  FROM csr.tpl_report tr
		 WHERE tr.tpl_report_sid = so.sid_id
		)
 WHERE so.sid_id IN (
		SELECT tpl_report_sid
		  FROM csr.tpl_report
		);

@..\templated_report_body

@update_tail
