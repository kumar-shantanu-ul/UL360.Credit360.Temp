-- Please update version.sql too -- this keeps clean builds in sync
define version=320
@update_header

ALTER TABLE UTILITY_CONTRACT ADD (
	TO_DTM		DATE	NULL
);

BEGIN
	FOR r IN (
		SELECT utility_contract_id, ADD_MONTHS(from_dtm, DECODE (c.contract_duration_id, 5, duration_other, d.duration_months)) to_dtm
		  FROM utility_contract c, contract_duration d
		 WHERE d.contract_duration_id = c.contract_duration_id
	) LOOP
		UPDATE utility_contract
		   SET to_dtm = r.to_dtm
		 WHERE utility_contract_id = r.utility_contract_id;
	END LOOP;
	COMMIT;
END;
/

ALTER TABLE UTILITY_CONTRACT MODIFY (
	TO_DTM		DATE	NOT NULL
);

COMMENT ON COLUMN UTILITY_CONTRACT.TO_DTM IS 'desc="To Date"'
;

DROP TABLE CONTRACT_DURATION CASCADE CONSTRAINTS;
ALTER TABLE UTILITY_CONTRACT DROP COLUMN CONTRACT_DURATION_ID;
ALTER TABLE UTILITY_CONTRACT DROP COLUMN DURATION_OTHER;

@update_tail