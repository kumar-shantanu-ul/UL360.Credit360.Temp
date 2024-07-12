define version=3254
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
DROP TYPE CSR.T_FLOW_STATE_TABLE;
CREATE OR REPLACE TYPE     CSR.T_FLOW_STATE_ROW AS
	OBJECT (
		XML_POS					NUMBER(10),	
		POS						NUMBER(10), 
		ID						NUMBER(10), 
		LABEL					VARCHAR2(255), 
		LOOKUP_KEY				VARCHAR2(255),
		IS_FINAL				NUMBER(1),
		STATE_COLOUR			NUMBER(10),
		EDITABLE_ROLE_SIDS		VARCHAR2(2000),
		NON_EDITABLE_ROLE_SIDS	VARCHAR2(2000),
		EDITABLE_COL_SIDS		VARCHAR2(2000),
		NON_EDITABLE_COL_SIDS	VARCHAR2(2000),
		INVOLVED_TYPE_IDS		VARCHAR2(2000),
		ATTRIBUTES_XML			XMLType,
		FLOW_STATE_NATURE_ID	NUMBER(10),
		MOVE_FROM_FLOW_STATE_ID NUMBER(10)
	);
/
CREATE OR REPLACE TYPE     CSR.T_FLOW_STATE_TABLE AS
  TABLE OF CSR.T_FLOW_STATE_ROW;
/


ALTER TABLE CSR.T_FLOW_STATE ADD MOVE_TO_FLOW_STATE_ID	NUMBER(10);
ALTER TABLE CSR.T_FLOW_STATE RENAME COLUMN MOVE_TO_FLOW_STATE_ID TO MOVE_FROM_FLOW_STATE_ID;
ALTER TABLE CSR.FLOW_STATE RENAME COLUMN MOVE_TO_FLOW_STATE_ID TO MOVE_FROM_FLOW_STATE_ID;
ALTER TABLE CSRIMP.FLOW_STATE RENAME COLUMN MOVE_TO_FLOW_STATE_ID TO MOVE_FROM_FLOW_STATE_ID;










UPDATE csr.flow_state
   SET move_from_flow_state_id = NULL
 WHERE move_from_flow_state_id IS NOT NULL
   AND is_deleted = 0;
/






@..\flow_pkg


@..\flow_body
@..\csrimp\imp_body
@..\schema_body
@..\enable_body



@update_tail
