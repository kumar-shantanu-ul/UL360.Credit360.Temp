-- Please update version.sql too -- this keeps clean builds in sync
define version=2916
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer ADD (
	quick_survey_fixed_structure NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_qs_fixed_structure CHECK (quick_survey_fixed_structure IN (0, 1))
);

ALTER TABLE csrimp.customer ADD (
	quick_survey_fixed_structure NUMBER(1),
	CONSTRAINT chk_qs_fixed_structure CHECK (quick_survey_fixed_structure IN (0, 1))
);

UPDATE csrimp.customer
   SET quick_survey_fixed_structure = 0
 WHERE quick_survey_fixed_structure IS NULL;

ALTER TABLE csrimp.customer MODIFY quick_survey_fixed_structure NOT NULL;


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\csrimp\imp_body
@..\schema_body
@..\customer_body

@update_tail
