define version=83
@update_header

CREATE TABLE chain.AMOUNT_UNIT(
    AMOUNT_UNIT_ID    NUMBER(10, 0)    NOT NULL,
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    DESCRIPTION       VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK285 PRIMARY KEY (AMOUNT_UNIT_ID, APP_SID)
)
;

ALTER TABLE chain.COMPONENT_RELATIONSHIP
 ADD (AMOUNT_CHILD_PER_PARENT  NUMBER(10,3));

ALTER TABLE chain.COMPONENT_RELATIONSHIP
 ADD (AMOUNT_UNIT_ID  NUMBER(10));
 
 
ALTER TABLE chain.AMOUNT_UNIT ADD CONSTRAINT RefCUSTOMER709 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

begin
	for r in (select 1 from all_users where username='RFA') loop
		execute immediate 'grant select on chain.amount_unit to rfa';
	end loop;
end;
/

ALTER TABLE chain.COMPONENT_RELATIONSHIP ADD CONSTRAINT RefAMOUNT_UNIT710 
    FOREIGN KEY (AMOUNT_UNIT_ID, APP_SID)
    REFERENCES AMOUNT_UNIT(AMOUNT_UNIT_ID, APP_SID)
;

ALTER TABLE chain.TT_COMPONENT_TREE
 ADD (AMOUNT_CHILD_PER_PARENT  NUMBER(10,3));

ALTER TABLE chain.TT_COMPONENT_TREE
 ADD (AMOUNT_UNIT_ID  NUMBER(10));

BEGIN
	FOR r IN (
		SELECT object_name, policy_name 
		  FROM all_policies 
		 WHERE object_owner='CHAIN' and function IN ('APPSIDCHECK', 'NULLABLEAPPSIDCHECK')
		 AND lower(policy_name) = 'amount_unit_pol'
	) LOOP
		dbms_rls.drop_policy(
            object_schema   => 'CHAIN',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    END LOOP;
END;
/

BEGIN
	
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		 INNER JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner = 'CHAIN' AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'APP_SID'
		 AND lower(c.table_name) = 'amount_unit'
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => r.owner,
			policy_function => (CASE WHEN r.nullable ='N' THEN 'appSidCheck' ELSE 'nullableAppSidCheck' END),
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static);
	END LOOP;
	
END;
/

@update_tail