-- Please update version.sql too -- this keeps clean builds in sync
define version=1629
@update_header

ALTER TABLE csr.tpl_report ADD parent_sid NUMBER(10, 0) NULL;

UPDATE csr.tpl_report tr
   SET parent_sid = (
		SELECT parent_sid_id
		  FROM security.securable_object so
		 WHERE so.sid_id = tr.tpl_report_sid
		);
		
ALTER TABLE csr.tpl_report MODIFY parent_sid NOT NULL;

ALTER TABLE csrimp.tpl_report ADD parent_sid NUMBER(10, 0);

@../templated_report_pkg
@../templated_report_body
@../schema_body
@../csrimp/imp_body

@update_tail
