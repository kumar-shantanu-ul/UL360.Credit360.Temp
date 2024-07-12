-- Please update version.sql too -- this keeps clean builds in sync
define version=1112
@update_header

ALTER TABLE CSR.PROPERTY ADD FLOW_ITEM_ID          NUMBER(10);
ALTER TABLE CSR.PROPERTY ADD CONSTRAINT FK_PROPERTY_FLOW_ITEM 
    FOREIGN KEY (APP_SID, FLOW_ITEM_ID)
    REFERENCES CSR.FLOW_ITEM(APP_SID, FLOW_ITEM_ID)
;
COMMENT ON COLUMN CSR.PROPERTY.FLOW_ITEM_ID IS 'desc="Flow item id",flow_item';
COMMENT ON COLUMN CSR.PROPERTY.REGION_SID IS 'desc="Region",flow_region';

@update_tail
