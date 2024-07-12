-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=10
@update_header

ALTER TABLE CSR.QUICK_SURVEY_ANSWER DROP CONSTRAINT FK_QSQ_QSA_MEASURE;

ALTER TABLE CSR.QUICK_SURVEY_ANSWER ADD CONSTRAINT FK_QSQ_QSA_MEASURE
    FOREIGN KEY (APP_SID, QUESTION_ID, SURVEY_VERSION, MEASURE_SID)
    REFERENCES CSR.QUICK_SURVEY_QUESTION(APP_SID, QUESTION_ID, SURVEY_VERSION, MEASURE_SID) DEFERRABLE INITIALLY DEFERRED
;

begin
	for r in (select 1 from all_constraints where owner='CSR' and constraint_name='FK_QSQ_Q_MEASURE') loop
		execute immediate 'ALTER TABLE CSR.QUICK_SURVEY_QUESTION DROP CONSTRAINT FK_QSQ_Q_MEASURE';
	end loop;
end;
/

-- *** DDL ***
-- Create tables

-- Alter tables

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

@update_tail
