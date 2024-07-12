-- Please update version.sql too -- this keeps clean builds in sync
define version=705
@update_header

ALTER TABLE csr.CUSTOM_LOCATION ADD CONSTRAINT RefLOCATION_TYPE2098 
    FOREIGN KEY (LOCATION_TYPE_ID)
    REFERENCES LOCATION_TYPE(LOCATION_TYPE_ID)
;

@update_tail
