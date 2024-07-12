-- Please update version.sql too -- this keeps clean builds in sync
define version=64
@update_header

connect postcode/postcode@&_CONNECT_IDENTIFIER

grant select, references on postcode.country to donations;

connect donations/donations@&_CONNECT_IDENTIFIER

ALTER TABLE donations.CUSTOMER_OPTIONS DROP CONSTRAINT RefCOUNTRY161;

ALTER TABLE donations.RECIPIENT DROP CONSTRAINT RefCOUNTRY65;

ALTER TABLE donations.CUSTOMER_OPTIONS ADD CONSTRAINT RefCOUNTRY161 
    FOREIGN KEY (DEFAULT_COUNTRY)
    REFERENCES POSTCODE.COUNTRY(COUNTRY)
;

ALTER TABLE donations.RECIPIENT ADD CONSTRAINT RefCOUNTRY65 
    FOREIGN KEY (COUNTRY_CODE)
    REFERENCES POSTCODE.COUNTRY(COUNTRY)
;

DROP TABLE donations.COUNTRY;

@..\recipient_pkg
@..\recipient_body
@..\reports_body

@update_tail
