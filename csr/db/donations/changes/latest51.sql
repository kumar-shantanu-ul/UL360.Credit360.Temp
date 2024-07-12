-- Please update version.sql too -- this keeps clean builds in sync
define version=51
@update_header

ALTER TABLE donations.customer_options ADD (
    DEFAULT_FIELD    varchar2(255) 
);


ALTER TABLE donations.custom_field ADD CONSTRAINT uk_custom_field_lookup_key UNIQUE (app_sid, lookup_key) USING INDEX;

ALTER TABLE donations.CUSTOMER_OPTIONS ADD CONSTRAINT RefCUSTOM_FIELD163
    FOREIGN KEY (APP_SID, DEFAULT_FIELD)
    REFERENCES donations.CUSTOM_FIELD(APP_SID, LOOKUP_KEY)
;

@../options_body

@update_tail
