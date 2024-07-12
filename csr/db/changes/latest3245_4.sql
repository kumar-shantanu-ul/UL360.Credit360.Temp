-- Please update version.sql too -- this keeps clean builds in sync
define version=3245
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- csr.compliance_item_description
ALTER TABLE csr.compliance_item_description ADD lang_id NUMBER(10);
ALTER TABLE csr.compliance_item_description DROP CONSTRAINT FK_COMP_ITEM_DESC_COMP_LANG;
ALTER TABLE csr.compliance_item_description DROP CONSTRAINT PK_COMPLIANCE_ITEM_DESCRIPTION;

UPDATE csr.compliance_item_description cid
   SET cid.lang_id = (
	SELECT cil.lang_id
	  FROM csr.compliance_language cil
	 WHERE cil.compliance_language_id = cid.compliance_language_id);

ALTER TABLE csr.compliance_item_description DROP COLUMN compliance_language_id;
ALTER TABLE csr.compliance_item_description ADD CONSTRAINT PK_COMPLIANCE_ITEM_DESCRIPTION PRIMARY KEY (APP_SID, COMPLIANCE_ITEM_ID, LANG_ID);

CREATE INDEX csr.ix_compliance_it_compliance_la on csr.compliance_item_description (app_sid, lang_id);

-- csrimp.compliance_item_description
ALTER TABLE csrimp.compliance_item_description DROP CONSTRAINT PK_COMPLIANCE_ITEM_DESCRIPTION;
ALTER TABLE csrimp.compliance_item_description RENAME COLUMN compliance_language_id TO lang_id;
ALTER TABLE csrimp.compliance_item_description ADD CONSTRAINT PK_COMPLIANCE_ITEM_DESCRIPTION PRIMARY KEY (CSRIMP_SESSION_ID, COMPLIANCE_ITEM_ID, LANG_ID);

-- csr.compliance_item_desc_hist
ALTER TABLE csr.compliance_item_desc_hist DROP CONSTRAINT FK_COMP_ITEM_DSC_HST_COMP_LANG;
UPDATE csr.compliance_item_desc_hist cidh SET compliance_language_id = (
	SELECT cil.lang_id
	  FROM csr.compliance_language cil
	 WHERE cil.compliance_language_id = cidh.compliance_language_id
);
ALTER TABLE csr.compliance_item_desc_hist RENAME COLUMN compliance_language_id TO lang_id;

DROP INDEX csr.ix_comp_item_desc_hist_comp_lg;
CREATE INDEX csr.ix_comp_item_desc_hist_comp_lg ON csr.compliance_item_desc_hist (app_sid, lang_id);

-- csrimp.compliance_item_desc_hist
ALTER TABLE csrimp.compliance_item_desc_hist RENAME COLUMN compliance_language_id TO lang_id;

-- csr.compliance_language
ALTER TABLE csr.compliance_language DROP CONSTRAINT PK_COMPLIANCE_LANGUAGE;
ALTER TABLE csr.compliance_language DROP CONSTRAINT UK_COMPLIANCE_LANGUAGE;
ALTER TABLE csr.compliance_language DROP COLUMN compliance_language_id;
ALTER TABLE csr.compliance_language ADD CONSTRAINT PK_COMPLIANCE_LANGUAGE PRIMARY KEY (APP_SID, LANG_ID);

-- csrimp.compliance_language
DROP TABLE csrimp.map_compliance_language;
ALTER TABLE csrimp.compliance_language DROP CONSTRAINT PK_COMPLIANCE_LANGUAGE;
ALTER TABLE csrimp.compliance_language DROP COLUMN compliance_language_id;
ALTER TABLE csrimp.compliance_language ADD CONSTRAINT PK_COMPLIANCE_LANGUAGE PRIMARY KEY (csrimp_session_id, lang_id);

-- add fks
ALTER TABLE csr.compliance_item_description
	ADD CONSTRAINT fk_pk_comp_item_var_comp_lang
	   FOREIGN KEY (app_sid, lang_id)
	    REFERENCES csr.compliance_language (app_sid, lang_id);
		
ALTER TABLE csr.compliance_item_desc_hist 
	ADD CONSTRAINT FK_COMP_ITEM_DSC_HST_COMP_LANG 
	   FOREIGN KEY (app_sid, lang_id) 
	    REFERENCES csr.compliance_language (app_sid, lang_id);

-- csr.compliance_item_history
ALTER TABLE csr.compliance_item_history ADD lang_id NUMBER(10,0);
UPDATE csr.compliance_item_history SET lang_id = 53;
ALTER TABLE csr.compliance_item_history MODIFY (lang_id NOT NULL);
-- csrimp.compliance_item_history
ALTER TABLE csrimp.compliance_item_history ADD lang_id NUMBER(10,0) NOT NULL;


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../compliance_pkg

@../compliance_body
@../compliance_library_report_body
@../compliance_register_report_body
@../csr_app_body
@../enable_body
@../schema_body

@../csrimp/imp_body

@update_tail
