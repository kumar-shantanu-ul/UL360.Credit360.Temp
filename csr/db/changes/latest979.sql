-- Please update version.sql too -- this keeps clean builds in sync
define version=979
@update_header

DELETE
  FROM csr.property_division pd
 WHERE pd.rowid >
   ANY (
		SELECT pd2.rowid
		  FROM csr.property_division pd2
		 WHERE pd.app_sid = pd2.app_sid
		   AND pd.division_id = pd2.division_id
		   AND pd.property_id = pd2.property_id
		   AND pd.start_dtm = pd2.start_dtm
);

ALTER TABLE csr.property_division
	ADD CONSTRAINT PK_PROPERTY_DIVISION PRIMARY KEY (APP_SID, DIVISION_ID, PROPERTY_ID, START_DTM);

@update_tail
