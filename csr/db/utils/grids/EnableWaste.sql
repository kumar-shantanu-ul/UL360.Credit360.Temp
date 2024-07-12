PROMPT Please enter host name and usr (ie: foo.credit360.com, FOOBAR)

--TO DO: check if reference tables already exist and skip


set echo on
whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

define host='&&1'
define usr='&&2'

exec security.user_pkg.logonadmin('&&1');

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_users
	 where username = UPPER('&&2');
	if v_exists = 0 then
		execute immediate 'create user &&2 identified by &&2 temporary tablespace temp default tablespace users quota unlimited on users';
	end if;
end;
/

grant select on cms.context to &&2;
grant select on cms.fast_context to &&2;
grant execute on cms.tab_pkg to &&2;
grant execute on security.security_pkg to &&2;

-- Drop relevent tables
DECLARE
	TYPE t_tabs IS TABLE OF VARCHAR2(40);
	v_list t_tabs := t_tabs(

    );
BEGIN
	cms.tab_pkg.enabletrace;
	FOR i IN 1 .. v_list.count 
	LOOP
		-- USER, table_name, cascade, drop physical
		cms.tab_pkg.DropTable(UPPER('&&2'), v_list(i), true, true);
		null;
	END LOOP;
END;
/

/***************************** REFERENCE DATA TABLES ***************************************/
PROMPT >> Creating REFERENCE DATA tables
--These tables are potentially shared.  Therefore, we must check if they exist before dropping and building

CREATE TABLE &&2..QUANTITY_UOM (
	 QUANTITY_UOM_ID	NUMBER(10) NOT NULL,
	 LABEL			VARCHAR2(255) NOT NULL,
	 POS     NUMBER(10) DEFAULT 0 NOT NULL,
	 CONSTRAINT PK_QUANTITY_UOM PRIMARY KEY (QUANTITY_UOM_ID)
 );
	COMMENT ON TABLE &&2..QUANTITY_UOM IS 'desc="Quantity UOMs"';
	COMMENT ON COLUMN &&2..QUANTITY_UOM.QUANTITY_UOM_ID IS 'desc="Id"';
	COMMENT ON COLUMN &&2..QUANTITY_UOM.LABEL IS 'desc="Label"';

BEGIN
    INSERT INTO &&2..QUANTITY_UOM (QUANTITY_UOM_ID, LABEL) VALUES (1 , 'Kgs');
    INSERT INTO &&2..QUANTITY_UOM (QUANTITY_UOM_ID, LABEL) VALUES (2 , 'm3');
    INSERT INTO &&2..QUANTITY_UOM (QUANTITY_UOM_ID, LABEL) VALUES (3 , 'Tonnes');
    INSERT INTO &&2..QUANTITY_UOM (QUANTITY_UOM_ID, LABEL) VALUES (4 , 'Bags');
    INSERT INTO &&2..QUANTITY_UOM (QUANTITY_UOM_ID, LABEL) VALUES (5 , 'Litres');
END;
/


/************************** MAIN DATA TABLES ***************************************/
PROMPT >> CREATING MAIN DATA TABLES

/***** HAZARD TYPE *****/
CREATE TABLE &&2..HAZARD_TYPE (
	HAZARD_TYPE_ID	NUMBER(10) NOT NULL,
	LABEL			VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_HAZARD_TYPE PRIMARY KEY (HAZARD_TYPE_ID)
);
COMMENT ON TABLE &&2..HAZARD_TYPE IS 'desc="Hazardous"';
COMMENT ON COLUMN &&2..HAZARD_TYPE.HAZARD_TYPE_ID IS 'desc="Id"';
COMMENT ON COLUMN &&2..HAZARD_TYPE.LABEL IS 'desc="Label"';

BEGIN
    INSERT INTO &&2..HAZARD_TYPE (HAZARD_TYPE_ID, LABEL) VALUES (0 , 'Non Hazardous Waste');
    INSERT INTO &&2..HAZARD_TYPE (HAZARD_TYPE_ID, LABEL) VALUES (1 , 'Hazardous Waste');
    INSERT INTO &&2..HAZARD_TYPE (HAZARD_TYPE_ID, LABEL) VALUES (2 , 'TBC');
END;
/

/***** EWC CODES *****/
CREATE TABLE &&2..EWC_CODE (
	EWC_CODE		NUMBER(10) NOT NULL,
	DESCRIPTION		VARCHAR2(255) NOT NULL,
	CONSTRAINT		PK_EWC_CODE PRIMARY KEY (EWC_CODE)
);
COMMENT ON TABLE &&2..EWC_CODE IS 'desc="EWC codes"';
COMMENT ON COLUMN &&2..EWC_CODE.EWC_CODE IS 'desc="EWC code"';
COMMENT ON COLUMN &&2..EWC_CODE.DESCRIPTION IS 'desc="Description"';

-- to do, add EWC source data AND LINK IN TO WASTE TYPE

/***** WASTE TYPE *****/
CREATE TABLE &&2..WASTE_TYPE (
	WASTE_TYPE_ID		NUMBER(10) NOT NULL,
	DESCRIPTION			VARCHAR2(255) NOT NULL,
	EWC_CODE			VARCHAR(64) NOT NULL,
	GUIDANCE			NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT PK_WASTE_TYPE PRIMARY KEY (WASTE_TYPE_ID)
);
COMMENT ON TABLE &&2..WASTE_TYPE IS 'desc="Waste type"';
COMMENT ON COLUMN &&2..WASTE_TYPE.WASTE_TYPE_ID IS 'desc="Id",auto';
COMMENT ON COLUMN &&2..WASTE_TYPE.DESCRIPTION IS 'desc="Description"';
COMMENT ON COLUMN &&2..WASTE_TYPE.EWC_CODE IS 'desc="EWC Code"';
COMMENT ON COLUMN &&2..WASTE_TYPE.GUIDANCE IS 'desc="Included in the 2010 guidance for CSR reporting?",boolean';

BEGIN
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (1, '1. Office - Routine Waste: Glass - Mixed', '20 01 02', 1);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (2, '1. Office - Routine Waste: Recyclable Mixed Municiple Waste', '20 03 01', 1);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (3, '1. Office - Routine Waste: Residual Mixed Municiple Waste', '20 03 01', 1);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (4, '1. Office - Routine Waste: Sanitary Waste (personal hygiene)', '18 01 04', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (5, '2. Office - Non-routine Waste: Aerosol Cans - Empty', '15 01 10*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (6, '2. Office - Non-routine Waste: Batteries (Alkaline, Lithium, Metal hydride)', '20 01 34', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (7, '2. Office - Non-routine Waste: Batteries (mixed or NiCad)', '20 01 33*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (8, '2. Office - Non-routine Waste: Confidential Waste Paper', '20 01 01', 1);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (9, '2. Office - Non-routine Waste: Hard hats', 'tbc', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (10, '2. Office - Non-routine Waste: Healthcare waste (non infectious)', '18 01 04', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (11, '2. Office - Non-routine Waste: Sharps (clinical / health care)', '18 01 01', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (12, '2. Office - Non-routine Waste: Site clothing - not contaminated', '15 02 03', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (13, '2. Office - Non-routine Waste: Spent Activated Carbon filter - Model Shop waste BH', '06 13 02*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (14, '2. Office - Non-routine Waste: Toner and Printer Cartridges - Empty', '08 03 18', 1);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (15, '3. Office - IT Waste: Keyboards, mice and cables', '16 02 14', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (16, '3. Office - IT Waste: Mobile phones', '20 01 35* 20 01 36', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (17, '3. Office - IT Waste: PC''s, laptops or server parts', '16 02 14', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (18, '3. Office - IT Waste: Printers / faxes', '16 02 14', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (19, '3. Office - IT Waste: Screens (Cathode Ray Tube)', '16 02 13*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (20, '3. Office - IT Waste: Screens (LCD / Plasma)', '16 02 13*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (21, '3. Office - IT Waste: UPS''s ', '20 01 33*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (22, '3. Office - IT Waste: Waste Electrical and Electronic Equipment (WEEE) - Other Equipment', '20 01 35*  or 20 01 36 0r 16 02 14', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (23, '3. Office - IT Waste: discarded equipment containing chlorofluorocarbons HCFC HFC', '16 02 11*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (24, '4. Facilities - maintenance, office churn: Asbestos containing construction materials', '17 06 05*',0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (25, '4. Facilities - maintenance, office churn: Cooking oil - Used', '20 01 25', 1);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (26, '4. Facilities - maintenance, office churn: Engine, Gearbox and  Hydraulic Oil (mixed)', '13 08 99*    ', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (27, '4. Facilities - maintenance, office churn: Fire Extinguishers', '16 05 05', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (28, '4. Facilities - maintenance, office churn: Fluorescent Lights/ Halogen Bulbs', '20 01 21*', 1);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (29, '4. Facilities - maintenance, office churn: Furniture (bulky waste)', '20 03 07', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (30, '4. Facilities - maintenance, office churn: Interceptor sludge', '13 05 03*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (31, '4. Facilities - maintenance, office churn: Lead Acid Batteries', '16 06 01*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (32, '4. Facilities - maintenance, office churn: Mixed commercial waste', '20 03 01', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (33, '4. Facilities - maintenance, office churn: Oil Filters (From plant and equipment) (the majority of oil to be drained from the filter beforehand )', '15 02 02*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (34, '4. Facilities - maintenance, office churn: Oil/ Grease contaminated Waste (absorbents, filter materials, wiping cloths, protective clothing) ', '15 02 02*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (35, '4. Facilities - maintenance, office churn: Packaging (Contaminated with hazardous residues) (empty Grease Cartridges)', '15 01 10*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (36, '4. Facilities - maintenance, office churn: Refrigerant - chlorofluorocarbons, HCFC, HFC', '14 06 01*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (37, '4. Facilities - maintenance, office churn: Scrap (Mixed) Metals ', '17 04 07 (If C and D or) 20 01 40', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (38, '4. Facilities - maintenance, office churn: Toilet Waste / Foul drain unblocking Sewage', '20 03 04', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (39, '4. Facilities - maintenance, office churn: Waste Fuel oil and diesel', '13 07 01*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (40, '4. Facilities - maintenance, office churn: Waste Resins and Adhesives (containing dangerous substances)', '20 01 27*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (41, '4. Facilities - maintenance, office churn: Waste Tins / Drummed Paints / unused (organic) products (containing dangerous substances)', '08 01 11* 16 03 05*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (42, '4. Facilities - maintenance, office churn: White Goods - dishwasher / cooker', '20 01 36', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (43, '4. Facilities - maintenance, office churn: White Goods - Fridges ', '16 02 11*', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (44, '4. Facilities - maintenance, office churn: Wood  Complete wooden pallets /', '15 01 03', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (45, '4. Facilities - maintenance, office churn:  Wood joinery offcuts / plywood / broken pallets', '17 02 01', 0);
INSERT INTO &&2..waste_type (waste_type_id, description, ewc_code, guidance) VALUES (46, '5. Contractor Waste (Refurbs): Mixed Construction / Demolition  Waste', '17 09 04', 0);
END;
/

/***** Data quality *****/
CREATE TABLE &&2..DATA_QUALITY (
	DATA_QUALITY_ID	NUMBER(10) NOT NULL,
	LABEL			VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_DATA_QUALITY PRIMARY KEY (DATA_QUALITY_ID)
);
COMMENT ON TABLE &&2..DATA_QUALITY IS 'desc="Data quality"';
COMMENT ON COLUMN &&2..DATA_QUALITY.DATA_QUALITY_ID IS 'desc="Id"';
COMMENT ON COLUMN &&2..DATA_QUALITY.LABEL IS 'desc="Label"';

BEGIN
    INSERT INTO &&2..DATA_QUALITY (DATA_QUALITY_ID, LABEL) VALUES (1 , 'Actual');
    INSERT INTO &&2..DATA_QUALITY (DATA_QUALITY_ID, LABEL) VALUES (2 , 'Calculated estimate');
    INSERT INTO &&2..DATA_QUALITY (DATA_QUALITY_ID, LABEL) VALUES (3 , 'Guesstimate');
END;
/

/***** Treatment method *****/
CREATE TABLE &&2..TREATMENT_METHOD (
	TREATMENT_METHOD_ID	NUMBER(10) NOT NULL,
	LABEL					VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_TREATMENT_METHOD PRIMARY KEY (TREATMENT_METHOD_ID)
);
COMMENT ON TABLE &&2..TREATMENT_METHOD IS 'desc="Waste treatment method"';
COMMENT ON COLUMN &&2..TREATMENT_METHOD.TREATMENT_METHOD_ID IS 'desc="Id"';
COMMENT ON COLUMN &&2..TREATMENT_METHOD.LABEL IS 'desc="Label"';

BEGIN
    INSERT INTO &&2..TREATMENT_METHOD (TREATMENT_METHOD_ID, LABEL) VALUES (1 , 'Reused');
    INSERT INTO &&2..TREATMENT_METHOD (TREATMENT_METHOD_ID, LABEL) VALUES (2 , 'Recycled');
    INSERT INTO &&2..TREATMENT_METHOD (TREATMENT_METHOD_ID, LABEL) VALUES (3 , 'Energy from waste');
    INSERT INTO &&2..TREATMENT_METHOD (TREATMENT_METHOD_ID, LABEL) VALUES (4 , 'Landfill');
    INSERT INTO &&2..TREATMENT_METHOD (TREATMENT_METHOD_ID, LABEL) VALUES (5 , 'Composted');
    INSERT INTO &&2..TREATMENT_METHOD (TREATMENT_METHOD_ID, LABEL) VALUES (6 , 'Incineration (without energy recovery)');
END;
/

/***** WASTE *****/
CREATE TABLE &&2..WASTE (
    WASTE_ID				NUMBER(10) NOT NULL,
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ROOT_DELEGATION_SID		NUMBER(10) NOT NULL,
	REGION_SID				NUMBER(10) NOT NULL,
	START_DTM				DATE NOT NULL,
	END_DTM					DATE NOT NULL,
	COLLECTION_START_DTM	DATE NOT NULL,
	COLLECTION_END_DTM		DATE NULL,
    COLLECTION_DATE			DATE NULL,
    WASTE_TYPE_ID			NUMBER(10) NOT NULL,
    HAZARD_TYPE_ID			NUMBER(10) NOT NULL,
    GUIDANCE				NUMBER(1),
    QUANTITY				NUMBER(10,2) NOT NULL,
    QUANTITY_UOM_ID			NUMBER(10) NOT NULL,
    DATA_QUALITY_ID			NUMBER(10) NOT NULL,
    TREATMENT_METHOD_ID		NUMBER(10) NOT NULL,
    ID_REF					VARCHAR2(255),
    COMMENTS				CLOB,
    CONSTRAINT PK_WASTE PRIMARY KEY (WASTE_ID)
);

COMMENT ON TABLE &&2..WASTE IS 'desc="Waste"';
COMMENT ON COLUMN &&2..WASTE.WASTE_ID IS 'desc="ID",auto';
COMMENT ON COLUMN &&2..WASTE.APP_SID IS 'app';
COMMENT ON COLUMN &&2..WASTE.REGION_SID IS 'desc="Regions",region';
COMMENT ON COLUMN &&2..WASTE.COLLECTION_START_DTM IS 'desc="Collection start date"';
COMMENT ON COLUMN &&2..WASTE.COLLECTION_END_DTM IS 'desc="Collection end date"';
COMMENT ON COLUMN &&2..WASTE.COLLECTION_DATE IS 'desc="Date of collection"';
COMMENT ON COLUMN &&2..WASTE.WASTE_TYPE_ID IS 'desc="Waste type",enum,enum_desc_col=description,enum_pos_col=waste_type_id';
COMMENT ON COLUMN &&2..WASTE.HAZARD_TYPE_ID IS 'desc="Hazardous or Non-hazardous",enum,enum_desc_col=label,enum_pos_col=HAZARD_TYPE_ID';
COMMENT ON COLUMN &&2..WASTE.GUIDANCE IS 'desc="Included in the 2010 guidance for CSR reporting?",bool';
COMMENT ON COLUMN &&2..WASTE.QUANTITY IS 'desc="Quantity"';
COMMENT ON COLUMN &&2..WASTE.QUANTITY_UOM_ID IS 'desc="Units of measure",enum,enum_desc_col=label,enum_pos_col=quantity_uom_id';
COMMENT ON COLUMN &&2..WASTE.DATA_QUALITY_ID IS 'desc="Data quality",enum,enum_desc_col=label,enum_pos_col=data_quality_id';
COMMENT ON COLUMN &&2..WASTE.TREATMENT_METHOD_ID IS 'desc="Waste treatment method",enum,enum_desc_col=label,enum_pos_col=treatment_method_id';
COMMENT ON COLUMN &&2..WASTE.ID_REF IS 'desc="Waste shipping number / invoice number / help desk number"';
COMMENT ON COLUMN &&2..WASTE.COMMENTS IS 'desc="Comments"';

ALTER TABLE &&2..WASTE ADD CONSTRAINT FK_WASTE_QUANTITY_UOM_ID
    FOREIGN KEY (QUANTITY_UOM_ID)
    REFERENCES &&2..QUANTITY_UOM(QUANTITY_UOM_ID);

ALTER TABLE &&2..WASTE ADD CONSTRAINT FK_WASTE_TYPE_ID
    FOREIGN KEY (WASTE_TYPE_ID)
    REFERENCES &&2..WASTE_TYPE(WASTE_TYPE_ID);
    
ALTER TABLE &&2..WASTE ADD CONSTRAINT FK_WASTE_HAZARD
    FOREIGN KEY (HAZARD_TYPE_ID)
    REFERENCES &&2..HAZARD_TYPE(HAZARD_TYPE_ID);
    
ALTER TABLE &&2..WASTE ADD CONSTRAINT FK_DATA_QUALITY_ID
    FOREIGN KEY (DATA_QUALITY_ID)
    REFERENCES &&2..DATA_QUALITY(DATA_QUALITY_ID);

ALTER TABLE &&2..WASTE ADD CONSTRAINT FK_TREATMENT_METHOD_ID
    FOREIGN KEY (TREATMENT_METHOD_ID)
    REFERENCES &&2..TREATMENT_METHOD(TREATMENT_METHOD_ID);

/***** WASTE DOC *****/
CREATE TABLE &&2..WASTE_DOC(
    WASTE_DOC_ID	NUMBER(10, 0)    NOT NULL,
    DOC_FILE		BLOB             NOT NULL,
    DOC_MIME		VARCHAR2(100)    NOT NULL,
    DOC_NAME		VARCHAR2(100)    NOT NULL,
    WASTE_ID		NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_WASTE_DOC PRIMARY KEY (WASTE_DOC_ID)
)
;

COMMENT ON TABLE &&2..WASTE_DOC IS 'desc="Waste transfer documentation"';
COMMENT ON COLUMN &&2..WASTE_DOC.WASTE_DOC_ID IS 'desc="Id",auto';
COMMENT ON COLUMN &&2..WASTE_DOC.DOC_FILE IS 'desc="Document",file,file_mime=doc_mime,file_name=doc_name';
COMMENT ON COLUMN &&2..WASTE_DOC.WASTE_ID IS 'desc="Waste record ID"';

ALTER TABLE &&2..WASTE_DOC ADD CONSTRAINT FK_WASTE_WASTE_DOC 
    FOREIGN KEY (WASTE_ID)
    REFERENCES &&2..WASTE(WASTE_ID)
;

spool registerTables.log

BEGIN
    dbms_output.enable(NULL); 
    security.user_pkg.LogonAdmin('&&1');
	cms.tab_pkg.enabletrace;
	cms.tab_pkg.allowTable('CSR', 'REGION');
    cms.tab_pkg.registertable(UPPER('&&2'), 'WASTE', TRUE);
	cms.tab_pkg.registertable(UPPER('&&2'), 'QUANTITY_UOM, HAZARD_TYPE, WASTE_TYPE', FALSE);    
END;
/

spool off   


 /************************** GRID INDICATORS ***************************************/
PROMPT >> CREATING GRID INDICATORS

BEGIN
	security.user_pkg.LogonAdmin('&&1');
	csr.delegation_pkg.CreateGridIndicator('WASTE', 'Waste', '/csr/forms/waste_grid.xml', null);
END;
/ 


/************************** MENU ***************************************/
PROMPT >> ADD MENU ITEMS

DECLARE
	v_app_sid				SECURITY.SECURITY_PKG.T_SID_ID; 
	v_act_id				SECURITY.SECURITY_PKG.T_ACT_ID;
	v_www_sid				SECURITY.SECURITY_PKG.T_SID_ID;
	v_forms					SECURITY.security_pkg.t_sid_id;
	v_registeredUsers_sid	SECURITY.SECURITY_PKG.T_SID_ID;
	v_administrators_sid	SECURITY.SECURITY_PKG.T_SID_ID;
	v_root_analysis_sid		SECURITY.SECURITY_PKG.T_SID_ID;
	v_waste_table_sid		SECURITY.SECURITY_PKG.T_SID_ID;
BEGIN 
	security.user_pkg.logonadmin('&&1');
	
	v_app_sid := security.security_pkg.GetApp;
	v_act_id := security.security_pkg.GetAct;
	v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_registeredUsers_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, security.security_pkg.GetApp, 'groups/RegisteredUsers');
	v_administrators_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, security.security_pkg.GetApp, 'groups/Administrators');
	v_root_analysis_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.GetApp, 'menu/Analysis');
	v_waste_table_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.GetApp, 'cms/"&&2"."WASTE"');
	
	BEGIN
--Add resource to display form
		BEGIN
			SECURITY.web_pkg.createresource(security.security_pkg.getact, v_www_sid, security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, v_www_sid,'csr'), 'forms', v_forms);
			security.acl_pkg.addace(security.security_pkg.getact, security.acl_pkg.getdaclidforsid(v_forms), -1, security.security_pkg.ace_type_allow, security.security_pkg.ace_flag_default, v_registeredusers_sid, security.security_pkg.permission_standard_read);
		exception
			WHEN security.security_pkg.duplicate_object_name THEN
				v_forms := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, v_www_sid,'csr/forms');
		END;		

		
--Add menu for analysis/waste pivot
		security.menu_pkg.CreateMenu(v_act_id, v_root_analysis_sid, 'csr_pivot_wastes', 'Pivot Wastes', '/fp/cms/analysis/pivot.acds?tabSid='||v_waste_table_sid, -1, null, v_root_analysis_sid);
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_root_analysis_sid), -1, security.security_pkg.ACE_TYPE_ALLOW, 0, v_administrators_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	exception
		WHEN security.security_pkg.duplicate_object_name THEN
		NULL;
	END;
END;
/
 
exit


