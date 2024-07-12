-- Please update version.sql too -- this keeps clean builds in sync
define version=621
@update_header

DROP TRIGGER csr.UTILIY_CONTRACT_BD_TRIGGER;

CREATE TABLE csr.METER_UTILITY_CONTRACT(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    REGION_SID             NUMBER(10, 0)    NOT NULL,
    UTILITY_CONTRACT_ID    NUMBER(10, 0)    NOT NULL,
    ACTIVE                 NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CHECK (ACTIVE IN (0,1)),
    CONSTRAINT PK908 PRIMARY KEY (APP_SID, REGION_SID, UTILITY_CONTRACT_ID)
)
;

ALTER TABLE csr.METER_UTILITY_CONTRACT ADD CONSTRAINT RefUTILITY_CONTRACT2010 
    FOREIGN KEY (APP_SID, UTILITY_CONTRACT_ID)
    REFERENCES csr.UTILITY_CONTRACT(APP_SID, UTILITY_CONTRACT_ID)
;

ALTER TABLE csr.METER_UTILITY_CONTRACT ADD CONSTRAINT RefALL_METER2011 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES csr.ALL_METER(APP_SID, REGION_SID)
;

CREATE OR REPLACE FUNCTION csr.utilityContractCheck (
	in_schema IN VARCHAR2, 
	in_object IN VARCHAR2
)
RETURN VARCHAR2
AS
BEGIN
  return '';
end;
/

CREATE OR REPLACE FUNCTION csr.utilityInvoiceCheck (
	in_schema IN VARCHAR2, 
	in_object IN VARCHAR2
)
RETURN VARCHAR2
AS
BEGIN
  RETURN '';
end;
/

BEGIN
	user_pkg.logonadmin(NULL);
	FOR r IN (
		SELECT DISTINCT c.app_sid, c.host
		  FROM csr.customer c, csr.utility_contract u
		 WHERE c.app_sid = u.app_sid
	) LOOP
		user_pkg.logonadmin(r.host);
		INSERT INTO csr.meter_utility_contract
			(app_sid, region_sid, utility_contract_id, active) (
				SELECT r.app_sid, m.region_sid, m.utility_contract_id, 1
				  FROM csr.all_meter m
				 WHERE m.app_sid = r.app_sid
				   AND m.utility_contract_id IS NOT NULL
			);
		user_pkg.logonadmin(NULL);
	END LOOP;
END;
/

ALTER TABLE csr.ALL_METER DROP COLUMN utility_contract_id CASCADE CONSTRAINTS
;

CREATE OR REPLACE VIEW csr.METER
	(REGION_SID, NOTE, PRIMARY_IND_SID, PRIMARY_MEASURE_CONVERSION_ID, METER_SOURCE_TYPE_ID, REFERENCE, CRC_METER) AS
  SELECT REGION_SID, NOTE, PRIMARY_IND_SID, PRIMARY_MEASURE_CONVERSION_ID, METER_SOURCE_TYPE_ID, REFERENCE, CRC_METER
    FROM ALL_METER
   WHERE ACTIVE = 1;

CREATE OR REPLACE TRIGGER csr.UTILIY_CONTRACT_BD_TRIGGER
BEFORE DELETE
    ON csr.UTILITY_CONTRACT
    FOR EACH ROW
DECLARE
BEGIN
    DELETE FROM meter_utility_contract
     WHERE utility_contract_id = :OLD.utility_contract_id;
END;
/

begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'METER_UTILITY_CONTRACT',
        policy_name     => 'METER_UTILITY_CONTRACT_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
end;
/

CREATE OR REPLACE FUNCTION csr.utilityContractCheck (
	in_schema IN VARCHAR2, 
	in_object IN VARCHAR2
)
RETURN VARCHAR2
AS
BEGIN
	-- If the user has the "access all contracts" capability then return all rows.
	-- This is useful as contracts may not yet be associated with meters and there 
	-- needs to be a set of users who can see them in order to create the assocations.
	IF csr_data_pkg.CheckCapability('Access all contracts') THEN
		RETURN '';
	END IF;
	
	-- Otherwise base access on contracts associated with meters under the user's region mount point
	RETURN 'utility_contract_id IN (' ||
			'SELECT muc.utility_contract_id ' ||
			  'FROM all_meter am, meter_utility_contract muc ' ||
			 'WHERE muc.region_sid = am.region_sid ' ||
			   'AND am.region_sid IN (' ||
			    'SELECT region_sid ' ||
			      'FROM csr.region ' ||
			        'START WITH region_sid = NVL((' ||
			             'SELECT region_mount_point_sid ' ||
			                'FROM csr.csr_user ' ||
			               'WHERE csr_user_sid = SYS_CONTEXT(''SECURITY'',''SID'') ' ||
			          '),(' ||
			            'SELECT region_root_sid ' ||
			              'FROM csr.customer ' ||
			             'WHERE app_sid = SYS_CONTEXT(''SECURITY'',''APP'') ' ||
			          ')) ' ||
			        'CONNECT BY PRIOR region_sid = parent_sid ' ||
			  ') ' ||
		') ' ||
		'OR SYS_CONTEXT(''SECURITY'',''SID'') = created_by_sid ' ||
		'OR SYS_CONTEXT(''SECURITY'',''SID'') = 3';
end;
/

CREATE OR REPLACE FUNCTION csr.utilityInvoiceCheck (
	in_schema IN VARCHAR2, 
	in_object IN VARCHAR2
)
RETURN VARCHAR2
AS
BEGIN
	-- If the user has the "access all contracts" capability then return all rows.
	-- This is useful as contracts may not yet be associated with meters and there 
	-- needs to be a set of users who can see them in order to create the assocations.
	IF csr_data_pkg.CheckCapability('Access All Contracts') THEN
		RETURN '';
	END IF;
	
	-- Otherwise base access on contracts associated with meters under the user's region mount point
	RETURN 'utility_contract_id IN (' ||
			'SELECT utility_contract_id ' ||
			  'FROM all_meter am, meter_utility_contract muc ' ||
			 'WHERE muc.region_sid = am.region_sid ' ||
			   'AND am.region_sid IN (' ||
			    'SELECT region_sid ' ||
			      'FROM csr.region ' ||
			        'START WITH region_sid = NVL((' ||
			             'SELECT region_mount_point_sid ' ||
			                'FROM csr.csr_user ' ||
			               'WHERE csr_user_sid = SYS_CONTEXT(''SECURITY'',''SID'') ' ||
			          '),(' ||
			            'SELECT region_root_sid ' ||
			              'FROM csr.customer ' ||
			             'WHERE app_sid = SYS_CONTEXT(''SECURITY'',''APP'') ' ||
			          ')) ' ||
			        'CONNECT BY PRIOR region_sid = parent_sid ' ||
			  ') ' ||
		') ' ||
		'OR SYS_CONTEXT(''SECURITY'',''SID'') = 3';
end;
/

@../meter_pkg
@../utility_pkg
@../csr_data_body
@../region_body
@../meter_body
@../utility_body
@../utility_report_body

@update_tail
