-- Please update version.sql too -- this keeps clean builds in sync
define version=3416
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.alert_template ADD (
    SAVE_IN_SENT_ALERTS     NUMBER(1) DEFAULT 1 NOT NULL,
    CONSTRAINT CK_SAVE_IN_SENT_ALERTS CHECK (SAVE_IN_SENT_ALERTS IN (0,1))
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.alert_template alt
   SET save_in_sent_alerts = 0
 WHERE EXISTS (
    SELECT NULL
      FROM csr.customer_alert_type
     WHERE customer_alert_type_id = alt.customer_alert_type_id
       AND std_alert_type_id = 25 -- csr.csr_data_pkg.ALERT_PASSWORD_RESET
);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../alert_body
@../csr_app_body

@update_tail
