-- Please update version.sql too -- this keeps clean builds in sync
define version=1803
@update_header


/* Better RLS */   
BEGIN
	

	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'EXPORT_FEED_CMS_FORM',
		policy_name     => 'EXPORT_FEED_CMS_FORM_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

grant select on cms.form to csr;

-- No clue why TAB was here

ALTER TABLE CSR.EXPORT_FEED_CMS_FORM drop CONSTRAINT FK_EXP_CMS_FORM_TAB;

ALTER TABLE CSR.EXPORT_FEED_CMS_FORM add CONSTRAINT FK_EXP_CMS_FORM_FORM
    FOREIGN KEY (APP_SID, FORM_SID) REFERENCES CMS.FORM (APP_SID, FORM_SID);


@update_tail
