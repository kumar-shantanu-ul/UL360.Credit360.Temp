-- DO NOT USE THIS FILE -- EDIT create_schema.sql DIRECTLY INSTEAD

/*
csr.meter_reading.is_delete twice -- should be is_estimate
overlapping constraints (to csr.customer on app_sid)
csr.section_ind orphaned -- generate, tabs without ri constraints on app_sid
UPDATED_PLANNED_DELEG_ALERT NO RI
NEW_PLANDELEG_ALERT_ID_SEQ NO RI
unique constraints without app_sid
batch job child tables missing constraints
csr.inbound_feed, csr.inbound_feed_account missing ri
csr.course_file_data, csr.course_file pk names
FK_IND_START_POINT_USER duff name!
CREATE SEQUENCE CSR.SUPPLIER_SCORE_ID_SEQ; -- rename to supplier_score_log

*/
