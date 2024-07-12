-- Please update version.sql too -- this keeps clean builds in sync
define version=427
@update_header

CREATE SEQUENCE csr.model_range_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 5
	NOORDER;

CREATE SEQUENCE csr.model_sheet_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 5
	NOORDER;
	
ALTER TABLE csr.model_sheet ADD sheet_id NUMBER(10, 0);

UPDATE csr.model_sheet SET sheet_id = csr.model_sheet_id_seq.NEXTVAL;

ALTER TABLE csr.model_sheet ADD CHECK (sheet_id IS NOT NULL);

CREATE TABLE csr.model_range
(
	app_sid		NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	model_sid	NUMBER(10, 0) NOT NULL,
	range_id	NUMBER(10, 0) NOT NULL,
	sheet_id	NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_model_range PRIMARY KEY (app_sid, model_sid, range_id),
	CONSTRAINT uk_model_range UNIQUE (range_id)
);

CREATE TABLE csr.model_range_cell
(
	app_sid		NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	model_sid	NUMBER(10, 0) NOT NULL,
	range_id	NUMBER(10, 0) NOT NULL,
	cell_name	VARCHAR2(20) NOT NULL,
	CONSTRAINT pk_model_range_cell PRIMARY KEY (app_sid, model_sid, range_id, cell_name)
);

CREATE TABLE csr.model_region_range
(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	model_sid				NUMBER(10, 0) NOT NULL,
	range_id				NUMBER(10, 0) NOT NULL,
	region_repeat_id		NUMBER(10, 0) DEFAULT 1 NOT NULL,
	CONSTRAINT pk_model_region_range PRIMARY KEY (app_sid, model_sid, range_id),
	CONSTRAINT ck_mrr_rri CHECK (region_repeat_id >= 1 AND region_repeat_id <= 4)
);

CREATE TABLE csr.model_instance_region
(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	model_instance_sid		NUMBER(10, 0) NOT NULL,
	region_sid				NUMBER(10, 0) NOT NULL,
	pos						NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_model_instance_region PRIMARY KEY (app_sid, model_instance_sid, region_sid)
);

CREATE TABLE csr.model_instance_sheet
(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	model_instance_sid		NUMBER(10, 0) NOT NULL,
	base_model_sid			NUMBER(10, 0) NOT NULL,
	sheet_id				NUMBER(10, 0) NOT NULL,
	structure				XMLTYPE,
	CONSTRAINT pk_model_instance_sheet PRIMARY KEY (app_sid, model_instance_sid, base_model_sid, sheet_id)
);

CREATE TABLE csr.model_instance_map
(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	model_instance_sid		NUMBER(10, 0) NOT NULL,
	base_model_sid			NUMBER(10, 0) NOT NULL,
	sheet_id				NUMBER(10, 0) NOT NULL,
	source_cell_name		VARCHAR2(20) NOT NULL,
	cell_name				VARCHAR2(20) NOT NULL,
	cell_value				VARCHAR2(4000),
	map_to_indicator_sid	NUMBER(10),
	map_to_region_sid		NUMBER(10),
	period_year_offset		NUMBER(10) DEFAULT 0 NOT NULL,
	period_offset			NUMBER(10) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_model_instance_map PRIMARY KEY (app_sid, model_instance_sid, base_model_sid, sheet_id, cell_name)
);

CREATE TABLE csr.model_instance_chart
(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	model_instance_sid		NUMBER(10, 0) NOT NULL,
	base_model_sid			NUMBER(10, 0) NOT NULL,
	sheet_id				NUMBER(10, 0) NOT NULL,
	chart_index				NUMBER(10, 0) NOT NULL,
	top						NUMBER(10, 0) NOT NULL,
	left					NUMBER(10, 0) NOT NULL,
	width					NUMBER(10, 0) NOT NULL,
	height					NUMBER(10, 0) NOT NULL,
	source_data				VARCHAR2(4000),
	CONSTRAINT pk_model_instance_chart PRIMARY KEY (app_sid, model_instance_sid, base_model_sid, sheet_id, chart_index)
);

DECLARE
	v_name VARCHAR2(30);
BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.model_instance_field DROP primary key drop index';
	SELECT constraint_name INTO v_name FROM all_constraints WHERE owner = 'CSR' AND table_name = 'MODEL_INSTANCE' AND r_constraint_name = 'PK_REGION';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.model_instance DROP CONSTRAINT ' || v_name;
	SELECT constraint_name INTO v_name FROM all_cons_columns WHERE owner = 'CSR' AND table_name = 'MODEL_INSTANCE' AND column_name = 'REGION_SID';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.model_instance DROP CONSTRAINT ' || v_name;
	SELECT constraint_name INTO v_name FROM all_constraints WHERE owner = 'CSR' AND table_name = 'MODEL_INSTANCE_FIELD' AND r_constraint_name = 'PK_MODEL_MAP';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.model_instance_field DROP CONSTRAINT ' || v_name;
	SELECT constraint_name INTO v_name FROM all_constraints WHERE owner = 'CSR' AND table_name = 'MODEL_VALIDATION' AND r_constraint_name = 'PK_MODEL_MAP';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.model_validation DROP CONSTRAINT ' || v_name;
	SELECT constraint_name INTO v_name FROM all_constraints WHERE owner = 'CSR' AND table_name = 'MODEL_MAP' AND r_constraint_name = 'PK_MODEL_SHEET';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.model_map DROP CONSTRAINT ' || v_name;
	EXECUTE IMMEDIATE 'ALTER TABLE csr.model_sheet DROP primary key drop index';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.model_validation DROP primary key drop index';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.model_map DROP primary key drop index';
	SELECT constraint_name INTO v_name FROM all_cons_columns WHERE owner = 'CSR' AND table_name = 'MODEL_INSTANCE_FIELD' AND column_name = 'SHEET_NAME';
	EXECUTE IMMEDIATE 'ALTER TABLE csr.model_instance_FIELD DROP CONSTRAINT ' || v_name;
END;
/

ALTER TABLE csr.model_map ADD sheet_id NUMBER(10);
ALTER TABLE csr.model_map ADD region_offset NUMBER(10) DEFAULT 0 NOT NULL;
ALTER TABLE csr.model_map ADD region_offset_tag_id NUMBER(10);
ALTER TABLE csr.model_map ADD period_year_offset NUMBER(10) DEFAULT 0 NOT NULL;
ALTER TABLE csr.model_map ADD period_offset NUMBER(10) DEFAULT 0 NOT NULL;
ALTER TABLE csr.model_validation ADD sheet_id NUMBER(10);
ALTER TABLE csr.model_validation MODIFY validation_text NULL;
ALTER TABLE csr.model_instance_field ADD sheet_id NUMBER(10);

UPDATE csr.model_map
SET sheet_id = (SELECT sheet_id FROM model_sheet WHERE app_sid = model_map.app_sid AND model_sid = model_map.model_sid AND sheet_name = model_map.sheet_name);

UPDATE csr.model_validation
SET sheet_id = (SELECT sheet_id FROM model_sheet WHERE app_sid = model_validation.app_sid AND model_sid = model_validation.model_sid AND sheet_name = model_validation.sheet_name);

UPDATE csr.model_instance_field
SET sheet_id = (SELECT sheet_id FROM model_sheet WHERE app_sid = model_instance_field.app_sid AND model_sid = model_instance_field.base_model_sid AND sheet_name = model_instance_field.sheet_name);

INSERT INTO csr.model_instance_map (app_sid, model_instance_sid, base_model_sid, sheet_id, source_cell_name, cell_name, cell_value)
SELECT app_sid, model_instance_sid, base_model_sid, sheet_id, cell_name, cell_name, cell_value FROM model_instance_field;

ALTER TABLE csr.model_map ADD CONSTRAINT pk_model_map
	PRIMARY KEY (app_sid, model_sid, sheet_id, cell_name);
	
ALTER TABLE csr.model_validation ADD CONSTRAINT pk_model_validation
	PRIMARY KEY (app_sid, model_sid, sheet_id, cell_name, display_seq);
	
ALTER TABLE csr.model_sheet ADD CONSTRAINT pk_model_sheet
	PRIMARY KEY (app_sid, model_sid, sheet_id);

ALTER TABLE csr.model_map ADD CONSTRAINT fk_mm_ms
	FOREIGN KEY (app_sid, model_sid, sheet_id)
	REFERENCES csr.model_sheet (app_sid, model_sid, sheet_id);
	
ALTER TABLE csr.model_validation ADD CONSTRAINT fk_mv_mm
	FOREIGN KEY (app_sid, model_sid, sheet_id, cell_name)
	REFERENCES csr.model_map (app_sid, model_sid, sheet_id, cell_name);

ALTER TABLE csr.model_range ADD CONSTRAINT fk_mr_ms
	FOREIGN KEY (app_sid, model_sid, sheet_id)
	REFERENCES csr.model_sheet (app_sid, model_sid, sheet_id);

ALTER TABLE csr.model_range_cell ADD CONSTRAINT fk_mrc_mr
	FOREIGN KEY (app_sid, model_sid, range_id)
	REFERENCES csr.model_range (app_sid, model_sid, range_id);

ALTER TABLE csr.model_region_range ADD CONSTRAINT fk_mrr_mr
	FOREIGN KEY (app_sid, model_sid, range_id)
	REFERENCES csr.model_range (app_sid, model_sid, range_id);

ALTER TABLE csr.model_instance_region ADD CONSTRAINT fk_mir_mi
	FOREIGN KEY (app_sid, model_instance_sid)
	REFERENCES csr.model_instance (app_sid, model_instance_sid);

ALTER TABLE csr.model_instance_region ADD CONSTRAINT fk_mir_r
	FOREIGN KEY (app_sid, region_sid)
	REFERENCES csr.region (app_sid, region_sid);

ALTER TABLE csr.model_instance_sheet ADD CONSTRAINT fk_mis_mi
	FOREIGN KEY (app_sid, model_instance_sid)
	REFERENCES csr.model_instance (app_sid, model_instance_sid);
	
ALTER TABLE csr.model_instance_sheet ADD CONSTRAINT fk_mis_ms
	FOREIGN KEY (app_sid, base_model_sid, sheet_id)
	REFERENCES csr.model_sheet (app_sid, model_sid, sheet_id);
	
ALTER TABLE csr.model_instance_map ADD CONSTRAINT fk_mim_mi
	FOREIGN KEY (app_sid, model_instance_sid)
	REFERENCES csr.model_instance (app_sid, model_instance_sid);
	
ALTER TABLE csr.model_instance_map ADD CONSTRAINT fk_mim_mm
	FOREIGN KEY (app_sid, base_model_sid, sheet_id, source_cell_name)
	REFERENCES csr.model_map (app_sid, model_sid, sheet_id, cell_name);	
	
ALTER TABLE csr.model_instance_chart ADD CONSTRAINT fk_mic_mi
	FOREIGN KEY (app_sid, model_instance_sid)
	REFERENCES csr.model_instance (app_sid, model_instance_sid);
	
ALTER TABLE csr.model_instance_chart ADD CONSTRAINT fk_mic_ms
	FOREIGN KEY (app_sid, base_model_sid, sheet_id)
	REFERENCES csr.model_sheet (app_sid, model_sid, sheet_id);
	
INSERT INTO csr.model_instance_region
SELECT app_sid, model_instance_sid, region_sid, 0
FROM model_instance;

ALTER TABLE csr.model_instance DROP COLUMN region_sid;

ALTER TABLE csr.model_instance ADD description VARCHAR(1000);

UPDATE csr.model_instance SET (description) =
(
	SELECT STRAGG(region.description)
	FROM csr.region INNER JOIN csr.model_instance_region ON region.region_sid = model_instance_region.region_sid
	WHERE model_instance_region.model_instance_sid = model_instance.model_instance_sid
)
WHERE description IS NULL;

ALTER TABLE csr.model ADD revision NUMBER(10, 0) DEFAULT(0) NOT NULL;
ALTER TABLE csr.model_sheet ADD structure XMLTYPE;
ALTER TABLE csr.model_instance ADD excel_doc BLOB;

ALTER TABLE csr.model_sheet DROP COLUMN run_html;
ALTER TABLE csr.model_sheet DROP COLUMN edit_html;
ALTER TABLE csr.model DROP COLUMN active_sheet_name;

ALTER TABLE csr.model_map DROP COLUMN sheet_name;
ALTER TABLE csr.model_validation DROP COLUMN sheet_name;

ALTER TABLE csr.model RENAME COLUMN filename TO file_name;

DROP TABLE csr.model_instance_field;

CREATE GLOBAL TEMPORARY TABLE csr.model_temp_map
(
	model_instance_sid	NUMBER(10, 0) NOT NULL,
	sheet_id			NUMBER(10, 0) NOT NULL,
	source_cell_name	VARCHAR2(20) NOT NULL,
	cell_name			VARCHAR2(20) NOT NULL,
	cell_value			VARCHAR2(4000)
)
ON COMMIT DELETE ROWS;

INSERT INTO csr.model_map_type (model_map_type_id, map_type) VALUES (6, 'Region name');

@..\model_pkg.sql
@..\model_body.sql

@update_tail
