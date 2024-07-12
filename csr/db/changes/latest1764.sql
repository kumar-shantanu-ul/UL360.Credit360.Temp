-- Please update version.sql too -- this keeps clean builds in sync
define version=1764
@update_header

-- update security function to handle logged out sessions (needed for 11g dbs to alter tables with defaults)
CREATE OR REPLACE FUNCTION chem.appSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN
	-- Not logged on => see everything.  Needed for update scripts...
	IF SYS_CONTEXT('SECURITY', 'APP') IS NULL THEN
		RETURN '';
	END IF;
	
	-- Only show data if you are logged on and data is for the current application
	RETURN 'app_sid = sys_context(''SECURITY'', ''APP'')';	
END;
/

grant select on csr.sheet_action to chem;

ALTER TABLE CHEM.SUBSTANCE_USE ADD (
	CREATED_DTM TIMESTAMP DEFAULT sys_extract_utc(systimestamp) NOT NULL,
	RETIRED_DTM TIMESTAMP NULL,
	VERS		NUMBER(10)  DEFAULT 1 NOT NULL,
	CHANGED_BY	NUMBER(10) DEFAULT 3 NOT NULL -- built in admin
);

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_constraints
	 where owner='CHEM' and table_name='SUBSTANCE_USE'
	   and constraint_name = 'UK_SUBSTANCE_USE';
	 
	if v_exists = 1 then
		execute immediate 'ALTER TABLE CHEM.SUBSTANCE_USE DROP CONSTRAINT UK_SUBSTANCE_USE';
	end if;
end;
/

ALTER TABLE CHEM.SUBSTANCE_USE ADD CONSTRAINT UK_SUBSTANCE_USE UNIQUE (SUBSTANCE_ID, PROCESS_DESTINATION_ID, REGION_SID, ROOT_DELEGATION_SID, START_DTM, END_DTM, APP_SID, VERS);

ALTER TABLE CHEM.SUBSTANCE_USE MODIFY (
	CHANGED_BY	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'SID')
);

CREATE OR REPLACE VIEW CHEM.V$SUBSTANCE_USE AS
	SELECT su.app_sid, su.substance_use_id, su.substance_id, 
		   su.region_sid, su.process_destination_id, su.root_delegation_sid, 
		   su.mass_value, su.note, su.start_dtm, su.end_dtm, su.entry_std_measure_conv_id, 
		   su.entry_mass_Value, su.created_dtm, su.vers, su.changed_by
	  FROM substance_use su
	  JOIN (
		SELECT substance_use_id, MAX(vers) vers, retired_dtm
		  FROM substance_use
		 GROUP BY substance_use_id, retired_dtm
	  ) suv ON su.substance_use_id = suv.substance_use_id AND su.vers = suv.vers AND suv.retired_dtm IS NULL;

ALTER TABLE CHEM.SUBSTANCE_USE_FILE DROP CONSTRAINT FK_SUBST_USE_SUBST_USE_FILE;
ALTER TABLE CHEM.SUBSTANCE_USE DROP CONSTRAINT PK_SUBSTANCE_USE;

ALTER TABLE CHEM.SUBSTANCE_USE ADD CONSTRAINT PK_SUBSTANCE_USE 
	PRIMARY KEY (APP_SID, SUBSTANCE_USE_ID, SUBSTANCE_ID, REGION_SID, VERS) ENABLE;

ALTER TABLE CHEM.SUBSTANCE_USE_FILE ADD (
	VERS		NUMBER(10)  DEFAULT 1 NOT NULL
);

ALTER TABLE CHEM.SUBSTANCE_USE_FILE ADD CONSTRAINT FK_SUBST_USE_SUBST_USE_FILE 
	FOREIGN KEY (APP_SID, SUBSTANCE_USE_ID, SUBSTANCE_ID, REGION_SID, VERS) REFERENCES CHEM.SUBSTANCE_USE (APP_SID,SUBSTANCE_USE_ID,SUBSTANCE_ID,REGION_SID, VERS);

CREATE OR REPLACE VIEW CHEM.V$OUTPUTS AS
	 SELECT su.app_sid, NVL(cg.label, 'Unknown') cas_group_label, cg.cas_group_id, 
		c.cas_code, c.name,  
		s.ref substance_ref, s.description substance_description,
		sr.waiver_status_id, sr.region_sid, su.start_dtm, su.end_dtm, 
		pd.to_air_pct * su.mass_value * sc.pct_composition air_mass_value,
		pd.to_water_pct * su.mass_value * sc.pct_composition water_mass_value,
		su.mass_value * sc.pct_composition cas_weight,
		pd.to_air_pct,
		pd.to_water_pct,
		pd.to_waste_pct,
		pd.to_product_pct,
		pd.remaining_pct,
		root_delegation_sid
	  FROM v$substance_use su
	  JOIN substance s ON su.substance_id = s.substance_id AND su.app_sid = s.app_sid
	  JOIN substance_region sr ON su.substance_id = sr.substance_id AND su.region_sid = sr.region_sid AND su.app_sid = sr.app_sid
	  LEFT JOIN process_destination pd ON su.process_destination_id = pd.process_destination_id AND su.app_sid = pd.app_sid 
	  JOIN substance_cas sc ON s.substance_id = sc.substance_id
	  JOIN cas c ON sc.cas_code = c.cas_code
	  LEFT JOIN cas_group_member cgm ON c.cas_code = cgm.cas_code 
	  LEFT JOIN cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;
	  
BEGIN
	FOR r IN (
		SELECT DISTINCT host
		  FROM csr.customer
		 WHERE host = 'philips.credit360.com'
	) LOOP
		security.user_pkg.logonadmin(r.host);
		
		csr.sqlreport_pkg.EnableReport('chem.audit_pkg.GetSubLogEntries');
		csr.sqlreport_pkg.EnableReport('chem.audit_pkg.GetAllUsageLogEntries');
		csr.sqlreport_pkg.EnableReport('chem.substance_pkg.GetAuditReport');
	END LOOP;
END;
/

CREATE OR REPLACE VIEW CHEM.V$AUDIT_LOG AS
	 SELECT su.app_sid, NVL(cg.label, 'Unknown') cas_group_label, cg.cas_group_id, 
		c.cas_code, c.name,  
		s.ref substance_ref, s.description substance_description,
		sr.waiver_status_id, sr.region_sid, su.start_dtm, su.end_dtm, 
		pd.to_air_pct * su.mass_value * sc.pct_composition air_mass_value,
		pd.to_water_pct * su.mass_value * sc.pct_composition water_mass_value,
		su.mass_value * sc.pct_composition cas_weight,
		pd.to_air_pct,
		pd.to_water_pct,
		pd.to_waste_pct,
		pd.to_product_pct,
		pd.remaining_pct,
		root_delegation_sid,
		su.changed_by,
		su.created_dtm,
		su.mass_value
	  FROM substance_use su
	  JOIN substance s ON su.substance_id = s.substance_id AND su.app_sid = s.app_sid
	  JOIN substance_region sr ON su.substance_id = sr.substance_id AND su.region_sid = sr.region_sid AND su.app_sid = sr.app_sid
	  LEFT JOIN process_destination pd ON su.process_destination_id = pd.process_destination_id AND su.app_sid = pd.app_sid 
	  JOIN substance_cas sc ON s.substance_id = sc.substance_id
	  JOIN cas c ON sc.cas_code = c.cas_code
	  LEFT JOIN cas_group_member cgm ON c.cas_code = cgm.cas_code 
	  LEFT JOIN cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;

@..\chem\substance_pkg
@..\chem\substance_body

@update_tail