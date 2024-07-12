PROMPT please enter host NAME AND usr (ie: foo.credit360.com, foobar)

--TO DO: check if reference tables already exist and skip


SET echo ON
WHENEVER sqlerror exit failure ROLLBACK 
WHENEVER oserror exit failure ROLLBACK

define host='&&1'
define usr='&&2'

exec SECURITY.user_pkg.logonadmin('&&1');

DECLARE
	v_exists NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_users
	 WHERE username = upper('&&2');
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'create user &&2 identified by &&2 temporary tablespace temp default tablespace users quota unlimited on users';
	END IF;
END;
/

GRANT SELECT ON cms.CONTEXT TO &&2;
GRANT SELECT ON cms.fast_context TO &&2;
GRANT EXECUTE ON cms.tab_pkg TO &&2;
GRANT EXECUTE ON SECURITY.security_pkg TO &&2;

-- Drop relevent tables
DECLARE
	TYPE t_tabs IS TABLE OF VARCHAR2(40);
	v_list t_tabs := t_tabs(

    );
BEGIN
	cms.tab_pkg.enabletrace;
	FOR i IN 1 .. v_list.count 
	loop
		-- USER, table_name, cascade, drop physical
		cms.tab_pkg.droptable(upper('&&2'), v_list(i), TRUE, TRUE);
		NULL;
	END loop;
END;
/

/***************************** REFERENCE DATA TABLES ***************************************/
prompt >> creating REFERENCE DATA TABLES
--These tables are potentially shared.  Therefore, we must check if they exist before dropping and building



DECLARE
	v_exists NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE owner=upper('&&2') AND table_name='CURRENCY_UOM';
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE'
		 	CREATE TABLE &&2..CURRENCY_UOM ('||'
			CURRENCY_UOM_ID		NUMBER(10) NOT NULL,'||'
			LABEL			VARCHAR2(255) NOT NULL,'||'
			FACTOR			NUMBER(24,10) NOT NULL,'||'
			CONSTRAINT PK_CURRENCY_UOM PRIMARY KEY (CURRENCY_UOM_ID)'||'
		)';
	END IF;
END;
/

		COMMENT ON TABLE &&2..currency_uom IS 'desc="Currency UOM"';
		COMMENT ON COLUMN &&2..currency_uom.currency_uom_id IS 'desc="Id",auto';
		COMMENT ON COLUMN &&2..currency_uom.label IS 'desc="Label"';

DECLARE
	v_exists NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE owner=upper('&&2') AND table_name='ENERGY_UOM';
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE'
			CREATE TABLE &&2..ENERGY_UOM ('||'
			ENERGY_UOM_ID		NUMBER(10) NOT NULL,'||'
			LABEL			VARCHAR2(255) NOT NULL,'||'
			FACTOR			NUMBER(24,10) NOT NULL,'||'
			CONSTRAINT PK_ENERGY_UOM PRIMARY KEY (ENERGY_UOM_ID)'||'
		)';
	END IF;
END;
/
		COMMENT ON TABLE &&2..energy_uom IS 'desc="Energy UOM"';
		COMMENT ON COLUMN &&2..energy_uom.energy_uom_id IS 'desc="Id",auto';
		COMMENT ON COLUMN &&2..energy_uom.label IS 'desc="Label"';



/************************** MAIN DATA TABLES ***************************************/
prompt >> creating MAIN DATA TABLES

-- project type
CREATE TABLE &&2..project_type (
	project_type_id		NUMBER(10) NOT NULL,
	label				VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_project_type PRIMARY KEY (project_type_id)
);

COMMENT ON TABLE &&2..project_type IS 'desc="Project Type"';
COMMENT ON COLUMN &&2..project_type.project_type_id IS 'desc="Id",auto';
COMMENT ON COLUMN &&2..project_type.label IS 'desc="Label"';

CREATE TABLE &&2..project_status (
	project_status_id		NUMBER(10) NOT NULL,
	label					VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_project_status PRIMARY KEY (project_status_id)
);

COMMENT ON TABLE &&2..project_status IS 'desc="Project status"';
COMMENT ON COLUMN &&2..project_status.project_status_id IS 'desc="Id",auto';
COMMENT ON COLUMN &&2..project_status.label IS 'desc="Label"';

--project
CREATE TABLE &&2..PROJECT (
	project_id			NUMBER(10) NOT NULL,
	project_type_id		NUMBER(10) NOT NULL,
	description			VARCHAR2(255) NOT NULL,
	energy_savings		NUMBER(24,10) NULL,
	energy_savings_uom	NUMBER(10) NULL,
	energy_savings_kwh	NUMBER(14,2),
	cost				NUMBER(12,2) NULL,
	cost_uom			NUMBER(10) NULL,
	cost_usd			NUMBER(14,2),
	est_impl_dtm		DATE NULL,
	comments			CLOB,
	project_status_id	NUMBER(10),
	app_sid				NUMBER(10) DEFAULT sys_context('SECURITY','APP') NOT NULL,
	root_delegation_sid	NUMBER(10) NOT NULL,
	region_sid			NUMBER(10) NOT NULL,
	start_dtm			DATE NOT NULL,
	end_dtm				DATE NOT NULL,
	CONSTRAINT pk_project PRIMARY KEY (project_id)
);

COMMENT ON TABLE &&2..PROJECT IS 'desc="Energy Saving &&2..Projects"';
COMMENT ON COLUMN &&2..PROJECT.project_id IS 'desc="Id",auto';
COMMENT ON COLUMN &&2..PROJECT.project_type_id IS 'desc="Project type",enum,enum_desc_col=label';
COMMENT ON COLUMN &&2..PROJECT.description IS 'desc="Project title/description"';
COMMENT ON COLUMN &&2..PROJECT.energy_savings IS 'desc="Estimated energy savings"';
COMMENT ON COLUMN &&2..PROJECT.energy_savings_uom IS 'desc="Estimated energy savings - units",enum,enum_desc_col=label';
COMMENT ON COLUMN &&2..PROJECT.energy_savings_kwh IS 'desc="Estimated energy savings - USD"';
COMMENT ON COLUMN &&2..PROJECT.cost IS 'desc="Cost"';
COMMENT ON COLUMN &&2..PROJECT.cost_uom IS 'desc="Cost - units",enum,enum_desc_col=label';
COMMENT ON COLUMN &&2..PROJECT.cost_usd IS 'desc="Cost - USD"';
COMMENT ON COLUMN &&2..PROJECT.est_impl_dtm IS 'desc="Estimated implementation date or completion date"';
COMMENT ON COLUMN &&2..PROJECT.comments IS 'desc="Additional comments"';
COMMENT ON COLUMN &&2..PROJECT.project_status_id IS 'desc="Project status",enum,enum_desc_col=label,enum_pos_col=project_status_id';
COMMENT ON COLUMN &&2..PROJECT.app_sid IS 'app';
COMMENT ON COLUMN &&2..PROJECT.region_sid IS 'desc="Regions",region';
COMMENT ON COLUMN &&2..PROJECT.start_dtm IS 'desc="Period start"';
COMMENT ON COLUMN &&2..PROJECT.end_dtm IS 'desc="Period end"';

ALTER TABLE &&2..PROJECT ADD CONSTRAINT fk_proj_proj_type
    FOREIGN KEY (project_type_id)
    REFERENCES &&2..project_type(project_type_id);

ALTER TABLE &&2..PROJECT ADD CONSTRAINT fk_project_currency_uom
    FOREIGN KEY (cost_uom)
    REFERENCES &&2..currency_uom(currency_uom_id);

ALTER TABLE &&2..PROJECT ADD CONSTRAINT fk_project_energy_uom
    FOREIGN KEY (energy_savings_uom)
    REFERENCES &&2..energy_uom(energy_uom_id);

ALTER TABLE &&2..PROJECT ADD CONSTRAINT fk_project_status
    FOREIGN KEY (project_status_id)
    REFERENCES &&2..project_status(project_status_id);


spool registertables.LOG

BEGIN
    dbms_output.ENABLE(NULL); 
    SECURITY.user_pkg.logonadmin('&&1');
	cms.tab_pkg.enabletrace;
	cms.tab_pkg.allowtable('CSR', 'REGION');
    cms.tab_pkg.registertable(upper('&&2'), 'PROJECT', TRUE);
	cms.tab_pkg.registertable(upper('&&2'), 'CURRENCY_UOM,ENERGY_UOM, PROJECT_TYPE, PROJECT_STATUS', FALSE);    
END;
/

spool OFF   

/************************** POPULATE BASEDATA ***************************************/
prompt >> Adding basedata

BEGIN
	INSERT INTO &&usr..currency_uom (currency_uom_id, label, factor)
	SELECT 1, 'Dollars (USD)', 1
	  FROM dual
	 UNION 
	SELECT measure_conversion_id,  description, nvl(A,1) -- TODO: fix!!
	  FROM csr.measure_conversion
	 WHERE measure_sid = (
		SELECT measure_sid
		  FROM csr.measure
		 WHERE app_sid = SECURITY.security_pkg.getapp
		   AND description = 'Dollars (USD)'
		)
	 MINUS 
	SELECT currency_uom_id, label, factor
	  FROM &&usr..currency_uom;
END;
/

BEGIN
	INSERT INTO &&usr..energy_uom (energy_uom_id, label, factor)
	SELECT 1, 'kWh', 1
	  FROM dual
	 UNION 
	SELECT measure_conversion_id,  description, A
	  FROM csr.measure_conversion
	 WHERE measure_sid = (
		SELECT measure_sid
		  FROM csr.measure
		 WHERE app_sid = SECURITY.security_pkg.getapp
		   AND description = 'kWh'
		);
END;
/


BEGIN
	INSERT INTO &&usr..project_type (project_type_id, label) VALUES (1, 'Capital Project');
	INSERT INTO &&usr..project_type (project_type_id, label) VALUES (2, 'Other Project');
END;
/

BEGIN
	INSERT INTO &&usr..project_status (project_status_id, label) VALUES (1, 'Completed');
	INSERT INTO &&usr..project_status (project_status_id, label) VALUES (2, 'Proposed');
END;
/

 /************************** GRANTS ***************************************/
prompt >> GRANT permissions FOR csr

--GRANT SELECT, REFERENCES ON &&2..PROJECT TO csr;
--GRANT SELECT, REFERENCES ON &&2..project_type TO csr;


 /************************** GRID INDICATORS ***************************************/
prompt >> creating grid indicators

BEGIN
	SECURITY.user_pkg.logonadmin('&&1');
	csr.delegation_pkg.creategridindicator('PROJECT', 'Energy Saving Projects', '/csr/forms/project_grid.xml', NULL);
END;
/ 

/************************** CREATE TRIGGERS ***************************************/
prompt >> creating TRIGGERS

CREATE OR REPLACE TRIGGER &&2..project_bi BEFORE INSERT OR UPDATE ON &&2..c$project FOR EACH ROW
BEGIN
	:NEW.energy_savings_kwh :=
			CASE
				WHEN nvl(:NEW.energy_savings_uom,1) = 1 THEN :NEW.energy_savings
				ELSE csr.measure_pkg.unsec_getbasevalue(:NEW.energy_savings, :NEW.energy_savings_uom, :NEW.start_dtm)
			END;

	:NEW.cost_usd :=
			CASE
				WHEN nvl(:NEW.cost_uom,1) = 1 THEN :NEW.COST
				ELSE csr.measure_pkg.unsec_getbasevalue(:NEW.COST, :NEW.cost_uom, :NEW.start_dtm)
			END;
END;
/


/************************** CREATE AGGREGATE INDICATORS ***************************************/
prompt >> creating aggregate indicators

--Indicators and Measures
DECLARE
	v_energy_measure_sid 	SECURITY.security_pkg.t_sid_id;
	v_currency_measure_sid	SECURITY.security_pkg.t_sid_id;
	v_ind_root_sid			SECURITY.security_pkg.t_sid_id;
	v_parent_sid			SECURITY.security_pkg.t_sid_id;
	v_table_ind_sid			SECURITY.security_pkg.t_sid_id;
BEGIN
	SECURITY.user_pkg.logonadmin('&&1');

	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM csr.customer
	 WHERE app_sid = SECURITY.security_pkg.getapp;

 	--Check for measures and create if necessary
 	BEGIN
		SELECT measure_sid
		  INTO v_currency_measure_sid
		  FROM csr.measure
		 WHERE UPPER(NAME)='USD'
		 AND APP_SID = SECURITY.security_pkg.getapp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.measure_pkg.createmeasure(
				in_name							=> 'USD',
				in_description					=> 'USD',
				in_std_measure_conversion_id 	=> 1,
				out_measure_sid					=> v_currency_measure_sid
			);
	END;
		
	BEGIN
		SELECT measure_sid
		  INTO v_energy_measure_sid
		  FROM csr.measure
		 WHERE UPPER(NAME)='KWH'
		 AND APP_SID = SECURITY.security_pkg.getapp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.measure_pkg.createmeasure(
				in_name							=> 'KWH',
				in_description					=> 'KWH',
				in_std_measure_conversion_id 	=> 8,
				out_measure_sid					=> v_energy_measure_sid
			);
	END;

	-- Create folder structure (root, table)
	BEGIN
		SELECT ind_sid
		  INTO v_parent_sid
		  FROM csr.ind
		 WHERE lookup_key = 'FORMS_ROOT';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.indicator_pkg.createindicator(
				in_name				=> 'FORMS_ROOT',
				in_description		=> 'Form Indicators',
				in_lookup_key		=> 'FORMS_ROOT',
				in_parent_sid_id	=> v_ind_root_sid,
				out_sid_id			=> v_parent_sid
			);
	END;

	--Create Mapped Inds
	BEGIN
		SELECT ind_sid
		  INTO v_table_ind_sid
		  FROM csr.ind
		 WHERE lookup_key = 'CAPITAL_PROJECT_SAVINGS';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.indicator_pkg.createindicator(
				in_name				=> 'CAPITAL_PROJECT_SAVINGS',
				in_description		=> 'Capital Project Savings',
				in_lookup_key		=> 'CAPITAL_PROJECT_SAVINGS',
				in_parent_sid_id	=> v_parent_sid,
				in_measure_sid      => v_energy_measure_sid,
				out_sid_id			=> v_table_ind_sid
			);
	END;	

	BEGIN
		SELECT ind_sid
		  INTO v_table_ind_sid
		  FROM csr.ind
		 WHERE lookup_key = 'OTHER_PROJECT_SAVINGS';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.indicator_pkg.createindicator(
				in_name				=> 'OTHER_PROJECT_SAVINGS',
				in_description		=> 'Other Project Savings',
				in_lookup_key		=> 'OTHER_PROJECT_SAVINGS',
				in_parent_sid_id	=> v_parent_sid,
				in_measure_sid      => v_energy_measure_sid,
				out_sid_id			=> v_table_ind_sid
			);
	END;	

	BEGIN
		SELECT ind_sid
		  INTO v_table_ind_sid
		  FROM csr.ind
		 WHERE lookup_key = 'CAPITAL_PROJECT_COSTS';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.indicator_pkg.createindicator(
				in_name				=> 'CAPITAL_PROJECT_COSTS',
				in_description		=> 'Capital Project Costs',
				in_lookup_key		=> 'CAPITAL_PROJECT_COSTS',
				in_parent_sid_id	=> v_parent_sid,
				in_measure_sid      => v_currency_measure_sid,
				out_sid_id			=> v_table_ind_sid
			);
	END;	

	BEGIN
		SELECT ind_sid
		  INTO v_table_ind_sid
		  FROM csr.ind
		 WHERE lookup_key = 'OTHER_PROJECT_COSTS';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.indicator_pkg.createindicator(
				in_name				=> 'OTHER_PROJECT_COSTS',
				in_description		=> 'Other Project Costs',
				in_lookup_key		=> 'OTHER_PROJECT_COSTS',
				in_parent_sid_id	=> v_parent_sid,
				in_measure_sid      => v_currency_measure_sid,
				out_sid_id			=> v_table_ind_sid
			);
	END;
END;
/

/************************** MAP AGGREGATE INDICATORS ***************************************/
prompt >> MAPPING aggregate indicators

DECLARE
    v_aggregate_xml     VARCHAR2(10000);
    v_ind_sid           csr.ind.ind_sid%TYPE;
BEGIN
    
    SECURITY.user_pkg.logonadmin('&&1');
    
    v_aggregate_xml := '<aggregates xmlns="http://www.credit360.com/XMLSchemas/cms">
    <aggregate type="view">
        <select>
            <tables>                               
                <table name="'||upper('&&2')||'.PROJECT"/>     
            </tables>
            <columns>
                <calc-column name = "PROJECT_COST_USD">
                    <expr>
                        <sum>                              
                            <expr>
                                <column name = "PROJECT.COST_USD"/> 
                            </expr>  
                            <partition>
                                <column name = "PROJECT.PROJECT_TYPE_ID"/>           
                            </partition>                        
                        </sum>
                    </expr>
                </calc-column> 
                <calc-column name = "PROJECT_SAVINGS_KWH">
                    <expr>
                        <sum>                              
                            <expr>
                                <column name = "PROJECT.ENERGY_SAVINGS_KWH"/> 
                            </expr>  
                            <partition>
                                <column name = "PROJECT.PROJECT_TYPE_ID"/>      
                            </partition>                        
                        </sum>
                    </expr>
                </calc-column>  
                <column name = "PROJECT.PROJECT_TYPE_ID"/> 
            </columns>         
          </select>
          <map>
              <column name = "PROJECT_SAVINGS_KWH">
                <choose>                                       
                    <when test = "PROJECT_TYPE_ID = 1"><indicator lookup-key = "CAPITAL_PROJECT_SAVINGS"/></when> 
                    <when test = "PROJECT_TYPE_ID = 2"><indicator lookup-key = "OTHER_PROJECT_SAVINGS"/></when>    
                </choose>
              </column>   
              <column name = "PROJECT_COST_USD">
                <choose>                                       
                    <when test = "PROJECT_TYPE_ID = 1"><indicator lookup-key = "CAPITAL_PROJECT_COSTS"/></when> 
                    <when test = "PROJECT_TYPE_ID = 2"><indicator lookup-key = "OTHER_PROJECT_COSTS"/></when>        
                </choose>
              </column>                
        </map>   
    </aggregate>
</aggregates>';

    SELECT ind_sid INTO v_ind_sid
      FROM csr.delegation_grid 
     WHERE path = '/csr/forms/project_grid.xml' AND app_sid = SECURITY.security_pkg.getapp;
     
     csr.delegation_pkg.setgridindaggregationxml(v_ind_sid, v_aggregate_xml);
END;
/


/************************** MENU ***************************************/
prompt >> ADD menu items

DECLARE
	v_app_sid				SECURITY.security_pkg.t_sid_id; 
	v_act_id				SECURITY.security_pkg.t_act_id;
	v_www_sid				SECURITY.security_pkg.t_sid_id;
	v_forms					SECURITY.security_pkg.t_sid_id;
	v_registeredusers_sid	SECURITY.security_pkg.t_sid_id;
	v_administrators_sid	SECURITY.security_pkg.t_sid_id;
	v_root_analysis_sid		SECURITY.security_pkg.t_sid_id;
	v_project_table_sid		SECURITY.security_pkg.t_sid_id;
BEGIN 
	SECURITY.user_pkg.logonadmin('&&1');
	
	v_app_sid := SECURITY.security_pkg.getapp;
	v_act_id := SECURITY.security_pkg.getact;
	v_www_sid := SECURITY.securableobject_pkg.getsidfrompath(v_act_id, v_app_sid, 'wwwroot');
	v_registeredusers_sid := SECURITY.securableobject_pkg.getsidfrompath(v_act_id, SECURITY.security_pkg.getapp, 'groups/RegisteredUsers');
	v_administrators_sid := SECURITY.securableobject_pkg.getsidfrompath(v_act_id, SECURITY.security_pkg.getapp, 'groups/Administrators');
	v_root_analysis_sid := SECURITY.securableobject_pkg.getsidfrompath(v_act_id, SECURITY.security_pkg.getapp, 'menu/Analysis');
	v_project_table_sid := SECURITY.securableobject_pkg.getsidfrompath(v_act_id, SECURITY.security_pkg.getapp, 'cms/"&&2"."PROJECT"');
	
--Add resource to display form
		BEGIN
			SECURITY.web_pkg.createresource(SECURITY.security_pkg.getact, v_www_sid, 
				SECURITY.securableobject_pkg.getsidfrompath(SECURITY.security_pkg.getact, v_www_sid,'csr'), 'forms', v_forms);
			SECURITY.acl_pkg.addace(SECURITY.security_pkg.getact, SECURITY.acl_pkg.getdaclidforsid(v_forms), -1, SECURITY.security_pkg.ace_type_allow, SECURITY.security_pkg.ace_flag_default, 
				v_registeredusers_sid, SECURITY.security_pkg.permission_standard_read);
		exception
			WHEN SECURITY.security_pkg.duplicate_object_name THEN
				v_forms := SECURITY.securableobject_pkg.getsidfrompath(SECURITY.security_pkg.getact, v_www_sid,'csr/forms');
		END;		

--Add menu item for pivot
		BEGIN
			SECURITY.menu_pkg.createmenu(v_act_id, v_root_analysis_sid, 'csr_pivot_projects', 'Pivot Projects', '/fp/cms/analysis/pivot.acds?tabSid='||v_project_table_sid, -1, NULL, v_root_analysis_sid);
			SECURITY.acl_pkg.addace(v_act_id, SECURITY.acl_pkg.getdaclidforsid(v_root_analysis_sid), -1, SECURITY.security_pkg.ace_type_allow, 0, v_administrators_sid, SECURITY.security_pkg.permission_standard_read);
		exception
			WHEN SECURITY.security_pkg.duplicate_object_name THEN
			NULL;
		END;
END;
/


COMMIT;
 
exit


