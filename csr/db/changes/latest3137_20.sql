-- Please update version.sql too -- this keeps clean builds in sync
define version=3137
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.AUTO_EXP_EXPORTER_PLUGIN_TYPE(
	PLUGIN_TYPE_ID	NUMBER NOT NULL,
	LABEL			VARCHAR2(255),
	CONSTRAINT PK_AEEPT_PLUGIN_TYPE_ID PRIMARY KEY (PLUGIN_TYPE_ID),
	CONSTRAINT UK_AEEPT_PLUGIN_LABEL UNIQUE (LABEL)
);
INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (1, 'DataView Exporter');
INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (2, 'DataView Exporter (Xml Mappable)');
INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (3, 'Batched Exporter');
INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (4, 'Stored Procedure Exporter');

CREATE TABLE CSR.AUTO_EXP_FILE_WRTR_PLUGIN_TYPE(
	PLUGIN_TYPE_ID	NUMBER NOT NULL,
	LABEL			VARCHAR2(255),
	CONSTRAINT PK_AEFWPT_PLUGIN_TYPE_ID PRIMARY KEY (PLUGIN_TYPE_ID),
	CONSTRAINT UK_AEFWPT_PLUGIN_LABEL UNIQUE (LABEL)
);
INSERT INTO csr.auto_exp_file_wrtr_plugin_type(plugin_type_id, label) VALUES (1, 'FTP');
INSERT INTO csr.auto_exp_file_wrtr_plugin_type(plugin_type_id, label) VALUES (2, 'DB');
INSERT INTO csr.auto_exp_file_wrtr_plugin_type(plugin_type_id, label) VALUES (3, 'Manual Download');



-- Alter tables
ALTER TABLE CSR.AUTO_EXP_EXPORTER_PLUGIN ADD
	DSV_OUTPUTTER			NUMBER(1)		DEFAULT 0 NOT NULL;
ALTER TABLE CSR.AUTO_EXP_EXPORTER_PLUGIN ADD
	PLUGIN_TYPE_ID	NUMBER;

ALTER TABLE CSR.AUTO_EXP_EXPORTER_PLUGIN ADD
	CONSTRAINT CK_AUTO_EXP_EXPORTER_DSV_OUTP CHECK (DSV_OUTPUTTER IN (0, 1));
	
ALTER TABLE CSR.AUTO_EXP_EXPORTER_PLUGIN ADD
	CONSTRAINT FK_AEE_PLUGIN_TYPE_ID
		FOREIGN KEY (PLUGIN_TYPE_ID)
		REFERENCES CSR.AUTO_EXP_EXPORTER_PLUGIN_TYPE (PLUGIN_TYPE_ID);


ALTER TABLE CSR.AUTO_EXP_FILE_WRITER_PLUGIN ADD
	PLUGIN_TYPE_ID	NUMBER		DEFAULT 1	NOT NULL;

ALTER TABLE CSR.AUTO_EXP_FILE_WRITER_PLUGIN ADD
	CONSTRAINT FK_AEFWP_PLUGIN_TYPE_ID
		FOREIGN KEY (PLUGIN_TYPE_ID)
		REFERENCES CSR.AUTO_EXP_FILE_WRTR_PLUGIN_TYPE (PLUGIN_TYPE_ID);

ALTER TABLE CSR.AUTO_EXP_FILE_WRITER_PLUGIN MODIFY PLUGIN_TYPE_ID DEFAULT NULL;

create index csr.ix_auto_exp_expo_plugin_type_i on csr.auto_exp_exporter_plugin (plugin_type_id);
create index csr.ix_auto_exp_file_plugin_type_i on csr.auto_exp_file_writer_plugin (plugin_type_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE CSR.AUTO_EXP_EXPORTER_PLUGIN
   SET DSV_OUTPUTTER = 1
 WHERE PLUGIN_ID IN (1, 2, 3, 4, 5, 6, 7, 13, 14, 15, 17, 19, 21, 22);

UPDATE CSR.AUTO_EXP_EXPORTER_PLUGIN
   SET PLUGIN_TYPE_ID = 1
 WHERE PLUGIN_ID IN (1, 2, 3);
UPDATE CSR.AUTO_EXP_EXPORTER_PLUGIN
   SET PLUGIN_TYPE_ID = 2
 WHERE PLUGIN_ID IN (21, 22);
UPDATE CSR.AUTO_EXP_EXPORTER_PLUGIN
   SET PLUGIN_TYPE_ID = 3
 WHERE PLUGIN_ID IN (19);
UPDATE CSR.AUTO_EXP_EXPORTER_PLUGIN
   SET PLUGIN_TYPE_ID = 4
 WHERE PLUGIN_ID IN (13);

UPDATE CSR.AUTO_EXP_FILE_WRITER_PLUGIN
   SET PLUGIN_TYPE_ID = 1
 WHERE PLUGIN_ID IN (1, 7);

UPDATE CSR.AUTO_EXP_FILE_WRITER_PLUGIN
   SET PLUGIN_TYPE_ID = 2
 WHERE PLUGIN_ID = 6;

UPDATE CSR.AUTO_EXP_FILE_WRITER_PLUGIN
   SET PLUGIN_TYPE_ID = 3
 WHERE PLUGIN_ID = 5;


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_pkg
@../automated_export_body

@update_tail
