-- Please update version.sql too -- this keeps clean builds in sync
define version=1952
@update_header

CREATE SEQUENCE CHAIN.CMS_ITEM_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

grant select on cms.tab_column to chain;

@../chain/flow_form_pkg	
@../chain/flow_form_body	

@update_tail