-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.EST_JOB ADD (
	CREATED_BY_USER_SID    NUMBER(10, 0)
);


ALTER TABLE CSR.EST_JOB ADD CONSTRAINT FK_CSRUSR_ESTJOB 
    FOREIGN KEY (APP_SID, CREATED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

CREATE INDEX CSR.IX_CSRUSR_ESTJOB ON CSR.EST_JOB(APP_SID, CREATED_BY_USER_SID);

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
@../energy_star_job_pkg

@../energy_star_body
@../energy_star_job_body

@update_tail
