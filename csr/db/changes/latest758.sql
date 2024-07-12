-- Please update version.sql too -- this keeps clean builds in sync
define version=758
@update_header


ALTER TABLE csr.CUSTOMER ADD (
	FWD_ESTIMATE_METERS 	NUMBER(1,0) 	DEFAULT 0 NOT NULL,
    CONSTRAINT CK_CUSTOMER_FWD_EST_METERS CHECK (FWD_ESTIMATE_METERS IN (0,1))
);

UPDATE csr.CUSTOMER SET FWD_ESTIMATE_METERS = 1
 WHERE app_sid IN (
	SELECT DISTINCT app_sid FROM csr.meter
 );


@..\meter_body


@update_tail
