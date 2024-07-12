-- Please update version.sql too -- this keeps clean builds in sync
define version=3498
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
    DBMS_SCHEDULER.DROP_JOB(job_name => 'OSC.CHECKBSCIMEMBERSHIP');
    DBMS_SCHEDULER.DROP_JOB(job_name => 'OSC.PROCESSCOMPANYEVENTS');
    DBMS_SCHEDULER.DROP_JOB(job_name => 'OSC.SIXMONTHLYREVIEW');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
