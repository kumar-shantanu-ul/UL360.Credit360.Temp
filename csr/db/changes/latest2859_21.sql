-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=21
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.QUICK_SURVEY_CSS (
    APP_SID						NUMBER(10)		DEFAULT sys_context('security','app') NOT NULL,
    CLASS_NAME		 			VARCHAR2(1024)	NOT NULL,
    DESCRIPTION		 			VARCHAR2(1024)	NOT NULL,
    TYPE						NUMBER(1)		NOT NULL,
	POSITION					NUMBER(10)    	DEFAULT 0 NOT NULL,
    CONSTRAINT PK_QUICK_SURVEY_CSS PRIMARY KEY (APP_SID, CLASS_NAME)
);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\quick_survey_pkg
@..\quick_survey_body

@update_tail
