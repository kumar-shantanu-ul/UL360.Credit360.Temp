-- Please update version.sql too -- this keeps clean builds in sync
define version=3474
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOM_FACTOR ADD CONSTRAINT FK_CUSTOM_FCTR_REGION
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;
create index csr.ix_custom_factor_region_sid on csr.custom_factor (app_sid, region_sid);

ALTER TABLE CSR.PROPERTY_FUND_OWNERSHIP ADD CONSTRAINT FK_PFO_REGION
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;

ALTER TABLE CSR.METER_UTILITY_CONTRACT ADD CONSTRAINT RefUTILITY_CONTRACT_REGION
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;

-- *** Grants ***
GRANT SELECT, UPDATE, DELETE ON chain.saved_filter_region TO csr;
grant select, UPDATE, DELETE, references on chain.saved_filter_alert_subscriptn to csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../trash_pkg

@../dataview_body
@../flow_body
@../region_body
@../trash_body

@update_tail
