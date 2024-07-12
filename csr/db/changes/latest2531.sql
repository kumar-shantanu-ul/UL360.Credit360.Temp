-- Please update version.sql too -- this keeps clean builds in sync
define version=2531
@update_header

ALTER TABLE CSR.EST_ERROR ADD (
	REQUEST_BODY_C       CLOB,
    RESPONSE_C           CLOB
);

BEGIN
	UPDATE csr.est_error
	   SET request_body_c = request_body,
	   	   response_c = response;
END;
/

ALTER TABLE CSR.EST_ERROR DROP COLUMN REQUEST_BODY;
ALTER TABLE CSR.EST_ERROR DROP COLUMN RESPONSE;

ALTER TABLE CSR.EST_ERROR RENAME COLUMN REQUEST_BODY_C TO REQUEST_BODY;
ALTER TABLE CSR.EST_ERROR RENAME COLUMN RESPONSE_C TO RESPONSE;

@../energy_star_pkg

@../energy_star_body
@../energy_star_job_body
@../property_body


@update_tail
