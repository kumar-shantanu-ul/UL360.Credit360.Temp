-- Please update version.sql too -- this keeps clean builds in sync
define version=2912
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.METER_TYPE_CHANGE_BATCH_JOB ADD CONSTRAINT FK_METINPAGG_METTYPCNGBATJOB 
    FOREIGN KEY (APP_SID, METER_INPUT_ID, AGGREGATOR)
    REFERENCES CSR.METER_INPUT_AGGREGATOR(APP_SID, METER_INPUT_ID, AGGREGATOR)
;

ALTER TABLE CSR.METER_TYPE_CHANGE_BATCH_JOB ADD CONSTRAINT FK_METTYP_METTYPCNGBATJOB 
    FOREIGN KEY (APP_SID, METER_TYPE_ID)
    REFERENCES CSR.METER_TYPE(APP_SID, METER_TYPE_ID)
;

ALTER TABLE CSR.METER_TYPE_CHANGE_BATCH_JOB DROP CONSTRAINT FK_METTYPINP_METTYPCNGBATJOB;
-- Index CSR.IX_METTYPINP_METTYPCNGBATJOB dod not exits (missed)

CREATE INDEX CSR.IX_METINPAGG_METTYPCNGBATJOB ON CSR.METER_TYPE_CHANGE_BATCH_JOB(APP_SID, METER_INPUT_ID, AGGREGATOR);
CREATE INDEX CSR.IX_METTYP_METTYPCNGBATJOB ON CSR.METER_TYPE_CHANGE_BATCH_JOB(APP_SID, METER_TYPE_ID);

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
