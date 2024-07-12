-- Please update version.sql too -- this keeps clean builds in sync
define version=3335
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.auto_exp_retrieval_dataview ADD (
	region_selection_type_id				NUMBER(10, 0) DEFAULT 6 NOT NULL,
	tag_id									NUMBER(10, 0)
);

ALTER TABLE csr.auto_exp_retrieval_dataview
ADD CONSTRAINT fk_auto_exp_rdv_tag FOREIGN KEY (app_sid, tag_id) REFERENCES csr.tag(app_sid, tag_id);

CREATE INDEX csr.ix_auto_exp_retr_tag_id ON csr.auto_exp_retrieval_dataview (app_sid, tag_id);

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
@../automated_export_pkg
@../automated_export_body

@update_tail
