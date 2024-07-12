-- Please update version.sql too -- this keeps clean builds in sync
define version=2395
@update_header

BEGIN
	FOR R IN (
		SELECT table_name,constraint_name 
		  FROM all_constraints 
		 WHERE owner='CSRIMP' 
		   AND constraint_name IN (
			'PK_CHAIN_CARD', 
			'UC_CHAIN_CARD_JS'
		)
	) 
	LOOP
		dbms_output.put_line('alter table CSRIMP.'||r.table_name||' drop constraint '||r.constraint_name ||' DROP INDEX;');
		EXECUTE IMMEDIATE ('alter table CSRIMP.'||r.table_name||' drop constraint '||r.constraint_name || ' DROP INDEX');
	END LOOP;
END;
/
ALTER TABLE CSRIMP.CHAIN_CARD ADD CONSTRAINT PK_CHAIN_CARD PRIMARY KEY (CSRIMP_SESSION_ID, CARD_ID);
ALTER TABLE CSRIMP.CHAIN_CARD ADD CONSTRAINT UC_CHAIN_CARD_JS UNIQUE (CSRIMP_SESSION_ID, JS_CLASS_TYPE);

BEGIN
	FOR R IN (
		SELECT index_name 
		  FROM all_indexes
		 WHERE owner='CSRIMP' 
		   AND index_name IN (
			'IX_CHAIN_CARD_INIT_PARAM'
		)
	) 
	LOOP
		dbms_output.put_line('drop index '||r.index_name);
		EXECUTE IMMEDIATE ('drop index CSRIMP.'||r.index_name);
	END LOOP;
END;
/
CREATE UNIQUE INDEX CSRIMP.IX_CHAIN_CARD_INIT_PARAM ON CSRIMP.CHAIN_CARD_INIT_PARAM (CSRIMP_SESSION_ID, CARD_ID, KEY, CASE WHEN PARAM_TYPE_ID = 0 /* GLOBAL */ THEN 1 ELSE CARD_GROUP_ID END);

@update_tail
