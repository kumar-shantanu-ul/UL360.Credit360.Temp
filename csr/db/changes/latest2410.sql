-- -- Please update version.sql too -- this keeps clean builds in sync
define version=2410
@update_header

BEGIN
  INSERT 
    INTO CSR.flow_alert_class 
  VALUES ('chemical', 'Chemical');
EXCEPTION  
  WHEN DUP_VAL_ON_INDEX THEN
    NULL;
END;
/

-- !!!!! NEED TO BE RELEASED OUT OF HOURS BECAUSE OF THAT !!!
BEGIN
	FOR x in (SELECT 1 FROM DUAL WHERE NOT EXISTS (SELECT * 
													 FROM all_tab_columns 
													WHERE owner = 'CSR' AND table_name = 'CUSTOMER' AND column_name = 'CHEMICAL_FLOW_SID')) 
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.CUSTOMER ADD ( CHEMICAL_FLOW_SID NUMBER(10, 0))';
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.CUSTOMER 
			ADD CONSTRAINT fk_customer_chemical_flow_sid foreign key (app_sid, chemical_flow_sid) references csr.flow (app_sid, flow_sid)';

  EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.CUSTOMER ADD ( CHEMICAL_FLOW_SID NUMBER(10, 0) )';
	END LOOP;
END;
/

-- Back up CHEM.CAS table
BEGIN
	FOR x in (SELECT 1 FROM DUAL
				WHERE NOT EXISTS (SELECT * 
									  FROM all_tab_columns 
									 WHERE owner = 'CHEM'
									   AND table_name = 'BACKUP_CAS')
				) 
	LOOP
		EXECUTE IMMEDIATE 'CREATE TABLE chem.backup_cas AS SELECT * FROM chem.cas';
	END LOOP;
END;
/

-- rest only if CHEM schema exist - need to add some checking:
BEGIN
	FOR x IN (SELECT username FROM dba_users where USERNAME = 'CHEM')
	LOOP
		FOR y in (SELECT 1 FROM DUAL WHERE NOT EXISTS (SELECT * 
														 FROM all_tab_columns 
														WHERE owner = 'CHEM' AND table_name = 'SUBSTANCE' AND column_name = 'IS_CENTRAL')) 
		LOOP
			EXECUTE IMMEDIATE 'ALTER TABLE CHEM.SUBSTANCE ADD IS_CENTRAL NUMBER(1) DEFAULT 0';
			EXECUTE IMMEDIATE 'UPDATE CHEM.SUBSTANCE SET IS_CENTRAL = 0';
			EXECUTE IMMEDIATE 'ALTER TABLE CHEM.SUBSTANCE ADD CONSTRAINT CHK_SUBSTANCE_IS_CENTRAL 
								CHECK (IS_CENTRAL IN (0,1))';
		END LOOP;

		-- Need grant before adding FK
		EXECUTE IMMEDIATE 'GRANT INSERT,SELECT,REFERENCES ON csr.flow_item TO chem';

		FOR z in (SELECT 1 FROM DUAL WHERE NOT EXISTS (SELECT * 
														 FROM all_tab_columns 
														WHERE owner = 'CHEM' AND table_name = 'SUBSTANCE_REGION' AND column_name = 'FLOW_ITEM_ID')) 
		LOOP
			EXECUTE IMMEDIATE 'ALTER TABLE CHEM.SUBSTANCE_REGION ADD FLOW_ITEM_ID	NUMBER(10)';
			EXECUTE IMMEDIATE 'ALTER TABLE CHEM.SUBSTANCE_REGION ADD CONSTRAINT FK_SUBSTANCE_REGION_FLOW_ITEM 
				FOREIGN KEY (APP_SID, FLOW_ITEM_ID)
				REFERENCES CSR.FLOW_ITEM(APP_SID, FLOW_ITEM_ID)';
		END LOOP;

		EXECUTE IMMEDIATE 'COMMENT ON COLUMN CHEM.SUBSTANCE_REGION.FLOW_ITEM_ID IS ''desc="Flow item id",flow_item''';
		EXECUTE IMMEDIATE 'COMMENT ON COLUMN CHEM.SUBSTANCE_REGION.REGION_SID IS ''desc="Region",flow_region''';

		EXECUTE IMMEDIATE 'GRANT SELECT ON csr.flow TO chem';
		EXECUTE IMMEDIATE 'GRANT SELECT ON csr.flow_state_log TO chem';
		EXECUTE IMMEDIATE 'GRANT SELECT ON csr.flow_item_id_seq to chem';
		EXECUTE IMMEDIATE 'GRANT SELECT ON csr.role TO chem WITH GRANT OPTION';
		EXECUTE IMMEDIATE 'GRANT SELECT ON csr.region_role_member TO chem WITH GRANT OPTION';
		EXECUTE IMMEDIATE 'GRANT SELECT ON csr.flow_state_role TO chem   WITH GRANT OPTION';
		EXECUTE IMMEDIATE 'GRANT SELECT ON csr.customer TO chem';
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON csr.flow_pkg TO chem';
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON csr.delegation_pkg TO chem';
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON csr.region_pkg TO chem';
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON csr.val_pkg TO chem';
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON csr.stragg TO chem';
		EXECUTE IMMEDIATE 'GRANT SELECT ON csr.v$open_flow_item_alert TO chem';
		EXECUTE IMMEDIATE 'GRANT SELECT ON csr.flow_state TO chem  WITH GRANT OPTION';
		EXECUTE IMMEDIATE 'GRANT SELECT ON csr.region TO chem WITH GRANT OPTION';
		EXECUTE IMMEDIATE 'GRANT SELECT ON csr.flow_item TO chem WITH GRANT OPTION';

		EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW chem.v$my_substance_region AS
			SELECT sr.app_sid, sr.region_sid, sr.substance_id, MAX(fsr.is_editable) is_editable
			  FROM csr.region_role_member rrm
			  JOIN csr.role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
			  JOIN csr.flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
			  JOIN csr.flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid 
			  JOIN csr.flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
			  JOIN chem.substance_region sr ON fi.flow_item_id = sr.flow_item_id AND rrm.region_sid = sr.region_sid AND rrm.app_sid = sr.app_sid
			  JOIN csr.region rg ON sr.region_sid = rg.region_sid AND sr.app_Sid = rg.app_sid
			 WHERE rrm.user_sid = SYS_CONTEXT(''SECURITY'',''SID'')
			 group by sr.app_sid, sr.region_sid, sr.substance_id';
		 
		EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW chem.v$substance_region AS
			SELECT sr.app_sid, sr.region_sid, sr.substance_id, sr.flow_item_id, 
				fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key,  
				fs.state_colour current_state_colour, sr.first_used_dtm, sr.local_ref, rg.active
			  FROM chem.substance_region sr
			  JOIN csr.flow_item fi ON fi.flow_item_id = sr.flow_Item_id
			  JOIN csr.flow_state fs ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
			  JOIN csr.region rg ON sr.region_sid = rg.region_sid AND sr.app_Sid = rg.app_sid';

	END LOOP;
END;
/

@../flow_pkg
@../chem/substance_pkg

@../flow_body
@../chem/substance_body
@../csr_app_body

@update_tail