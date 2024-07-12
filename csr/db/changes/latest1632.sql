-- Please update version.sql too -- this keeps clean builds in sync
define version=1632
@update_header

CREATE UNIQUE INDEX CSR.UK_EST_BUILDING_REGION_SID ON CSR.EST_BUILDING(REGION_SID);
CREATE UNIQUE INDEX CSR.UK_EST_ENERGYM_REGION_SID ON CSR.EST_ENERGY_METER(REGION_SID);
CREATE UNIQUE INDEX CSR.UK_EST_SPACE_REGION_SID ON CSR.EST_SPACE(REGION_SID);
CREATE UNIQUE INDEX CSR.UK_EST_WATERM_REGION_SID ON CSR.EST_WATER_METER(REGION_SID);

@update_tail
