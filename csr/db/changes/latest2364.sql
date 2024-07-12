-- Please update version.sql too -- this keeps clean builds in sync
define version=2364
@update_header

-- drop constraints referring to component_bind, component_relationship
BEGIN
	FOR R IN (
		SELECT table_name,constraint_name 
		  FROM all_constraints 
		 WHERE owner='CHAIN' 
		   AND constraint_name IN (
			'REFCOMPONENT539', 
			'REFCOMPONENT_BIND581', 
			'REFCOMPONENT_BIND582', 
			'REFCOMPONENT_BIND585', 
			'REFCOMPONENT_BIND586', 
			'REFCOMPONENT_TYPE_CONTAINME583',
			'REFAMOUNT_UNIT897'
		)
	) 
	LOOP
		dbms_output.put_line('alter table chain.'||r.table_name||' drop constraint '||r.constraint_name);
		EXECUTE IMMEDIATE ('alter table chain.'||r.table_name||' drop constraint '||r.constraint_name);
	END LOOP;
END;
/

exec dbms_output.put_line('move component_bind columns to component');
ALTER TABLE chain.component ADD COMPONENT_TYPE_ID 			NUMBER(10, 0);
ALTER TABLE chain.component ADD COMPANY_SID 				NUMBER(10, 0);

BEGIN
	UPDATE chain.component c
	   SET (component_type_id, company_sid) =(
			SELECT component_type_id, company_sid
			  FROM chain.component_bind cb
			 WHERE cb.app_sid = c.app_sid
			   AND cb.component_id = c.component_id 
	   );
	DELETE FROM chain.component
	  WHERE component_type_id IS NULL;
END;
/ 

ALTER TABLE chain.component MODIFY COMPONENT_TYPE_ID NUMBER(10, 0) NOT NULL;
ALTER TABLE chain.component MODIFY COMPANY_SID NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')  NOT NULL;

exec dbms_output.put_line('move component_relationship columns to component');
ALTER TABLE chain.component ADD PARENT_COMPONENT_ID 		NUMBER(10, 0);
ALTER TABLE chain.component ADD PARENT_COMPONENT_TYPE_ID 	NUMBER(10, 0);
ALTER TABLE chain.component ADD POSITION					NUMBER(10);
ALTER TABLE chain.component ADD AMOUNT_CHILD_PER_PARENT		NUMBER(10,3);
ALTER TABLE chain.component ADD AMOUNT_UNIT_ID				NUMBER(10);

BEGIN
	UPDATE chain.component c
	   SET (parent_component_id, parent_component_type_id, position, amount_child_per_parent, amount_unit_id) = (
			SELECT container_component_id, container_component_type_id, position, amount_child_per_parent, amount_unit_id
			  FROM chain.component_relationship cr
			 WHERE cr.app_sid = c.app_sid
			   AND cr.child_component_id = c.component_id 
			   AND cr.child_component_type_id = c.component_type_id 
	   )
	 WHERE EXISTS (
		SELECT 1
		  FROM chain.component_relationship cr
		 WHERE cr.app_sid = c.app_sid
		   AND cr.child_component_id = c.component_id 
		   AND cr.child_component_type_id = c.component_type_id 
	 );
END;
/ 

exec dbms_output.put_line('change FK from component_relationship to link to chain.component');

ALTER TABLE CHAIN.COMPONENT ADD CONSTRAINT FK_COMPONENT_CMP_TYPE_CONTAIN
	FOREIGN KEY (APP_SID, PARENT_COMPONENT_TYPE_ID, COMPONENT_TYPE_ID)
	REFERENCES CHAIN.COMPONENT_TYPE_CONTAINMENT (APP_SID, CONTAINER_COMPONENT_TYPE_ID, CHILD_COMPONENT_TYPE_ID);

ALTER TABLE CHAIN.COMPONENT ADD CONSTRAINT FK_COMPONENT_PARENT_CHILD
	FOREIGN KEY  (APP_SID, PARENT_COMPONENT_ID)
	REFERENCES CHAIN.COMPONENT (APP_SID, COMPONENT_ID);
	
ALTER TABLE CHAIN.COMPONENT ADD CONSTRAINT FK_COMPONENT_UNIT
    FOREIGN KEY (APP_SID, AMOUNT_UNIT_ID)
    REFERENCES CHAIN.AMOUNT_UNIT(APP_SID, AMOUNT_UNIT_ID)
;

ALTER TABLE CHAIN.COMPONENT ADD CONSTRAINT UK_COMPONENT UNIQUE(APP_SID, COMPONENT_ID, COMPANY_SID, COMPONENT_TYPE_ID);

ALTER TABLE CHAIN.PRODUCT ADD CONSTRAINT FK_PRODUCT_COMPONENT_PSEUDO
	FOREIGN KEY (APP_SID, PSEUDO_ROOT_COMPONENT_ID, COMPANY_SID, COMPONENT_TYPE_ID)
	REFERENCES CHAIN.COMPONENT(APP_SID, COMPONENT_ID, COMPANY_SID, COMPONENT_TYPE_ID);

ALTER TABLE CHAIN.PRODUCT ADD CONSTRAINT FK_PRODUCT_COMPONENT_VALIDATED
	FOREIGN KEY (APP_SID, VALIDATED_ROOT_COMPONENT_ID, COMPANY_SID, COMPONENT_TYPE_ID)
	REFERENCES CHAIN.COMPONENT(APP_SID, COMPONENT_ID, COMPANY_SID, COMPONENT_TYPE_ID);
	
exec dbms_output.put_line('change FK from PURCHASED_COMPONENT TO chain.component');
ALTER TABLE CHAIN.PURCHASED_COMPONENT ADD CONSTRAINT FK_PURCHASED_CMP_COMPONENTS
    FOREIGN KEY (APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
    REFERENCES CHAIN.COMPONENT(APP_SID, COMPONENT_ID, COMPONENT_TYPE_ID, COMPANY_SID)
;

CREATE INDEX CHAIN.IX_COMPONENT_PARENT_COMP ON CHAIN.COMPONENT (APP_SID, PARENT_COMPONENT_ID);

--Rename redundant tables
ALTER TABLE CHAIN.COMPONENT_BIND RENAME TO XX_COMPONENT_BIND;
ALTER TABLE CHAIN.COMPONENT_RELATIONSHIP RENAME	TO XX_COMPONENT_RELATIONSHIP;

DROP VIEW chain.v$component;

@../chain/component_pkg
@../chain/component_body
@../chain/chain_body
@../chain/company_body
@../chain/company_user_body
@../chain/message_body
@../chain/product_body

@update_tail
