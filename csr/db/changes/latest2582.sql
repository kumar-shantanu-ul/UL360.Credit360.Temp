-- Please update version.sql too -- this keeps clean builds in sync
define version=2582
@update_header

DROP INDEX CSR.UK_METER_IND;

ALTER TABLE CSR.METER_IND ADD(
    REASON                 VARCHAR2(256)    DEFAULT 'DEFAULT' NOT NULL
);

CREATE UNIQUE INDEX CSR.UK_METER_IND ON CSR.METER_IND(APP_SID, CONSUMPTION_IND_SID, REASON, NVL(GROUP_KEY,'ALL'));

@../property_body
@../energy_star_attr_body

@update_tail
