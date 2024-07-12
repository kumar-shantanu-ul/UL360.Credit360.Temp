-- Please update version.sql too -- this keeps clean builds in sync
define version=2280
@update_header

BEGIN
	FOR r IN (
		SELECT owner, table_name
		  FROM all_tables
		 WHERE owner IN ('CSR','CSRIMP')
		   AND table_name IN ('ROOT_SECTION_USER','SECTION_APPROVERS')
		)
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE '||r.owner||'.'||r.table_name;
	END LOOP;
END;
/

@..\csr_app_body

@update_tail