-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table CSR.QS_ANSWER_LOG ADD (
	VERSION_STAMP NUMBER(10,0) DEFAULT(0) NOT NULL
);

alter table CSRIMP.QS_ANSWER_LOG ADD (
	VERSION_STAMP NUMBER(10,0) DEFAULT(0) NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@..\csrimp\imp_body
@..\quick_survey_body
@..\schema_body

@update_tail
