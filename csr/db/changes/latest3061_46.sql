-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=46
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
	
-- *** Grants ***

-- ** Cross schema constraints ***

ALTER TABLE chain.supplier_relationship_score ADD CONSTRAINT fk_sup_rel_csr_user 
	FOREIGN KEY (app_sid, changed_by_user_sid)
	REFERENCES csr.csr_user(app_sid, csr_user_sid);

CREATE INDEX chain.ix_rel_score_csr_user ON chain.supplier_relationship_score (app_sid, changed_by_user_sid);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
