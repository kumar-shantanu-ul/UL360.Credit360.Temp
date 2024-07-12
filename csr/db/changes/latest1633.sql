-- Please update version.sql too -- this keeps clean builds in sync
define version=1633
@update_header

DROP INDEX CSR.UK_EST_BUILDING_REGION_SID;
DROP INDEX CSR.IX_EST_BLDNG_RGN;
DROP INDEX CSR.UK_EST_ENERGYM_REGION_SID;
DROP INDEX CSR.IX_EST_METER_RGN;
DROP INDEX CSR.UK_EST_SPACE_REGION_SID;
DROP INDEX CSR.IX_EST_SPACE_RGN;
DROP INDEX CSR.UK_EST_WATERM_REGION_SID;
DROP INDEX CSR.IX_WMETER_RGN;

CREATE UNIQUE INDEX CSR.UK_EST_BUILDING_REGION_SID ON CSR.EST_BUILDING(APP_SID, REGION_SID);
CREATE UNIQUE INDEX CSR.UK_EST_ENERGYM_REGION_SID ON CSR.EST_ENERGY_METER(APP_SID, REGION_SID);
CREATE UNIQUE INDEX CSR.UK_EST_SPACE_REGION_SID ON CSR.EST_SPACE(APP_SID, REGION_SID);
CREATE UNIQUE INDEX CSR.UK_EST_WATERM_REGION_SID ON CSR.EST_WATER_METER(APP_SID, REGION_SID);


ALTER TABLE CSR.ROUTE ADD (DUE_DTM DATE);


ALTER TABLE CSR.ROUTE_STEP RENAME COLUMN DUE_DTM TO STEP_DUE_DTM;

CREATE FUNCTION aspen2.SubtractWorkingDays(
    in_date     IN  DATE,
    in_days     IN  NUMBER
) RETURN DATE
AS
    v_result    DATE;
BEGIN
    IF in_days < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Days must be greater than or equal to zero');
    ELSIF in_days = 0 THEN
        RETURN in_date;
    END IF;
    SELECT in_date-MAX(i) INTO v_result
      FROM (
        SELECT i, ROWNUM rn
          FROM (SELECT LEVEL i FROM dual CONNECT BY LEVEL BETWEEN 1 AND (in_days+1)*2) -- multply by two to guarantee some leeway
         WHERE TO_CHAR(in_date-i,'Dy') NOT IN ('Sat', 'Sun')
         )
     WHERE rn = in_days;
    RETURN v_result;
END;
/


UPDATE CSR.ROUTE_STEP
   SET step_due_dtm = aspen2.utils_pkg.SubtractWorkingDays(step_due_dtm, work_days_offset);

DROP FUNCTION aspen2.SubtractWorkingDays;


BEGIN
    FOR r IN (
        SELECT route_id, MAX(step_due_dtm) due_dtm FROM csr.route_step GROUP BY route_id
    )
    LOOP
        UPDATE CSR.ROUTE
           SET due_dtm = r.due_dtm
         WHERE route_id = r.route_id;
    END LOOP;
END;
/

ALTER TABLE CSR.ROUTE MODIFY DUE_DTM NOT NULL;

ALTER TABLE CSRIMP.ROUTE_STEP RENAME COLUMN DUE_DTM TO STEP_DUE_DTM;

ALTER TABLE CSRIMP.ROUTE ADD (DUE_DTM DATE);

BEGIN
    FOR r IN (
        SELECT CSRIMP_SESSION_ID, route_id, MAX(step_due_dtm) due_dtm FROM csrimp.route_step GROUP BY CSRIMP_SESSION_ID, route_id
    )
    LOOP
        UPDATE CSRIMP.ROUTE
           SET due_dtm = r.due_dtm
         WHERE route_id = r.route_id
           AND CSRIMP_SESSION_ID = r.CSRIMP_SESSION_ID;
    END LOOP;
END;
/

ALTER TABLE CSRIMP.ROUTE MODIFY DUE_DTM NOT NULL;


@..\section_pkg
@..\section_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
