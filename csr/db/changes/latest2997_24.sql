-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=24
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.doc_folder ADD (
	property_sid					NUMBER(10) NULL,
	CONSTRAINT fk_doc_folder_property 
		FOREIGN KEY (app_sid, property_sid) 
		REFERENCES csr.all_property (app_sid, region_sid)
);

ALTER TABLE csrimp.doc_folder ADD (
	property_sid					NUMBER(10) NULL
);

CREATE INDEX csr.ix_doc_folder_property ON csr.doc_folder (app_sid, property_sid);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (90, 'Properties - document library', 'EnablePropertyDocLib', 'Enables the property document library and document tab.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../doc_folder_pkg
@../enable_pkg
@../property_pkg

@../csrimp/imp_body
@../doc_folder_body
@../enable_body
@../property_body
@../region_body
@../schema_body

@update_tail
