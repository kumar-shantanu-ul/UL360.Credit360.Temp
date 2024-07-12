define version=2183
@update_header

begin
	-- select from ALL_POLICIES and restrict by OBJECT_OWNER in case we have to run this as another user with grant execute on dbms_rls
	for r in (select object_name, policy_name from all_policies where object_owner='CHAIN' and object_name='PRODUCT') loop
		dbms_rls.drop_policy(
            object_schema   => 'CHAIN',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    end loop;
end;
/

--If this first statement fails with ORA-28133, try running the script as sysdba
ALTER TABLE CHAIN.PRODUCT ADD (VALIDATED_ROOT_COMPONENT_ID   NUMBER(10, 0),
							   VALIDATION_STATUS   VARCHAR2(100) DEFAULT 'Initial' NOT NULL);
ALTER TABLE CHAIN.PRODUCT ADD CONSTRAINT CONS_PSEUDO_ROOT_COMPONENT_ID  UNIQUE (PSEUDO_ROOT_COMPONENT_ID);
ALTER TABLE CHAIN.PRODUCT ADD CONSTRAINT CONS_VAL_ROOT_COMPONENT_ID  UNIQUE (VALIDATED_ROOT_COMPONENT_ID);

ALTER TABLE CHAIN.PRODUCT ADD CONSTRAINT RefCOMPONENT516
    FOREIGN KEY (APP_SID, VALIDATED_ROOT_COMPONENT_ID)
    REFERENCES CHAIN.COMPONENT(APP_SID, COMPONENT_ID)
;

ALTER TABLE CHAIN.PRODUCT ADD CONSTRAINT
	CHK_VALIDATION_STATUS CHECK
	(VALIDATION_STATUS IN ('Initial', 'Not yet validated', 'Validation needs review', 'Validation in progress', 'Validated'))
;

CREATE INDEX CHAIN.IX_PRODUCT_VALIDATED_ROOT_C ON CHAIN.PRODUCT (app_sid, validated_root_component_id);

CREATE OR REPLACE VIEW CHAIN.v$product AS
	SELECT cmp.app_sid, p.product_id, p.pseudo_root_component_id, p.validated_root_component_id, cmp.component_id root_component_id,
			p.active, cmp.component_code code1, p.code2, p.code3, p.notes, p.need_review,
			cmp.description, cmp.component_code, cmp.deleted,
			p.company_sid, cmp.created_by_sid, cmp.created_dtm,
			p.published, p.last_published_dtm, p.last_published_by_user_sid, p.validation_status
	  FROM product p
	  JOIN component cmp ON p.app_sid = cmp.app_sid AND DECODE(p.validation_status, 'Validated', p.validated_root_component_id, p.pseudo_root_component_id) = cmp.component_id
	 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
;

CREATE OR REPLACE VIEW CHAIN.v$purchased_component AS
	SELECT cmp.app_sid, cmp.component_id, 
			cmp.description, cmp.component_code, cmp.component_notes, cmp.deleted,
			pc.company_sid, cmp.created_by_sid, cmp.created_dtm,
			pc.component_supplier_type_id, pc.acceptance_status_id,
			pc.supplier_company_sid, supp.name supplier_name, supp.country_code supplier_country_code, supp.country_name supplier_country_name, 
			pc.purchaser_company_sid, pur.name purchaser_name, pur.country_code purchaser_country_code, pur.country_name purchaser_country_name, 
			pc.uninvited_supplier_sid, unv.name uninvited_name, unv.country_code uninvited_country_code, NULL uninvited_country_name, 
			pc.supplier_product_id, NVL2(pc.supplier_product_id, 1, 0) mapped, mapped_by_user_sid, mapped_dtm,
			p.description supplier_product_description, p.code1 supplier_product_code1, p.code2 supplier_product_code2, p.code3 supplier_product_code3, 
			p.published supplier_product_published, p.last_published_dtm supplier_product_published_dtm, pc.purchases_locked, p.validation_status
	  FROM purchased_component pc
	  JOIN component cmp ON pc.app_sid = cmp.app_sid AND pc.component_id = cmp.component_id
	  LEFT JOIN v$product p ON pc.app_sid = p.app_sid AND pc.supplier_product_id = p.product_id
	  LEFT JOIN v$company supp ON pc.app_sid = supp.app_sid AND pc.supplier_company_sid = supp.company_sid
	  LEFT JOIN v$company pur ON pc.app_sid = pur.app_sid AND pc.purchaser_company_sid = pur.company_sid
	  LEFT JOIN uninvited_supplier unv ON pc.app_sid = unv.app_sid AND pc.uninvited_supplier_sid = unv.uninvited_supplier_sid AND pc.company_sid = unv.company_sid
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
;

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_PRODUCT_COMPONENT_TREE
(
	TOP_COMPONENT_ID			NUMBER(10) NOT NULL,
	TOP_PRODUCT_ID				NUMBER(10) NOT NULL
)
ON COMMIT DELETE ROWS;

CREATE UNIQUE INDEX CHAIN.IX_COMPONENT_DELETED ON CHAIN.COMPONENT(APP_SID, DELETED, COMPONENT_ID);

CREATE TABLE CHAIN.VALIDATED_PURCHASED_COMPONENT(
    APP_SID                       	NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPONENT_ID                  	NUMBER(10, 0)    NOT NULL,
    MAPPED_PURCHASED_COMPONENT_ID	NUMBER(10, 0),
    CONSTRAINT PK_VAL_PURCH_COMP PRIMARY KEY (APP_SID, COMPONENT_ID)
)
;

ALTER TABLE CHAIN.VALIDATED_PURCHASED_COMPONENT ADD CONSTRAINT RefCOMPONENT_VALIDATED_PC
    FOREIGN KEY (APP_SID, COMPONENT_ID)
    REFERENCES CHAIN.COMPONENT(APP_SID, COMPONENT_ID)
;

ALTER TABLE CHAIN.VALIDATED_PURCHASED_COMPONENT ADD CONSTRAINT RefPURCH_COMPONENT_VAL_PC
    FOREIGN KEY (APP_SID, MAPPED_PURCHASED_COMPONENT_ID)
    REFERENCES CHAIN.PURCHASED_COMPONENT(APP_SID, COMPONENT_ID)
;

BEGIN
	UPDATE chain.product
	   SET validation_status = 'Validation needs review'
	 WHERE published = 1;
	   --AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;
/

DROP PACKAGE chain.component_report_pkg;
DROP VIEW chain.v$component_rel_amounts;
DROP VIEW chain.v$component_product_rel;
DROP TABLE chain.tt_purchases;

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner = 'CHAIN' AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'APP_SID'
		   AND t.table_name IN ('PRODUCT', 'VALIDATED_PURCHASED_COMPONENT')
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
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');	
END;
/


create or replace package CHAIN.VALIDATED_PURCH_COMPONENT_PKG as end;
/
GRANT EXECUTE ON CHAIN.VALIDATED_PURCH_COMPONENT_PKG TO WEB_USER;

@..\chain\chain_pkg
@..\chain\product_pkg
@..\chain\product_body
@..\chain\company_user_body
@..\chain\validated_purch_component_pkg
@..\chain\validated_purch_component_body
@..\chain\purchased_component_pkg
@..\chain\purchased_component_body
@..\chain\component_pkg
@..\chain\component_body
@..\supplier_pkg
@..\supplier_body
@..\issue_body

@update_tail
