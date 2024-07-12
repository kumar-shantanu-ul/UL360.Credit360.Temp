-- Please update version.sql too -- this keeps clean builds in sync
define version=2379
@update_header

-- Table appears to be deprecated, but constraint is causing problems for csrimp.
BEGIN
	FOR R IN (
		SELECT table_name,constraint_name 
		  FROM all_constraints 
		 WHERE owner='CSRIMP' 
		   AND constraint_name IN (
			'PK_DELEGATION_IND_COND_ACTION'
		)
	) 
	LOOP
		dbms_output.put_line('alter table CSRIMP.'||r.table_name||' drop constraint '||r.constraint_name);
		EXECUTE IMMEDIATE ('alter table CSRIMP.'||r.table_name||' drop constraint '||r.constraint_name);
	END LOOP;
END;
/

@update_tail
