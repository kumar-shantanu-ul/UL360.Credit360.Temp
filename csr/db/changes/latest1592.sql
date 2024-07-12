-- Please update version.sql too -- this keeps clean builds in sync
define version=1592
@update_header

BEGIN
	FOR r IN (
		SELECT *
		  FROM dual
		 WHERE NOT EXISTS (SELECT NULL FROM all_indexes WHERE owner='CSR' and index_name='IX_CSR_USER_IMP_SESSION_M')
	) LOOP
		EXECUTE IMMEDIATE 'create index csr.ix_csr_user_imp_session_m on csr.csr_user (app_sid, imp_session_mount_point_sid)';
	END LOOP;
END;
/

@update_tail