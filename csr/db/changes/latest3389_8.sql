-- Please update version.sql too -- this keeps clean builds in sync
define version=3389
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.EXCEL_EXPORT_OPTIONS_TAG_GROUP(
	APP_SID			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP'),
	DATAVIEW_SID	NUMBER(10, 0)	NOT NULL,
	APPLIES_TO		NUMBER			NOT NULL,
	TAG_GROUP_ID	NUMBER			NOT NULL,
	CONSTRAINT PK_EXCEL_EXPORT_OPTIONS_TG PRIMARY KEY (APP_SID, DATAVIEW_SID, APPLIES_TO, TAG_GROUP_ID),
	CONSTRAINT CHK_EXCEL_EXPORT_OPTIONS_AT CHECK (APPLIES_TO IN (1,2))
)
;

CREATE TABLE CSRIMP.EXCEL_EXPORT_OPTIONS_TAG_GROUP(
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DATAVIEW_SID				NUMBER(10, 0)	NOT NULL,
	APPLIES_TO					NUMBER			NOT NULL,
	TAG_GROUP_ID				NUMBER			NOT NULL,
	CONSTRAINT PK_EXCEL_EXPORT_OPTIONS_TG PRIMARY KEY (CSRIMP_SESSION_ID, DATAVIEW_SID, APPLIES_TO, TAG_GROUP_ID),
	CONSTRAINT CHK_EXCEL_EXPORT_OPTIONS_AT CHECK (APPLIES_TO IN (1,2)),
	CONSTRAINT FK_EXCEL_EXPORT_OPTIONS_TAG_GROUP_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE CSR.EXCEL_EXPORT_OPTIONS_TAG_GROUP ADD CONSTRAINT FK_EE_OPTIONS_TG_EE_OPTIONS
	FOREIGN KEY (APP_SID, DATAVIEW_SID)
	REFERENCES CSR.EXCEL_EXPORT_OPTIONS(APP_SID, DATAVIEW_SID)
;

ALTER TABLE CSR.EXCEL_EXPORT_OPTIONS_TAG_GROUP ADD CONSTRAINT FK_EE_OPTIONS_TG_TAG_GROUP
	FOREIGN KEY (APP_SID, TAG_GROUP_ID)
	REFERENCES CSR.TAG_GROUP(APP_SID, TAG_GROUP_ID)
;

ALTER TABLE CSRIMP.REGION_ENERGY_RATING MODIFY (ISSUED_DTM NULL);

CREATE INDEX csr.ix_excel_export__tag_group_id ON csr.excel_export_options_tag_group (app_sid, tag_group_id);

-- *** Grants ***
grant insert on csr.excel_export_options_tag_group to csrimp;
grant select,insert,update,delete on csrimp.excel_export_options_tag_group to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../excel_export_pkg
@../schema_pkg

@../csr_app_body
@../excel_export_body
@../dataview_body
@../schema_body
@../csrimp/imp_body

@update_tail
