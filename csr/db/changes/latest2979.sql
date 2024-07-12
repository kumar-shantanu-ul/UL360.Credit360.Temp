define version=2979
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
--Failed to locate all sections of latest2972_12.sql
--Failed to locate all sections of latest2972_10.sql
CREATE TABLE csr.non_comp_type_rpt_audit_type (
	app_sid										NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	non_compliance_type_id						NUMBER(10, 0) NOT NULL,
	internal_audit_type_id						NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_nc_type_rpt_ia_type			PRIMARY KEY (app_sid, non_compliance_type_id, internal_audit_type_id),
	CONSTRAINT fk_nc_type_rpt_ia_type_nc_type	FOREIGN KEY (app_sid, non_compliance_type_id) REFERENCES csr.non_compliance_type (app_sid, non_compliance_type_id),
	CONSTRAINT fk_nc_type_rpt_ia_type_ia_type	FOREIGN KEY (app_sid, internal_audit_type_id) REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id)
);
CREATE TABLE CSRIMP.NON_COM_TYP_RPT_AUDI_TYP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	NON_COMPLIANCE_TYPE_ID NUMBER(10,0) NOT NULL,
	INTERNAL_AUDIT_TYPE_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_NON_COM_TYP_RPT_AUDI_TYP PRIMARY KEY (CSRIMP_SESSION_ID, NON_COMPLIANCE_TYPE_ID, INTERNAL_AUDIT_TYPE_ID),
	CONSTRAINT FK_NON_COM_TYP_RPT_AUDI_TYP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE SEQUENCE csr.auto_imp_core_data_val_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;
CREATE TABLE csr.auto_imp_core_data_val (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL ,
	val_id					NUMBER(10) NOT NULL,
	instance_id				NUMBER(10) NOT NULL,
	instance_step_id		NUMBER(10) NOT NULL,
	ind_sid					NUMBER(10) NOT NULL,
	region_sid				NUMBER(10) NOT NULL,
	start_dtm				DATE NOT NULL,
	end_dtm					DATE NOT NULL,
	val_number				NUMBER(24, 10),
	measure_conversion_id	NUMBER(10),
	entry_val_number		NUMBER(24, 10),
	note					CLOB,
	source_file_ref			VARCHAR2(1024),
	CONSTRAINT pk_auto_imp_core_data_val PRIMARY KEY (app_sid, val_id),
	CONSTRAINT uk_auto_imp_core_data_val UNIQUE (app_sid, ind_sid, region_sid, start_dtm, end_dtm, instance_step_id)
);
CREATE TABLE csr.auto_imp_mapping_type (
	mapping_type_id			NUMBER(2) NOT NULL,
	name					VARCHAR(255),
	CONSTRAINT pk_auto_imp_map_type PRIMARY KEY (mapping_type_id)
);
CREATE TABLE csr.auto_imp_date_type (
	date_type_id			NUMBER(2) NOT NULL,
	name					VARCHAR(255),
	CONSTRAINT pk_auto_imp_date_type PRIMARY KEY (date_type_id)
);
CREATE TABLE csr.auto_imp_date_col_type (
	date_col_type_id		NUMBER(2) NOT NULL,
	name					VARCHAR(255),
	CONSTRAINT pk_auto_imp_date_col_type PRIMARY KEY (date_col_type_id)
);
CREATE SEQUENCE csr.auto_imp_coredta_setngs_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;
CREATE TABLE csr.auto_imp_core_data_settings (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_imp_core_data_settings_id	NUMBER(10) NOT NULL,
	automated_import_class_sid		NUMBER(10) NOT NULL,
	step_number						NUMBER(10) NOT NULL,
	mapping_xml						SYS.XMLTYPE NOT NULL,
	automated_import_file_type_id	NUMBER(10) NOT NULL,
	dsv_separator					CHAR(1),
	dsv_quotes_as_literals			NUMBER(1),
	excel_worksheet_index			NUMBER(10),
	all_or_nothing					NUMBER(1),
	has_headings					NUMBER(1) DEFAULT 1 NOT NULL,
	ind_mapping_type_id				NUMBER(2) NOT NULL,
	region_mapping_type_id			NUMBER(2) NOT NULL,
	unit_mapping_type_id			NUMBER(2) NOT NULL,
	requires_validation_step		NUMBER(1) DEFAULT 0 NOT NULL,
	date_format_type_id				NUMBER(2) NOT NULL,
	first_col_date_format_id		NUMBER(2),
	second_col_date_format_id		NUMBER(2),
	zero_indexed_month_indices		NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT pk_auto_imp_core_data_settings PRIMARY KEY (app_sid, auto_imp_core_data_settings_id),
	CONSTRAINT ck_auto_imp_core_set_quo CHECK (dsv_quotes_as_literals IN (0,1) OR dsv_quotes_as_literals IS NULL),
	CONSTRAINT ck_auto_imp_core_set_allorno CHECK (all_or_nothing IN (0,1) OR all_or_nothing IS NULL),
	CONSTRAINT ck_auto_imp_core_set_hasheads CHECK (has_headings IN (0,1)),
	CONSTRAINT ck_auto_imp_core_set_reqvalid CHECK (requires_validation_step IN (0,1)),
	CONSTRAINT ck_auto_imp_core_set_zeroind CHECK (zero_indexed_month_indices IN (0,1)),
	CONSTRAINT fk_auto_imp_core_set_step FOREIGN KEY (app_sid, automated_import_class_sid, step_number) REFERENCES csr.automated_import_class_step(app_sid, automated_import_class_sid, step_number),
	CONSTRAINT uk_auto_imp_core_set_step UNIQUE (app_sid, automated_import_class_sid, step_number),
	CONSTRAINT fk_auto_imp_core_set_filetype FOREIGN KEY (automated_import_file_type_id) REFERENCES csr.automated_import_file_type(automated_import_file_type_id),
	CONSTRAINT fk_auto_imp_core_set_indmap FOREIGN KEY (ind_mapping_type_id) REFERENCES csr.auto_imp_mapping_type(mapping_type_id),
	CONSTRAINT fk_auto_imp_core_set_regmap FOREIGN KEY (region_mapping_type_id) REFERENCES csr.auto_imp_mapping_type(mapping_type_id),
	CONSTRAINT fk_auto_imp_core_set_unitmap FOREIGN KEY (unit_mapping_type_id) REFERENCES csr.auto_imp_mapping_type(mapping_type_id),
	CONSTRAINT fk_auto_imp_core_set_datetype FOREIGN KEY (date_format_type_id) REFERENCES csr.auto_imp_date_type(date_type_id), 
	CONSTRAINT fk_auto_imp_core_set_datecol1 FOREIGN KEY (first_col_date_format_id) REFERENCES csr.auto_imp_date_col_type(date_col_type_id),
	CONSTRAINT fk_auto_imp_core_set_datecol2 FOREIGN KEY (second_col_date_format_id) REFERENCES csr.auto_imp_date_col_type(date_col_type_id)
);
CREATE TABLE csr.auto_imp_indicator_map (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	automated_import_class_sid		NUMBER(10) NOT NULL,
	source_text						VARCHAR2(1024),
	ind_sid							NUMBER(10),
	CONSTRAINT pk_auto_imp_indicator_map PRIMARY KEY (app_sid, automated_import_class_sid, source_text),
	CONSTRAINT fk_auto_imp_ind_map_cls FOREIGN KEY (app_sid, automated_import_class_sid) REFERENCES csr.automated_import_class(app_sid, automated_import_class_sid),
	CONSTRAINT fk_auto_imp_ind_map_ind FOREIGN KEY (app_sid, ind_sid) REFERENCES csr.ind(app_sid, ind_sid)  
);
CREATE TABLE csr.auto_imp_region_map (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	automated_import_class_sid		NUMBER(10) NOT NULL,
	source_text						VARCHAR2(1024),
	region_sid						NUMBER(10),
	CONSTRAINT pk_auto_imp_region_map PRIMARY KEY (app_sid, automated_import_class_sid, source_text),
	CONSTRAINT fk_auto_imp_reg_map_cls FOREIGN KEY (app_sid, automated_import_class_sid) REFERENCES csr.automated_import_class(app_sid, automated_import_class_sid),
	CONSTRAINT fk_auto_imp_reg_map_reg FOREIGN KEY (app_sid, region_sid) REFERENCES csr.region(app_sid, region_sid)  
);
CREATE TABLE csr.auto_imp_unit_map (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	automated_import_class_sid		NUMBER(10) NOT NULL,
	source_text						VARCHAR2(1024),
	measure_conversion_id			NUMBER(10),
	CONSTRAINT pk_auto_imp_unit_map PRIMARY KEY (app_sid, automated_import_class_sid, source_text),
	CONSTRAINT fk_auto_imp_unit_map_cls FOREIGN KEY (app_sid, automated_import_class_sid) REFERENCES csr.automated_import_class(app_sid, automated_import_class_sid),
	CONSTRAINT fk_auto_imp_unit_map_unit FOREIGN KEY (app_sid, measure_conversion_id) REFERENCES csr.measure_conversion(app_sid, measure_conversion_id)  
);


ALTER TABLE CSR.PLUGIN ADD FORM_SID NUMBER(10);
ALTER TABLE CSR.PLUGIN DROP CONSTRAINT CK_PLUGIN_REFS ;
ALTER TABLE CSR.PLUGIN ADD CONSTRAINT CK_PLUGIN_REFS 
	CHECK (
        (TAB_SID IS NULL AND FORM_PATH IS NULL AND
         FORM_SID IS NULL AND GROUP_KEY IS NULL AND SAVED_FILTER_SID IS NULL AND
         CONTROL_LOOKUP_KEYS IS NULL AND PORTAL_SID IS NULL)
        OR
        (APP_SID IS NOT NULL AND (
            (TAB_SID IS NOT NULL AND (FORM_PATH IS NOT NULL OR FORM_SID IS NOT NULL) AND 
             GROUP_KEY IS NULL AND
             SAVED_FILTER_SID IS NULL AND
             PORTAL_SID IS NULL)
            OR
            (TAB_SID IS NULL AND FORM_PATH IS NULL AND
             FORM_SID IS NULL AND GROUP_KEY IS NOT NULL AND
             SAVED_FILTER_SID IS NULL AND
             PORTAL_SID IS NULL)
            OR
            (TAB_SID IS NULL AND FORM_PATH IS NULL AND
             FORM_SID IS NULL AND GROUP_KEY IS NULL AND
             SAVED_FILTER_SID IS NOT NULL AND
             PORTAL_SID IS NULL)
            OR
            (TAB_SID IS NULL AND FORM_PATH IS NULL AND
             FORM_SID IS NULL AND GROUP_KEY IS NULL AND
             SAVED_FILTER_SID IS NULL AND
             PORTAL_SID IS NOT NULL)
        ))
    );
ALTER TABLE CSR.INTERNAL_AUDIT_TYPE ADD FORM_SID NUMBER(10);
ALTER TABLE CSR.INTERNAL_AUDIT_TYPE DROP CONSTRAINT CHK_IA_TYPE_CMS_TAB_FORM ;
ALTER TABLE CSR.INTERNAL_AUDIT_TYPE ADD CONSTRAINT CHK_IA_TYPE_CMS_TAB_FORM 
	CHECK ((TAB_SID IS NULL AND FORM_PATH IS NULL AND FORM_SID IS NULL) OR (TAB_SID IS NOT NULL AND (FORM_PATH IS NOT NULL OR FORM_SID IS NOT NULL)));
ALTER TABLE CSR.DELEGATION_GRID ADD FORM_SID NUMBER(10);
ALTER TABLE CSR.DELEGATION_GRID MODIFY PATH NULL;
ALTER TABLE CSR.DELEGATION_GRID ADD CONSTRAINT CHK_DELE_GRID_CMS_FORM CHECK (PATH IS NOT NULL OR FORM_SID IS NOT NULL);
ALTER TABLE CSRIMP.PLUGIN ADD FORM_SID NUMBER(10);
ALTER TABLE CSRIMP.INTERNAL_AUDIT_TYPE ADD FORM_SID NUMBER(10);
ALTER TABLE CSRIMP.INTERNAL_AUDIT_TYPE DROP CONSTRAINT CHK_IA_TYPE_CMS_TAB_FORM ;
ALTER TABLE CSRIMP.INTERNAL_AUDIT_TYPE ADD CONSTRAINT CHK_IA_TYPE_CMS_TAB_FORM 
	CHECK ((TAB_SID IS NULL AND FORM_PATH IS NULL AND FORM_SID IS NULL) OR (TAB_SID IS NOT NULL AND (FORM_PATH IS NOT NULL OR FORM_SID IS NOT NULL)));
ALTER TABLE CSRIMP.DELEGATION_GRID ADD FORM_SID NUMBER(10);
ALTER TABLE CSRIMP.DELEGATION_GRID MODIFY PATH NULL;
ALTER TABLE CSRIMP.DELEGATION_GRID ADD CONSTRAINT CHK_DELE_GRID_CMS_FORM CHECK (PATH IS NOT NULL OR FORM_SID IS NOT NULL);
ALTER TABLE CSR.MODULE ADD (
	WARNING_MSG	VARCHAR2(1023)
);
ALTER TABLE cms.tab ADD is_basedata NUMBER(1) DEFAULT(0) NOT NULL;
ALTER TABLE cms.tab ADD CONSTRAINT CK_TAB_IS_BASEDATA_1_0 CHECK (is_basedata IN (0,1));
ALTER TABLE cms.ck_cons ADD (
	constraint_owner	VARCHAR2(30),
	constraint_name		VARCHAR2(30)
);
ALTER TABLE cms.fk_cons ADD (
	constraint_owner	VARCHAR2(30),
	constraint_name		VARCHAR2(30)
);
ALTER TABLE cms.uk_cons ADD (
	constraint_owner	VARCHAR2(30),
	constraint_name		VARCHAR2(30)
);
ALTER TABLE csrimp.cms_tab ADD is_basedata NUMBER(1) NOT NULL;
ALTER TABLE csrimp.cms_tab ADD CONSTRAINT CK_TAB_IS_BASEDATA_1_0 CHECK (is_basedata IN (0,1));
ALTER TABLE csrimp.cms_ck_cons ADD (
	constraint_owner	VARCHAR2(30) NOT NULL,
	constraint_name		VARCHAR2(30) NOT NULL
);
ALTER TABLE csrimp.cms_fk_cons ADD (
	constraint_owner	VARCHAR2(30) NOT NULL,
	constraint_name		VARCHAR2(30) NOT NULL
);
ALTER TABLE csrimp.cms_uk_cons ADD (
	constraint_owner	VARCHAR2(30) NOT NULL,
	constraint_name		VARCHAR2(30) NOT NULL
);
BEGIN
	FOR x IN (SELECT app_sid,fk_cons_id,owner, constraint_name
		FROM (SELECT fk.app_sid, fk.fk_cons_id, fk.owner,
				DECODE(t.managed, 0, fk.table_name, 1, 'C$'||fk.table_name) table_name, fk.table_name tab_name,
				LISTAGG(fk.column_name, ', ') WITHIN GROUP (ORDER BY pos) column_names, fk.uk_cons_id, fk.r_owner,
				DECODE(tr.managed, 0, fk.r_table_name, 1, 'C$'||fk.r_table_name) r_table_name, fk.r_table_name r_tab_name,
				LISTAGG(fk.r_column_name, ', ') WITHIN GROUP (ORDER BY pos) r_column_names
		  FROM cms.fk fk
		  JOIN cms.tab t ON fk.fk_tab_sid = t.tab_sid
		  JOIN cms.tab tr ON fk.r_tab_sid = tr.tab_sid
		 GROUP BY fk.app_sid, fk.fk_cons_id, fk.fk_tab_sid, fk.owner, t.managed, fk.table_name,
				  fk.uk_cons_id, fk.r_owner, fk.r_tab_sid, tr.managed, fk.r_table_name)
		LEFT JOIN (WITH ac AS (
			SELECT constraint_type, owner, constraint_name, table_name, r_owner, r_constraint_name,
					LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY position) column_names
			  FROM all_constraints
			  JOIN all_cons_columns USING(owner, table_name, constraint_name)
			 GROUP BY constraint_type, owner, constraint_name, table_name, r_owner, r_constraint_name)
			SELECT ac.owner, ac.constraint_name, ac.table_name, ac.column_names, acr.owner r_owner,
					acr.table_name r_table_name, acr.column_names r_column_names
			  FROM ac ac
			  JOIN ac acr ON ac.r_owner = acr.owner AND ac.r_constraint_name = acr.constraint_name
			 WHERE ac.constraint_type = 'R') 
	   USING (owner, table_name, column_names, r_owner, r_table_name, r_column_names))
	LOOP
		UPDATE cms.fk_cons
		   SET constraint_name = x.constraint_name, constraint_owner= x.owner 
		 WHERE fk_cons_id= x.fk_cons_id 
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/
BEGIN
	FOR x in (SELECT fk_cons_id, owner, app_sid, 'FK_'||
			CASE
				WHEN LENGTH(tab_name)+LENGTH(r_tab_name)<=23 THEN tab_name||'_'||r_tab_name
				ELSE
					CASE
						WHEN LENGTH(r_tab_name)>12 THEN SUBSTR(tab_name,1,12)||'_'||SUBSTR(r_tab_name,1,11)
						ELSE SUBSTR(tab_name,1,23-LENGTH(r_tab_name))||'_'||r_tab_name
					END
			END constraint_name
		FROM (SELECT fk.app_sid, fk.fk_cons_id, fk.owner,
				DECODE(t.managed, 0, fk.table_name, 1, 'C$'||fk.table_name) table_name, fk.table_name tab_name,
				LISTAGG(fk.column_name, ', ') WITHIN GROUP (ORDER BY pos) column_names, fk.uk_cons_id, fk.r_owner,
				DECODE(tr.managed, 0, fk.r_table_name, 1, 'C$'||fk.r_table_name) r_table_name, fk.r_table_name r_tab_name,
				LISTAGG(fk.r_column_name, ', ') WITHIN GROUP (ORDER BY pos) r_column_names
		  FROM cms.fk fk
		  JOIN cms.tab t ON fk.fk_tab_sid = t.tab_sid
		  JOIN cms.tab tr ON fk.r_tab_sid = tr.tab_sid
		 WHERE fk_cons_id IN (SELECT fk_cons_id
			FROM cms.fk_cons
		   WHERE constraint_name IS NULL)
		 GROUP BY fk.app_sid, fk.fk_cons_id, fk.fk_tab_sid, fk.owner, t.managed, fk.table_name,
				  fk.uk_cons_id, fk.r_owner, fk.r_tab_sid, tr.managed, fk.r_table_name))
	LOOP
		UPDATE cms.fk_cons
		   SET constraint_name = x.constraint_name, constraint_owner= x.owner 
		 WHERE fk_cons_id= x.fk_cons_id 
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/
DECLARE
	v_suffix NUMBER(10);
BEGIN
	FOR x in (SELECT app_sid, constraint_owner, constraint_name, count(*) FROM cms.fk_cons
		GROUP BY app_sid, constraint_owner, constraint_name 
	   HAVING COUNT(*) >1)
	LOOP
		v_suffix := 1;
		FOR y IN(SELECT app_sid, fk_cons_id 
			FROM cms.fk_cons 
		   WHERE constraint_name = x.constraint_name 
			 AND constraint_owner = x.constraint_owner 
			 AND app_sid = x.app_sid)
		LOOP
			UPDATE cms.fk_cons
			   SET constraint_name = constraint_name || '_' || v_suffix 
			 WHERE fk_cons_id = y.fk_cons_id 
			   AND app_sid= y.app_sid;
			v_suffix := v_suffix+ 1;
		END LOOP;
	END LOOP;
END;
/
/*
 * all_constraints.search_condition is returned as a LONG datatype, which cannot easily
 * be compared to a CLOB or converted to a CLOB. The TO_CLOB function can only be used
 * to convert the column when inserting into a CLOB column, so create a temporary table
 * to store the data as a CLOB and allow comparison  with cms.ck_cons.search_condition.
 */
CREATE TABLE cms.us3942_check_constraint AS (
	SELECT owner, table_name, constraint_name, TO_LOB(search_condition) search_condition
	  FROM all_constraints
	 WHERE constraint_type = 'C'
	   AND (owner, table_name) IN (SELECT owner, table_name FROM cms.ck)
	);
BEGIN
	FOR x IN (SELECT t1.app_sid, t1.ck_cons_id, t1.owner, t1.tab_name, t1.column_names, t2.constraint_name
		FROM (SELECT app_sid, ck_cons_id, oracle_schema owner, managed, oracle_table tab_name, column_names, search_condition,
			     DECODE(managed,0,oracle_table,'C$'||oracle_table) table_name
			FROM cms.ck_cons
			JOIN cms.tab USING (app_sid, tab_sid)
			JOIN (SELECT app_sid, ck_cons_id, LISTAGG(column_name,'_') WITHIN GROUP (ORDER BY column_name) column_names
				FROM cms.ck
			   GROUP BY app_sid, ck_cons_id) 
		   USING (app_sid, ck_cons_id)) t1
		LEFT JOIN (SELECT owner, table_name, constraint_name, search_condition, column_names
			FROM CMS.US3942_CHECK_CONSTRAINT
			JOIN (SELECT owner, table_name, constraint_name, LISTAGG(column_name, '_') WITHIN GROUP (ORDER BY column_name) column_names
				FROM all_cons_columns
			   GROUP BY owner, constraint_name, table_name) 
		   USING (owner, constraint_name, table_name)) t2 
		  ON t1.owner = t2.owner 
		 AND t1.table_name = t2.table_name 
		 AND t2.column_names = t1.column_names 
		 AND dbms_lob.compare(t1.search_condition, t2.search_condition) = 0)
	LOOP
		UPDATE cms.ck_cons
		   SET constraint_name = x.constraint_name, constraint_owner= x.owner 
		 WHERE ck_cons_id= x.ck_cons_id 
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/
BEGIN
	FOR x in (SELECT ck_cons_id, owner, app_sid, 'CK_'||
				CASE
					WHEN LENGTH(t1.tab_name)+LENGTH(t1.column_names)<=23 THEN t1.tab_name||'_'||t1.column_names
					ELSE
						CASE
							WHEN LENGTH(t1.column_names)>12 THEN SUBSTR(t1.tab_name,1,12)||'_'||SUBSTR(t1.column_names,1,11)
							ELSE SUBSTR(t1.tab_name,1,23-LENGTH(t1.column_names))||'_'||t1.column_names
						END
				END constraint_name
		FROM (SELECT app_sid, ck_cons_id, oracle_schema owner, managed, oracle_table tab_name, column_names, search_condition,
			     DECODE(managed,0,oracle_table,'C$'||oracle_table) table_name
			FROM cms.ck_cons
			JOIN cms.tab USING (app_sid, tab_sid)
			JOIN (SELECT app_sid, ck_cons_id, LISTAGG(column_name,'_') WITHIN GROUP (ORDER BY column_name) column_names
				FROM cms.ck
			   GROUP BY app_sid, ck_cons_id) 
		   USING (app_sid, ck_cons_id)) t1
		   WHERE ck_cons_id IN (SELECT ck_cons_id
			FROM cms.ck_cons
		   WHERE constraint_name IS NULL))
	LOOP
		UPDATE cms.ck_cons
		   SET constraint_name = x.constraint_name, constraint_owner= x.owner 
		 WHERE ck_cons_id= x.ck_cons_id 
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/
DECLARE
	v_suffix NUMBER(10);
BEGIN
	FOR x in (SELECT app_sid, constraint_owner, constraint_name, count(*) FROM cms.ck_cons
		GROUP BY app_sid, constraint_owner, constraint_name 
	   HAVING COUNT(*) >1)
	LOOP
		v_suffix := 1;
		FOR y IN(SELECT app_sid, ck_cons_id 
			FROM cms.ck_cons 
		   WHERE constraint_name = x.constraint_name 
			 AND constraint_owner = x.constraint_owner 
			 AND app_sid = x.app_sid)
		LOOP
			UPDATE cms.ck_cons
			   SET constraint_name = constraint_name || '_' || v_suffix 
			 WHERE ck_cons_id = y.ck_cons_id 
			   AND app_sid= y.app_sid;
			v_suffix := v_suffix+ 1;
		END LOOP;
	END LOOP;
END;
/
DROP TABLE cms.us3942_check_constraint;
BEGIN
	FOR x IN (SELECT app_sid,uk_cons_id,owner, constraint_name
		FROM (SELECT uk.app_sid, uk.uk_cons_id, uk.owner, table_name tab_name,
				 DECODE(t.managed, 0, uk.table_name, 1, 'C$'||uk.table_name) table_name,
				 LISTAGG(uk.column_name, '_') WITHIN GROUP (ORDER BY uk.pos) column_names
			FROM cms.uk
			JOIN cms.tab t ON uk.app_sid = t.app_sid AND uk.uk_tab_sid = t.tab_sid
		   GROUP BY uk.app_sid, uk.uk_cons_id, uk.owner, t.managed, uk.table_name)
		LEFT JOIN (SELECT constraint_name, owner, table_name, LISTAGG(column_name, '_') WITHIN GROUP (ORDER BY position) column_names
			FROM all_constraints
			JOIN all_cons_columns USING (owner, table_name, constraint_name)
		   WHERE constraint_type = 'U'
		   GROUP BY constraint_name, owner, table_name) 
	   USING (owner, table_name, column_names))
	LOOP
		UPDATE cms.uk_cons
		   SET constraint_name = x.constraint_name, constraint_owner= x.owner 
		 WHERE uk_cons_id= x.uk_cons_id 
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/
BEGIN
	FOR x in (SELECT uk_cons_id, owner, app_sid,  CASE
				WHEN pk_cons_id = uk_cons_id THEN CASE
					WHEN LENGTH(tab_name) <= 23 THEN 'PK_' || tab_name
					ELSE 'PK_' || SUBSTR(tab_name, 23)
				END
				ELSE 'UK_'|| CASE
						WHEN LENGTH(tab_name)+LENGTH(column_names)<=23 THEN tab_name||'_'||column_names
						ELSE
							CASE
								WHEN LENGTH(column_names)>12 THEN SUBSTR(tab_name,1,12)||'_'||SUBSTR(column_names,1,11)
								ELSE SUBSTR(tab_name,1,23-LENGTH(column_names))||'_'||column_names
							END
					END 
				END constraint_name
		FROM (SELECT uk.app_sid, uk.uk_cons_id, uk.owner, table_name tab_name, t.pk_cons_id,
				 DECODE(t.managed, 0, uk.table_name, 1, 'C$'||uk.table_name) table_name,
				 LISTAGG(uk.column_name, '_') WITHIN GROUP (ORDER BY uk.pos) column_names
			FROM cms.uk
			JOIN cms.tab t ON uk.app_sid = t.app_sid AND uk.uk_tab_sid = t.tab_sid
		   GROUP BY uk.app_sid, uk.uk_cons_id, uk.owner, t.managed, uk.table_name, t.pk_cons_id)
	   WHERE uk_cons_id IN (SELECT uk_cons_id
			FROM cms.uk_cons
		   WHERE constraint_name IS NULL))
	LOOP
		UPDATE cms.uk_cons
		   SET constraint_name = x.constraint_name, constraint_owner= x.owner 
		 WHERE uk_cons_id= x.uk_cons_id 
		   AND app_sid = x.app_sid;
	END LOOP;
END;
/
DECLARE
	v_suffix NUMBER(10);
BEGIN
	FOR x in (SELECT app_sid, constraint_owner, constraint_name, count(*) FROM cms.uk_cons
		GROUP BY app_sid, constraint_owner, constraint_name 
	   HAVING COUNT(*) >1)
	LOOP
		v_suffix := 1;
		FOR y IN(SELECT app_sid, uk_cons_id 
			FROM cms.uk_cons 
		   WHERE constraint_name = x.constraint_name 
			 AND constraint_owner = x.constraint_owner 
			 AND app_sid = x.app_sid)
		LOOP
			UPDATE cms.uk_cons
			   SET constraint_name = constraint_name || '_' || v_suffix 
			 WHERE uk_cons_id = y.uk_cons_id 
			   AND app_sid= y.app_sid;
			v_suffix := v_suffix+ 1;
		END LOOP;
	END LOOP;
END;
/
UPDATE cms.fk_cons fk
   SET fk.constraint_name = 'FK_' || fk_cons_id,
   fk.constraint_owner = (
	SELECT oracle_schema 
	  FROM cms.tab t 
	  WHERE t.tab_sid = fk.tab_sid
   )
 WHERE fk.constraint_name IS NULL 
    OR fk.constraint_owner IS NULL;
UPDATE cms.ck_cons ck
   SET ck.constraint_name = 'CK_' || ck_cons_id,
   ck.constraint_owner = (
	SELECT oracle_schema 
	  FROM cms.tab t 
	  WHERE t.tab_sid = ck.tab_sid
   )
 WHERE ck.constraint_name IS NULL 
    OR ck.constraint_owner IS NULL;
UPDATE cms.uk_cons uk
   SET uk.constraint_name = 'UK_' || uk_cons_id,
   uk.constraint_owner = (
	SELECT oracle_schema 
	  FROM cms.tab t 
	  WHERE t.tab_sid = uk.tab_sid
   )
 WHERE uk.constraint_name IS NULL 
    OR uk.constraint_owner IS NULL;
ALTER TABLE cms.fk_cons MODIFY (
	constraint_owner	VARCHAR2(30) NOT NULL,
	constraint_name		VARCHAR2(30) NOT NULL
);
ALTER TABLE cms.fk_cons ADD CONSTRAINT UK_FK_CONS_OWNER_NAME UNIQUE (app_sid, constraint_owner, constraint_name);
ALTER TABLE cms.ck_cons MODIFY (
	constraint_owner	VARCHAR2(30) NOT NULL,
	constraint_name		VARCHAR2(30) NOT NULL
);
ALTER TABLE cms.ck_cons ADD CONSTRAINT UK_CK_CONS_OWNER_NAME UNIQUE (app_sid, constraint_owner, constraint_name);
ALTER TABLE cms.uk_cons MODIFY (
	constraint_owner	VARCHAR2(30) NOT NULL,
	constraint_name		VARCHAR2(30) NOT NULL
);
ALTER TABLE cms.uk_cons ADD CONSTRAINT UK_UK_CONS_OWNER_NAME UNIQUE (app_sid, constraint_owner, constraint_name);
ALTER TABLE CSR.AUTO_EXP_FILECREATE_DSV
ADD encoding_name VARCHAR2(255);
DECLARE
	v_nullable VARCHAR2(1);
BEGIN
	SELECT nullable
	  INTO v_nullable
	  FROM all_tab_columns
	 WHERE owner='CSR' AND table_name='PROPERTY_TYPE' AND column_name='LOOKUP_KEY';
	IF v_nullable = 'N' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.PROPERTY_TYPE modify LOOKUP_KEY NULL';
	END IF;
	
	SELECT nullable
	  INTO v_nullable
	  FROM all_tab_columns
	 WHERE owner='CSR' AND table_name='PROPERTY_TYPE' AND column_name='GRESB_PROP_TYPE_CODE';
	IF v_nullable = 'N' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.PROPERTY_TYPE modify GRESB_PROP_TYPE_CODE NULL';
	END IF;
	
END;
/
ALTER TABLE CSR.DATAVIEW ADD (HIGHLIGHT_CHANGED_SINCE NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE CSR.DATAVIEW ADD (HIGHLIGHT_CHANGED_SINCE_DTM DATE);
ALTER TABLE CSR.DATAVIEW_HISTORY ADD (HIGHLIGHT_CHANGED_SINCE NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE CSR.DATAVIEW_HISTORY ADD (HIGHLIGHT_CHANGED_SINCE_DTM DATE);
ALTER TABLE CSRIMP.DATAVIEW ADD (HIGHLIGHT_CHANGED_SINCE NUMBER(1, 0) NOT NULL);
ALTER TABLE CSRIMP.DATAVIEW ADD (HIGHLIGHT_CHANGED_SINCE_DTM DATE);
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD (HIGHLIGHT_CHANGED_SINCE NUMBER(1, 0) NOT NULL);
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD (HIGHLIGHT_CHANGED_SINCE_DTM DATE);
declare
	v_num number;
begin
	select csr.plugin_id_seq.nextval into v_num from dual;
	if v_num < 10000 then
		execute immediate 'drop sequence csr.plugin_id_seq';
		execute immediate 'create sequence csr.plugin_id_seq start with 10000 nocache';
		execute immediate 'grant select on csr.plugin_Id_seq to csrimp';
	end if;
end;
/
alter table csr.non_comp_default_issue drop constraint CHK_NON_COMP_DEF_ISS_DUE_UNIT;
alter table csr.non_comp_default_issue add
	CONSTRAINT CHK_NON_COMP_DEF_ISS_DUE_UNIT CHECK (DUE_DTM_RELATIVE_UNIT IN ('d','m'));
alter table csrimp.non_comp_default_issue drop constraint CHK_NON_COMP_DEF_ISS_DUE_UNIT;
alter table csrimp.non_comp_default_issue add
	CONSTRAINT CHK_NON_COMP_DEF_ISS_DUE_UNIT CHECK (DUE_DTM_RELATIVE_UNIT IN ('d','m'));
alter TABLE CSRIMP.QUICK_SURVEY_EXPR_ACTION drop
	CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK ;
alter TABLE CSRIMP.QUICK_SURVEY_EXPR_ACTION add
    CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK CHECK (
	(ACTION_TYPE = 'nc' AND QS_EXPR_NON_COMPL_ACTION_ID IS NOT NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'msg' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NOT NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'show_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NOT NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'mand_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NOT NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'show_p' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NOT NULL)
    );
 
drop index CSRIMP.UK_CUSTOMER_AGGREGATE_TYPE ;
CREATE UNIQUE INDEX CSRIMP.UK_CUSTOMER_AGGREGATE_TYPE ON CSRIMP.CHAIN_CUSTOMER_AGGREGATE_TYPE (
		CSRIMP_SESSION_ID, CARD_GROUP_ID, CMS_AGGREGATE_TYPE_ID, INITIATIVE_METRIC_ID, IND_SID, FILTER_PAGE_IND_INTERVAL_ID, METER_AGGREGATE_TYPE_ID, SCORE_TYPE_AGG_TYPE_ID); 
ALTER TABLE csr.auto_impexp_instance_msg
 DROP CONSTRAINT ck_auto_impexp_inst_msg_sev;
ALTER TABLE csr.auto_impexp_instance_msg
 ADD CONSTRAINT ck_auto_impexp_inst_msg_sev CHECK (severity IN ('W', 'X', 'I', 'S'));
alter table aspen2.application add cdn_server varchar2(512);
alter table csrimp.aspen2_application add cdn_server varchar2(512);
ALTER TABLE CSR.CUSTOMER ADD (
    DELEG_DROPDOWN_THRESHOLD           NUMBER(10)         DEFAULT 4 NOT NULL
);


GRANT SELECT ON csr.property_options to cms;
GRANT SELECT ON csr.delegation_grid to cms;
GRANT SELECT ON csr.v$ind to cms;
GRANT SELECT ON csr.aggregate_ind_group to cms;
GRANT SELECT ON csr.aggregate_ind_group_member to cms;
GRANT select_catalog_role TO cms;
grant select, insert, update, delete on csrimp.non_com_typ_rpt_audi_typ to web_user;
grant select, insert, update on csr.non_comp_type_rpt_audit_type to csrimp;


ALTER TABLE CSR.PLUGIN ADD CONSTRAINT FK_PLUGIN_CMS_FORM
	FOREIGN KEY (APP_SID, FORM_SID) 
	REFERENCES CMS.FORM (APP_SID, FORM_SID) ON DELETE CASCADE;
	
ALTER TABLE CSR.INTERNAL_AUDIT_TYPE ADD CONSTRAINT FK_INT_AUDIT_TYPE_CMS_FORM
	FOREIGN KEY (APP_SID, FORM_SID) 
	REFERENCES CMS.FORM (APP_SID, FORM_SID);
	
ALTER TABLE CSR.DELEGATION_GRID ADD CONSTRAINT FK_DELE_GRID_CMS_FORM
	FOREIGN KEY (APP_SID, FORM_SID) 
	REFERENCES CMS.FORM (APP_SID, FORM_SID);
ALTER TABLE CSR.DATAVIEW ADD CONSTRAINT CK_DATAVIEW_HGHLGHT_CHGD_SNCE CHECK (HIGHLIGHT_CHANGED_SINCE IN (0,1));
ALTER TABLE CSR.DATAVIEW_HISTORY ADD CONSTRAINT CK_DV_HIST_HIGHLIGHT_CHGD_SNCE CHECK (HIGHLIGHT_CHANGED_SINCE IN (0,1));
ALTER TABLE CSRIMP.DATAVIEW ADD CONSTRAINT CK_DATAVIEW_HGHLGHT_CHGD_SNCE CHECK (HIGHLIGHT_CHANGED_SINCE IN (0,1));
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD CONSTRAINT CK_DV_HIST_HIGHLIGHT_CHGD_SNCE CHECK (HIGHLIGHT_CHANGED_SINCE IN (0,1));

CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, r.geo_longitude longitude, r.geo_latitude latitude, rt.class_name region_type_class_name,
		   ia.auditee_user_sid, u.full_name auditee_full_name, u.email auditee_email,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.interactive audit_type_interactive,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename, cast(act.icon_image_sha1  as varchar2(40)) icon_image_sha1,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, NVL(cu.email, au.email) auditor_email,
		   iat.filename template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final, 
		   fs.state_colour flow_state_colour, act.is_failure,
		   sqs.survey_sid summary_survey_sid, sqs.label summary_survey_label, ssr.survey_version summary_survey_version, ia.summary_response_id,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label ia_type_group_label, atg.lookup_key ia_type_group_lookup_key, atg.internal_audit_type_group_id, iat.form_sid,
		   atg.audit_singular_label, atg.audit_plural_label, atg.auditee_user_label, atg.auditor_user_label, atg.auditor_name_label,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score, sr.survey_version,
		   sst.score_type_id survey_score_type_id, sr.score_threshold_id survey_score_thrsh_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, NVL(ia.ovw_nc_score_thrsh_id, ia.nc_score_thrsh_id) nc_score_thrsh_id, ncst.max_score nc_max_score, ncst.label nc_score_label,
		   ncst.format_mask nc_score_format_mask,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm END next_audit_due_dtm
	  FROM csr.internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM csr.audit_user_cover auc
			  JOIN csr.user_cover uc ON auc.app_sid = uc.app_sid AND auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.app_sid = auc.app_sid AND PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  LEFT JOIN csr.csr_user u ON ia.auditee_user_sid = u.csr_user_sid AND ia.app_sid = u.app_sid
	  JOIN csr.csr_user au ON ia.auditor_user_sid = au.csr_user_sid AND ia.app_sid = au.app_sid
	  LEFT JOIN csr.csr_user cu ON cvru.user_giving_cover_sid = cu.csr_user_sid AND cvru.app_sid = cu.app_sid
	  LEFT JOIN csr.internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN csr.internal_audit_type_group atg ON atg.app_sid = iat.app_sid AND atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
	  LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  LEFT JOIN csr.v$quick_survey_response ssr ON ia.summary_response_id = ssr.survey_response_id AND ia.app_sid = sr.app_sid
	  LEFT JOIN csr.v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN csr.v$quick_survey sqs ON NVL(ssr.survey_sid, iat.summary_survey_sid) = sqs.survey_sid AND iat.app_sid = sqs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM csr.audit_non_compliance anc
			  JOIN csr.non_compliance nnc ON anc.non_compliance_id = nnc.non_compliance_id AND anc.app_sid = nnc.app_sid
			  LEFT JOIN csr.issue_non_compliance inc ON nnc.non_compliance_id = inc.non_compliance_id AND nnc.app_sid = inc.app_sid
			  LEFT JOIN csr.issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE ((nnc.is_closed IS NULL
			   AND i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
			   AND i.deleted = 0)
			    OR nnc.is_closed = 0)
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN csr.v$region r ON ia.app_sid = r.app_sid AND ia.region_sid = r.region_sid
	  LEFT JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id AND ia.internal_audit_type_id = atct.internal_audit_type_id AND ia.app_sid = atct.app_sid
	  LEFT JOIN csr.flow_item fi
	    ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN csr.flow_state fs
	    ON fs.app_sid = fi.app_sid AND fs.flow_state_id = fi.current_state_id
	  LEFT JOIN csr.flow f
	    ON f.app_sid = fi.app_sid AND f.flow_sid = fi.flow_sid
	  LEFT JOIN chain.company ac
	    ON ia.auditor_company_sid = ac.company_sid AND ia.app_sid = ac.app_sid
	  LEFT JOIN score_type ncst ON ncst.app_sid = iat.app_sid AND ncst.score_type_id = iat.nc_score_type_id
	  LEFT JOIN score_type sst ON sst.app_sid = qs.app_sid AND sst.score_type_id = qs.score_type_id
	 WHERE ia.deleted = 0;

begin
	begin
		INSERT INTO csr.plugin_type
			(plugin_type_id, description)
		VALUES
			(17, 'Emission factor tab');
	exception
		when dup_val_on_index then
			null;
	end;
end;
/
declare
	procedure sp(
		in_plugin_id					IN	csr.plugin.plugin_id%TYPE,
		in_plugin_type_id				IN 	csr.plugin.plugin_type_id%TYPE,
		in_description					IN  csr.plugin.description%TYPE,
		in_js_include					IN  csr.plugin.js_include%TYPE,
		in_js_class						IN  csr.plugin.js_class%TYPE,
		in_cs_class						IN  csr.plugin.cs_class%TYPE,
		in_details						IN  csr.plugin.details%TYPE,
		in_preview_image_path			IN  csr.plugin.preview_image_path%TYPE,
		in_r_script_path				IN	csr.plugin.r_script_path%TYPE
	)
	as
		v_plugin_id						csr.plugin.plugin_id%type;
		v_cnt							number;
	begin
		v_plugin_id := in_plugin_id;
		select count(*) into v_cnt from csr.plugin where plugin_id = in_plugin_id;
		if v_cnt > 0 then
			select count(*) into v_cnt from csr.plugin where plugin_id = in_plugin_id and plugin_type_id = in_plugin_type_id and js_class = in_js_class and app_sid is null;
			if v_cnt = 0 then
				select csr.plugin_id_seq.nextval into v_plugin_id from dual;
			end if;
		end if;
	
		begin
			INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
				details, preview_image_path, r_script_path)
			VALUES (NULL, v_plugin_id, in_plugin_type_id, in_description,  in_js_include, in_js_class, 
				in_cs_class, in_details, in_preview_image_path, in_r_script_path);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.plugin 
				   SET description = in_description,
					   js_include = in_js_include,
					   cs_class = in_cs_class,
					   details = in_details,
					   preview_image_path = in_preview_image_path,
					   r_script_path = in_r_script_path
				 WHERE plugin_type_id = in_plugin_type_id
				   AND js_class = in_js_class
				   AND app_sid IS NULL;
		end;
	end;
begin
	sp(1, 2, 'ListEditor CMS Plugin', '/csr/shared/plugins/ListEditorCMSPlugin.js', 'Credit360.plugins.ListEditorCMSPlugin', 'Credit360.Plugins.EmptyDto', '', '', '');
	sp(2, 1, 'Spaces', '/csr/site/property/properties/controls/SpaceListMetricPanel.js', 'Controls.SpaceListMetricPanel', 'Credit360.Plugins.PluginDto', 'This tab shows a list of spaces (sub-regions) at the selected property. It allows you to create new spaces, and set space metrics that have been configured for the chosen space type.', '/csr/shared/plugins/screenshots/property_tab_space_list_metric.png', '');
	sp(3, 1, 'Delegations tab', '/csr/site/property/properties/controls/DelegationPanel.js', 'Controls.DelegationPanel', 'Credit360.Property.Plugins.DelegationDto', 'This tab shows any delegation forms that the logged in user needs to enter data or approve for the property they are viewing.', '/csr/shared/plugins/screenshots/property_tab_delegation.png', '');
	sp(4, 4, 'My feed', '/csr/site/activity/controls/MyFeedPanel.js', 'Activity.MyFeedPanel', 'Credit360.UserProfile.MyFeedDto', '', '', '');
	sp(5, 4, 'My activities', '/csr/site/activity/controls/MyActivitiesPanel.js', 'Activity.MyActivitiesPanel', 'Credit360.UserProfile.MyActivitiesDto', '', '', '');
	sp(6, 1, 'Actions tab', '/csr/site/property/properties/controls/IssuesPanel.js', 'Controls.IssuesPanel', 'Credit360.Plugins.PluginDto', 'This tab shows a list of actions (issues) associated with the property.', '/csr/shared/plugins/screenshots/property_tab_actions.png', '');
	sp(7, 5, 'Summary', '/csr/site/teamroom/controls/SummaryPanel.js', 'Teamroom.SummaryPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(8, 5, 'Documents', '/csr/site/teamroom/controls/DocumentsPanel.js', 'Teamroom.DocumentsPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(9, 5, 'Calendar', '/csr/site/teamroom/controls/CalendarPanel.js', 'Teamroom.CalendarPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(10, 5, 'Actions', '/csr/site/teamroom/controls/IssuesPanel.js', 'Teamroom.IssuesPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(11, 5, 'Projects', '/csr/site/teamroom/controls/InitiativesPanel.js', 'Teamroom.InitiativesPanel', 'Credit360.Plugins.InitiativesPlugin', '', '', '');
	sp(12, 8, 'Details', '/csr/site/initiatives/detail/controls/SummaryPanel.js', 'Credit360.Initiatives.SummaryPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(13, 8, 'Documents', '/csr/site/initiatives/detail/controls/DocumentsPanel.js', 'Credit360.Initiatives.DocumentsPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(14, 8, 'Calendar', '/csr/site/initiatives/detail/controls/CalendarPanel.js', 'Credit360.Initiatives.CalendarPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(15, 8, 'Actions', '/csr/site/initiatives/detail/controls/IssuesPanel.js', 'Credit360.Initiatives.IssuesPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(16, 1, 'Property Surveys Tab', '/csr/site/property/properties/controls/surveysTab.js', 'Controls.SurveysTab', 'Credit360.Property.Plugins.SurveysTab', 'This tab shows the list of surveys the logged in user has access to for the property being viewed.', '/csr/shared/plugins/screenshots/property_tab_surveys.png', '');
	sp(17, 1, 'Initiatives', '/csr/site/property/properties/controls/InitiativesPanel.js', 'Controls.InitiativesPanel', 'Credit360.Plugins.InitiativesPlugin', 'This tab lists the initiatives associated with the property. It supports creating, exporting, importing the intiatives from within the tab.', '/csr/shared/plugins/screenshots/property_tab_initiatives.png', '');
	sp(18, 10, 'Supplier list', '/csr/site/chain/managecompany/controls/SupplierListTab.js', 'Chain.ManageCompany.SupplierListTab', 'Credit360.Chain.Plugins.SupplierListDto', 'This tab shows the suppliers of the company being viewed as a list, and allows drill down to view the company management page for the chosen supplier.', '/csr/shared/plugins/screenshots/company_tab_suppliers.png', '');
	sp(19, 10, 'Activity Summary', '/csr/site/chain/managecompany/controls/ActivitySummaryTab.js', 'Chain.ManageCompany.ActivitySummaryTab', 'Credit360.Chain.CompanyManagement.ActivitySummaryTab', 'This tab displays a summary of upcoming/overdue activities for a supplier, that required the logged in user to set the outcome of.', '/csr/shared/plugins/screenshots/company_tab_activity_summary.png', '');
	sp(20, 10, 'Activity List', '/csr/site/chain/managecompany/controls/ActivityListTab.js', 'Chain.ManageCompany.ActivityListTab', 'Credit360.Chain.CompanyManagement.ActivityListTab', 'This tab displays a filterable/searchable table of all activities raised against the supplier being viewed, that the logged in user has permission to see.', '/csr/shared/plugins/screenshots/company_tab_activity_list.png', '');
	sp(21, 11, 'Score header for company management page', '/csr/site/chain/managecompany/controls/ScoreHeader.js', 'Chain.ManageCompany.ScoreHeader', 'Credit360.Chain.Plugins.ScoreHeaderDto', 'This header shows any survey scores for the supplier, and allows the user to set the score if it has been configured to allow manual editing (via /csr/site/quicksurvey/admin/thresholds/list.acds).', '/csr/shared/plugins/screenshots/company_header_scores.png', '');
	sp(22, 10, 'Activity Calendar', '/csr/site/chain/managecompany/controls/CalendarTab.js', 'Chain.ManageCompany.CalendarTab', 'Credit360.Chain.CompanyManagement.CalendarTab', 'This tab displays a calendar that can show activities relating to the supplier being viewed.', '/csr/shared/plugins/screenshots/company_tab_calendar.png', '');
	sp(23, 12, 'Audits', '/csr/shared/calendar/includes/audits.js', 'Credit360.Calendars.Audits', 'Credit360.Audit.AuditCalendarDto', '', '', '');
	sp(24, 12, 'Events', '/csr/shared/calendar/includes/initiatives.js', 'Credit360.Calendars.Initiatives', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(25, 12, 'Issues coming due', '/csr/shared/calendar/includes/issues.js', 'Credit360.Calendars.Issues', 'Credit360.Issues.IssueCalendarDto', '', '', '');
	sp(26, 12, 'Teamroom events', '/csr/shared/calendar/includes/teamrooms.js', 'Credit360.Calendars.Teamrooms', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(27, 12, 'Activities', '/csr/shared/calendar/includes/activities.js', 'Credit360.Calendars.Activities', 'Credit360.Chain.Activities.ActivityCalendarDto', '', '', '');
	sp(28, 12, 'Teamroom actions', '/csr/site/teamroom/controls/calendar/issues.js', 'Teamroom.Calendars.Issues', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(29, 12, 'Actions', '/csr/site/initiatives/calendar/issues.js', 'Credit360.Initiatives.Calendars.Issues', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(30, 11, 'Company management indicators', '/csr/site/chain/managecompany/controls/IndicatorsHeader.js', 'Chain.ManageCompany.IndicatorsHeader', 'Credit360.Chain.Plugins.ChainIndicatorPluginDto', 'This plugin gives the ability to show some indicator values associated with the company in the header panel.', '', '');
	sp(31, 1, 'Portlets', '/csr/site/property/properties/controls/PortalTab.js', 'Controls.PortalTab', 'Credit360.Property.Plugins.PortalDto', 'This tab shows any portlets configured for regions (via /csr/site/portal/Region.acds), setting the region context for the portlets to be that of the property. Each tab configured shows as a separate tab in the property page.', '', '');
	sp(32, 10, 'Product types', '/csr/site/chain/managecompany/controls/ProductTypesTab.js', 'Chain.ManageCompany.ProductTypesTab', 'Credit360.Chain.CompanyManagement.ProductTypesTab', 'This tab shows the product types that a supplier supplies, and providing the user has the write capability for products, it will also let the user edit the list.', '/csr/shared/plugins/screenshots/company_tab_product_types.png', '');
	sp(33, 14, 'Full audit details header', '/csr/site/audit/controls/FullAuditHeader.js', 'Audit.Controls.FullAuditHeader', 'Credit360.Audit.Plugins.FullAuditHeader', 'This header gives the original view of an audit, showing the audit region and date, auditor organisation, audit type, workflow status, closure results, audit notes and a link to the audit survey.', '/csr/shared/plugins/screenshots/audit_header_full_details.png', '');
	sp(34, 1, 'Chemicals Inventory', '/csr/site/property/properties/controls/ChemicalInventoryTab.js', 'Controls.ChemicalInventoryTab', 'Credit360.Plugins.PluginDto', 'This tab shows a list chemicals associated with the property.', '', '');
	sp(35, 10, 'Actions', '/csr/site/chain/manageCompany/controls/IssuesPanel.js', 'Chain.ManageCompany.IssuesPanel', 'Credit360.Plugins.PluginDto', '', '/csr/shared/plugins/screenshots/company_tab_issues.png', '');
	sp(36, 10, 'Delegations', '/csr/site/chain/manageCompany/controls/DelegationPanel.js', 'Chain.ManageCompany.DelegationPanel', 'Credit360.Chain.Plugins.DelegationDto', '', '/csr/shared/plugins/screenshots/company_tab_delegations.png', '');
	sp(37, 10, 'Questionnaires', '/csr/site/chain/manageCompany/controls/QuestionnaireList.js', 'Chain.ManageCompany.QuestionnaireList', 'Credit360.Chain.Plugins.QuestionnaireListDto', '', '/csr/shared/plugins/screenshots/company_tab_questionnaires.png', '');
	sp(38, 10, 'Supplier Audits', '/csr/site/chain/manageCompany/controls/SupplierAuditList.js', 'Chain.ManageCompany.SupplierAuditList', 'Credit360.Chain.Plugins.SupplierAuditListDto', '', '/csr/shared/plugins/screenshots/company_tab_supplier_audits.png', '');
	sp(39, 10, 'Data Collection', '/csr/site/chain/manageCompany/controls/DataCollection.js', 'Chain.ManageCompany.DataCollection', 'Credit360.Chain.Plugins.DataCollectionDto', 'Shows delegations, questionnaires and supplier audits on a single tab', '/csr/shared/plugins/screenshots/company_tab_data_collection.png', '');
	sp(40, 10, 'Messages', '/csr/site/chain/manageCompany/controls/MessagesTab.js', 'Chain.ManageCompany.MessagesTab', 'Credit360.Plugins.PluginDto', '', '/csr/shared/plugins/screenshots/company_tab_messages.png', '');
	sp(41, 10, 'Portlets', '/csr/site/chain/manageCompany/controls/PortalTab.js', 'Chain.ManageCompany.PortalTab', 'Credit360.Chain.Plugins.PortalDto', 'This tab shows any portlets configured for regions (via /csr/site/portal/Region.acds), setting the region context for the portlets to be that of the company. Each tab configured shows as a separate tab in the company management page.', '', '');
	sp(42, 1, 'Enhesa Regulatory Monitoring', '/csr/site/property/properties/controls/EnhesaTopicsTab.js', 'Controls.EnhesaTopicsTab', 'Credit360.Property.Plugins.EnhesaTopicsTab', 'This tab shows a list of Enhesa Regulatory Monitoring topics for a property.', '/csr/shared/plugins/screenshots/property_tab_enhesa_topics.png', '');
	sp(43, 10, 'Subsidiaries', '/csr/site/chain/manageCompany/controls/SubsidiaryTab.js', 'Chain.ManageCompany.SubsidiaryTab', 'Credit360.Chain.Plugins.SubsidiaryDto', 'This tab shows the subsidiaries of the selected company, and given the correct permissions, will allow adding new subsidiaries.', '', '');
	sp(44, 10, 'Supply Chain Graph', '/csr/site/chain/manageCompany/controls/CompaniesGraph.js', 'Chain.ManageCompany.CompaniesGraph', 'Credit360.Chain.Plugins.CompaniesGraphDto', 'This tab shows a graph of the supply chain for the selected company.', '', '');
	sp(45, 10, 'Company users', '/csr/site/chain/manageCompany/controls/CompanyUsers.js', 'Chain.ManageCompany.CompanyUsers', 'Credit360.Chain.Plugins.CompanyUsersDto', 'This tab shows the users of the selected company, and given the correct permissions, will allow updateding / adding new users.', '', '');
	sp(46, 10, 'Company details', '/csr/site/chain/manageCompany/controls/CompanyDetails.js', 'Chain.ManageCompany.CompanyDetails', 'Credit360.Chain.Plugins.CompanyDetailsDto', 'This tab allows editing of the core company details such as address.', '', '');
	sp(47, 10, 'Relationships', '/csr/site/chain/manageCompany/controls/RelationshipsTab.js', 'Chain.ManageCompany.RelationshipsTab', 'Credit360.Chain.Plugins.RelationshipsTabDto', 'This tab allows adding/removing relationships to a company.', '', '');
	sp(48, 10, 'Business Relationships', '/csr/site/chain/manageCompany/controls/BusinessRelationships.js', 'Chain.ManageCompany.BusinessRelationships', 'Credit360.Chain.Plugins.BusinessRelationshipsDto', 'This tab shows the business relationships for a company.', '', '');
	sp(49, 10, 'My Details', '/csr/site/chain/manageCompany/controls/MyDetailsTab.js', 'Chain.ManageCompany.MyDetailsTab', 'Credit360.Chain.Plugins.MyDetailsDto', 'This tab allows a user to maintain their personal details. This tab would normally only be used when looking at your own company.', '', '');
	sp(50, 13, 'Findings', '/csr/site/audit/controls/FindingTab.js', 'Audit.Controls.FindingTab', 'Credit360.Audit.Plugins.FindingTab', 'Findings', '', '');
	sp(51, 13, 'Finding score summary', '/csr/site/audit/controls/NcScoreSummaryTab.js', 'Audit.Controls.NcScoreSummaryTab', 'Credit360.Audit.Plugins.NcScoreSummaryTab', 'Summarises the findings score for the audit, broken down by finding type', '', '');
	sp(52, 13, 'Documents', '/csr/site/audit/controls/DocumentsTab.js', 'Audit.Controls.Documents', 'Credit360.Audit.Plugins.FullAuditTab', 'Documents', '', '');
	sp(53, 13, 'Executive Summary', '/csr/site/audit/controls/ExecutiveSummaryTab.js', 'Audit.Controls.ExecutiveSummary', 'Credit360.Audit.Plugins.FullAuditTab', 'Executive Summary', '', '');
	sp(54, 13, 'Audit Log', '/csr/site/audit/controls/AuditLogTab.js', 'Audit.Controls.AuditLog', 'Credit360.Audit.Plugins.FullAuditTab', 'Audit Log', '', '');
	sp(55, 13, 'Full audit details tab', '/csr/site/audit/controls/FullAuditTab.js', 'Audit.Controls.FullAuditTab', 'Credit360.Audit.Plugins.FullAuditTab', 'This tab gives the original view of an audit, showing the executive summary, audit documents and non-compliances each in its own section.', '/csr/shared/plugins/screenshots/audit_tab_full_details.png', '');
	sp(56, 12, 'Course schedules', '/csr/shared/calendar/includes/training.js', 'Credit360.Calendars.Training', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(57, 1, 'Portlets', '/csr/site/property/properties/controls/PortalTab.js', 'Portlets', 'Credit360.Property.Plugins.PortalDto', '', '', '');
	sp(58, 6, 'Settings', '/csr/site/teamroom/controls/edit/SettingsPanel.js', 'MarksAndSpencer.Teamroom.Edit.SettingsPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(59, 7, 'Settings', '/csr/site/teamroom/controls/mainTab/SettingsPanel.js', 'MarksAndSpencer.Teamroom.MainTab.SettingsPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(60, 1, 'Meter Raw Data', '/csr/site/property/properties/controls/MeterRawDataTab.js', 'Controls.MeterRawDataTab', 'Credit360.Plugins.PluginDto', 'This tab shows raw data for real time metering.', '', '');
	sp(61, 8, 'Audit Log', '/csr/site/initiatives/detail/controls/AuditLogPanel.js', 'Credit360.Initiatives.AuditLogPanel', 'Credit360.Plugins.PluginDto', 'Audit Log', '', '');
	sp(62, 13, 'Finding List', '/csr/site/audit/controls/NonComplianceListTab.js', 'Audit.Controls.NonComplianceListTab', 'Credit360.Audit.Plugins.NonComplianceList', 'This tab shows a filterable list of findings.', '', '');
	sp(63, 13, 'Survey List', '/csr/site/audit/controls/SurveysTab.js', 'Audit.Controls.SurveysTab', 'Credit360.Audit.Plugins.SurveysTab', 'This tab shows a list of surveys against an audit.  It is intended for customers who have purchased the "multiple audit surveys" feature.', '', '');
	sp(64, 1, 'Meter data quick chart', '/csr/site/meter/controls/meterListTab.js', 'Credit360.Metering.MeterListTab', 'Credit360.Metering.Plugins.MeterList', 'Quick Charts tab for meter data', '/csr/shared/plugins/screenshots/property_tab_meter_list.png', '');
	sp(65, 15, 'Validation report', '/csr/site/rreports/reports/Validation.js', 'Credit360.RReports.Validation', 'Credit360.RReports.Runners.ValidationReportRunner', '', '', '/csr/rreports/validation_V5/validation_V5.R');
	sp(66, 16, 'Raw meter data', '/csr/site/meter/controls/meterRawDataTab.js', 'Credit360.Metering.MeterRawDataTab', 'Credit360.Metering.Plugins.MeterRawData', 'Display, filter, search, and export raw readings for the meter.', '/csr/shared/plugins/screenshots/meter_raw_data.png', '');
	sp(67, 16, 'Meter data quick chart', '/csr/site/meter/controls/meterListTab.js', 'Credit360.Metering.MeterQuickChartTab', 'Credit360.Metering.Plugins.MeterQuickChartTab', 'Display data for the meter in a calendar view, chart, list, or pivot table.', '/csr/shared/plugins/screenshots/property_tab_meter_list.png', '');
	sp(68, 16, 'Meter audit log', '/csr/site/meter/controls/AuditLogTab.js', 'Credit360.Metering.AuditLogTab', 'Credit360.Metering.Plugins.AuditLogTab', 'Log changes to the meter region and any patches made to the meter data.', '/csr/shared/plugins/screenshots/meter_audit_log_tab.png', '');
	sp(69, 16, 'Actions tab', '/csr/site/meter/controls/IssuesTab.js', 'Credit360.Metering.IssuesTab', 'Credit360.Plugins.PluginDto', 'Show all actions associated with the meter, and raise new actions.', '/csr/shared/plugins/screenshots/meter_issue_list_tab.png', '');
	sp(70, 16, 'Hi-res chart', '/csr/site/meter/controls/meterHiResChartTab.js', 'Credit360.Metering.MeterHiResChartTab', 'Credit360.Metering.Plugins.MeterHiResChart', 'Display a detailed interactive chart showing all inputs for the meter, and patch data for the meter.', '/csr/shared/plugins/screenshots/meter_hi_res_chart.png', '');
	sp(71, 16, 'Low-res chart', '/csr/site/meter/controls/meterLowResChartTab.js', 'Credit360.Metering.MeterLowResChartTab', 'Credit360.Metering.Plugins.MeterLowResChart', 'Display a simple chart showing total and average consumption for the lifetime of the meter.', '/csr/shared/plugins/screenshots/meter_low_res_chart.png', '');
	sp(72, 16, 'Readings', '/csr/site/meter/controls/meterReadingTab.js', 'Credit360.Metering.MeterReadingTab', 'Credit360.Metering.Plugins.MeterReading', 'Enter readings and check percentage tolerances.', '/csr/shared/plugins/screenshots/meter_readings.png', '');
	sp(73, 16, 'Meter Characteristics', '/csr/site/meter/controls/meterCharacteristicsTab.js', 'Credit360.Metering.MeterCharacteristicsTab', 'Credit360.Metering.Plugins.MeterCharacteristics', 'Edit meter data.', '', '');
	sp(74, 17, 'Emissions profiles', '/csr/site/admin/emissionFactors/controls/EmissionProfilesTab.js', 'Controls.EmissionProfilesTab', 'Credit360.Plugins.PluginDto', 'This tab will hold the options to manage emission factor profiles.', '', '');
	sp(75, 17, 'Map indicators', '/csr/site/admin/emissionFactors/controls/MapIndicatorsTab.js', 'Credit360.EmissionFactors.MapIndicatorsTab', 'Credit360.Plugins.PluginDto', 'This tab will hold the options to manage the emission factor indicator mappings.', '', '');
	sp(76, 8, 'Initiative details - What', '/csr/site/initiatives/detail/controls/WhatPanel.js', 'Credit360.Initiatives.Plugins.WhatPanel', 'Credit360.Plugins.PluginDto', 'Contains core details about the initiative, including the name, reference, project type and description.', '/csr/shared/plugins/screenshots/initiative_tab_what.png', '');
	sp(77, 8, 'Initiative details - Where', '/csr/site/initiatives/detail/controls/WherePanel.js', 'Credit360.Initiatives.Plugins.WherePanel', 'Credit360.Plugins.PluginDto', 'Contains location information about the initiative, i.e. the regions the initiative will apply to.', '/csr/shared/plugins/screenshots/initiative_tab_where.png', '');
	sp(78, 8, 'Initiative details - When', '/csr/site/initiatives/detail/controls/WhenPanel.js', 'Credit360.Initiatives.Plugins.WhenPanel', 'Credit360.Plugins.PluginDto', 'Contains timing information about when the initiative will run.', '/csr/shared/plugins/screenshots/initiative_tab_when.png', '');
	sp(79, 8, 'Initiative details - Why', '/csr/site/initiatives/detail/controls/WhyPanel.js', 'Credit360.Initiatives.Plugins.WhyPanel', 'Credit360.Plugins.PluginDto', 'Contains metrics about the initiative.', '/csr/shared/plugins/screenshots/initiative_tab_why.png', '');
	sp(80, 8, 'Initiative details - Who', '/csr/site/initiatives/detail/controls/WhoPanel.js', 'Credit360.Initiatives.Plugins.WhoPanel', 'Credit360.Plugins.PluginDto', 'Contains details of who is involved with the initiative.', '/csr/shared/plugins/screenshots/initiative_tab_who.png', '');
	sp(81, 8, 'Initiative details', '/csr/site/initiatives/detail/controls/InitiativeDetailsPanel.js', 'Credit360.Initiatives.Plugins.InitiativeDetailsPanel', 'Credit360.Plugins.PluginDto', 'Contains all the details of the initiative in one tab (use this instead of the individual what, where, when, why, who tabs).', '/csr/shared/plugins/screenshots/initiative_tab_initiative_details.png', '');
	sp(82, 10, 'Supplier followers', '/csr/site/chain/manageCompany/controls/SupplierFollowersTab.js', 'Chain.ManageCompany.SupplierFollowersTab', 'Credit360.Chain.Plugins.SupplierFollowersDto', 'This tab shows the followers of the selected company, and given the correct permissions, will allow adding/removing followers.', '', '');
END;
/


 -- Data
BEGIN
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'usingAdvancedFilter', 'BOOLEAN', 'Using advanced filter');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'includeFinalState', 'BOOLEAN', 'Advanced filter setting - Whether to include final state dashboards');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'groupedBy', 'STRING', 'What the dashboards are grouped by');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'textSearch', 'STRING', 'Advanced filter setting - Text search');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'startDtm', 'STRING', 'Advanced filter setting - Exclude dashboards before');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'endDtm', 'STRING', 'Advanced filter setting - Exclude dashboards after');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'actionState', 'NUMBER', 'Advanced filter setting - The action state selection');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'workflowState', 'STRING', 'Advanced filter setting - Workflow state to filter to');
	INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) 
	VALUES (1060,'My approval dashboards filter','Credit360.Portlets.ApprovalDashboardFilter', EMPTY_CLOB(),'/csr/site/portal/portlets/ApprovalDashboardFilter.js');
END;
/


INSERT INTO csr.audit_type ( audit_type_group_id, audit_type_id, label ) 
VALUES (1, 120, 'Module enabled');
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning, warning_msg)
VALUES (84, 'Properties - base', 'EnableProperties', 'Enables the Properties module. Cannot be undone. To manage a property, add a user to Property Manager role after enabling.', 1, 'This enables parts of the supply chain system and cannot be undone.');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (84, 'in_company_name', 0, 'Provide name of top level company if chain is not already enabled');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (84, 'in_property_type', 1, 'Enter default property type (existing properties will be assigned this type)');
INSERT INTO csr.util_script (util_script_id,util_script_name,description,util_script_sp,wiki_article) 
VALUES (24, 'Add Missing Properties', 'Add properties from the region tree which are missing in the Properties module list. (Needed if Properties was enabled prior to October 2016.)', 'AddMissingProperties', NULL);
INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos) 
VALUES (24, 'Property type','Enter default property type (if type does not exist, it will be created)',0);
UPDATE csr.module SET Module_name = 'Properties - dashboards' WHERE module_id = 64;
BEGIN
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (46, 'in_setup_base_data', 'Create default initiative module projects, metrics and metric groups? (y|n default=n)', 0);
EXCEPTION
	WHEN dup_val_on_index THEN
		NULL;
END;
/
DECLARE
	v_reminder_alert_type_id	NUMBER := 60;
	v_overdue_alert_type_id		NUMBER := 61;
BEGIN
	FOR r IN (
		SELECT c.app_sid
		  FROM csr.customer c
	) LOOP
		BEGIN
			INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (r.app_sid, csr.customer_alert_type_id_seq.nextval, v_reminder_alert_type_id);
			
			INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (r.app_sid, csr.customer_alert_type_id_seq.nextval, v_overdue_alert_type_id);
			INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			SELECT r.app_sid, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'manual'
			  FROM csr.alert_frame af
			  JOIN csr.customer_alert_type cat ON af.app_sid = cat.app_sid
			 WHERE af.app_sid = r.app_sid
			   AND cat.std_alert_type_id IN (v_reminder_alert_type_id, v_overdue_alert_type_id)
			 GROUP BY cat.customer_alert_type_id
			HAVING MIN(af.alert_frame_id) > 0;			
			
			INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			SELECT r.app_sid, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
			  FROM csr.default_alert_template_body d
			  JOIN csr.customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
			  JOIN csr.alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
			  CROSS JOIN aspen2.translation_set t
			 WHERE d.std_alert_type_id IN (v_reminder_alert_type_id, v_overdue_alert_type_id)
			   AND d.lang='en'
			   AND t.application_sid = r.app_sid
			   AND cat.app_sid = r.app_sid;
		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		END;
	END LOOP;
END;
/
BEGIN
	UPDATE csr.auto_exp_exporter_plugin
	   SET outputter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DsvOutputter'
	 WHERE plugin_id = 1;
END;
/
BEGIN
	security.user_pkg.logonadmin;
	UPDATE chain.filter_value fv
	   SET end_dtm_value = end_dtm_value + 1
	 WHERE num_value = -1
	   AND end_dtm_value IS NOT NULL
	   AND EXISTS(SELECT * 
				    FROM chain.filter_field ff
				   WHERE fv.filter_field_id = ff.filter_field_id
					 AND ff.show_all = 0);
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (23,'Create custom delegation layout','Creates delegation layout and assigns it to given delegation sid','CreateCustomDelegLayout','W1698');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS) VALUES (23, 'Delegation SID','SID of the delegation to set layout to',0);
INSERT INTO csr.auto_imp_mapping_type (mapping_type_id, name) VALUES (0, 'Sid');
INSERT INTO csr.auto_imp_mapping_type (mapping_type_id, name) VALUES (1, 'Lookup key');
INSERT INTO csr.auto_imp_mapping_type (mapping_type_id, name) VALUES (2, 'Mapping table');
INSERT INTO csr.auto_imp_mapping_type (mapping_type_id, name) VALUES (3, 'Description');
INSERT INTO csr.auto_imp_date_type (date_type_id, name) VALUES (0, 'One col, one date');
INSERT INTO csr.auto_imp_date_type (date_type_id, name) VALUES (1, 'One col, two dates');
INSERT INTO csr.auto_imp_date_type (date_type_id, name) VALUES (2, 'Two cols, one date');
INSERT INTO csr.auto_imp_date_type (date_type_id, name) VALUES (3, 'Two cols, two dates');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (0, 'Year, eg 15 or 2015');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (1, 'Month name, eg Aug or August');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (2, 'Month index');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (3, 'Financial year, eg FY15 or FY2015');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (4, 'Date string, eg .net parsable');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (5, 'App year, eg 15 or 2015');
INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (6, 'Month and year, eg Aug 2015, August 2015 (or with 15)');
INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly) VALUES (4, 'Core data importer', 'Credit360.ExportImport.Automated.Import.Importers.CoreDataImporter.CoreDataImporter');
DECLARE
	v_has_measure	NUMBER:=0;
BEGIN
	SELECT COUNT(*)
	  INTO v_has_measure
	  FROM csr.std_measure
	 WHERE std_measure_id = 42;
	 
	IF v_has_measure > 0 THEN
		GOTO has_measure;
	END IF;
	
	INSERT INTO csr.std_measure (
		std_measure_id, name, description, scale, format_mask, regional_aggregation, custom_field, pct_ownership_applies, m, kg, s, a, k, mol, cd
	) VALUES (
		42, 's^2/m^5', 's^2/m^5', 0, '#,##0', 'sum', NULL, 0, -5, 0, 2, 0, 0, 0, 0
	);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28206, 18, 'GJ/m^2', 0.000000001, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28207, 24, 'GJ/(m^3.PJ)', 1000000, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28208, 42, 'kg/(m^3.PJ)', 1000000000000000, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28209, 24, 'kWh/(m^3.PJ)', 277777777.78, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28210, 35, 'm^3/day', 86400, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28211, 35, 'MGal (UK)/day', 19.005335, 1, 0, 1);
	INSERT INTO csr.std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c, divisible) VALUES (28212, 35, 'MGal (US)/day', 22.824465, 1, 0, 1);
	
	<<has_measure>>
	NULL;
END;
/
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (19,'Set CDN Server','Sets the domain of the CDN server. A CDN provides static content to users from a server closer to their location. Dynamic content such as data will still come from our servers.','SetCDNServer',null);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS) VALUES (19, 'CDN Server name','Domain of the CDN server',0);
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (20,'Remove CDN Server','Removes the CDN server so that all content comes from the site directly','RemoveCDNServer',null);
END;
/






@..\scenario_run_pkg
@..\plugin_pkg
@..\delegation_pkg
@..\audit_pkg
@..\csr_data_pkg
@..\enable_pkg
@..\benchmarking_dashboard_pkg
@..\metric_dashboard_pkg
@..\util_script_pkg
@..\..\..\aspen2\cms\db\export_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\flow_pkg
@..\automated_export_pkg
@..\chain\company_pkg
@..\chain\filter_pkg
@..\dataview_pkg
@..\approval_dashboard_pkg
@..\schema_pkg
@..\csrimp\imp_pkg
@..\region_pkg
@..\automated_import_pkg
@..\customer_pkg


@..\enable_body
@..\factor_body
@..\scenario_run_body
@..\plugin_body
@..\delegation_body
@..\sheet_body
@..\property_body
@..\meter_body
@..\initiative_body
@..\audit_body
@..\schema_body
@..\chain\plugin_body
@..\csrimp\imp_body
@..\csr_app_body
@..\region_body
@..\benchmarking_dashboard_body
@..\metric_dashboard_body
@..\util_script_body
@..\property_report_body
@..\..\..\aspen2\cms\db\export_body
@..\..\..\aspen2\cms\db\tab_body
@..\..\..\aspen2\cms\db\form_body
@..\flow_body
@..\issue_body
@..\automated_export_body
@..\energy_star_job_body
@..\chain\company_body
@..\chain\filter_body
@..\audit_report_body
@..\initiative_report_body
@..\issue_report_body
@..\meter_report_body
@..\non_compliance_report_body
@..\user_report_body
@..\..\..\aspen2\cms\db\filter_body
@..\compliance_body
@..\comp_regulation_report_body
@..\meter_list_body
@..\region_metric_body
@..\dataview_body
@..\meter_monitor_body
@..\chain\higg_setup_body
@..\approval_dashboard_body
 
@..\saml_body
@..\factor_set_group_body
@..\chain\message_body
@..\energy_star_job_data_body
@..\indicator_body
@..\measure_body
@..\automated_import_body
@..\..\..\aspen2\db\aspenapp_body
@..\customer_body
@..\csr_data_body



@update_tail
