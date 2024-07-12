-- Please update version.sql too -- this keeps clean builds in sync
define version=36
@update_header


DROP TYPE T_VAL_TABLE;

CREATE OR REPLACE TYPE T_VAL_ROW AS 
  OBJECT ( 
	PERIOD_START_DTM		DATE,
	PERIOD_END_DTM			DATE,
	VAL_NUMBER			NUMBER(20, 6),
	VAL_NULL			NUMBER(10),
	ESTIMATED			NUMBER(10),
	VAL_IDS_USED			VARCHAR2(2000),
	REGION_SID			NUMBER(10),
	FLAGS				NUMBER(10),
	MOST_RECENT_CHANGE_DTM		DATE
  );
/
CREATE OR REPLACE TYPE T_VAL_TABLE AS 
  TABLE OF T_VAL_ROW;
/







-- refix fully_delegated flag
DECLARE
	v_is_fully_delegated NUMBER(10);
BEGIN
	FOR r IN (SELECT delegation_sid, ROWID rid FROM delegation WHERE delegation_pkg.IsFullyDelegated(delegation_sid) != fully_delegated)
    LOOP
    	v_is_fully_delegated := delegation_pkg.isFullyDelegated(r.delegation_sid);
		UPDATE delegation SET Fully_Delegated = v_is_fully_delegated WHERE ROWID = r.rid;
	END LOOP;
END; 
/
COMMIT;

@update_tail
