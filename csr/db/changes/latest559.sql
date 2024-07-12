-- Please update version.sql too -- this keeps clean builds in sync
define version=559
@update_header

CREATE GLOBAL TEMPORARY TABLE temp_region_sid
(
	region_sid		number(10) not null
) ON COMMIT DELETE ROWS;
CREATE INDEX ix_temp_region_sid ON temp_region_sid(region_sid);

CREATE GLOBAL TEMPORARY TABLE temp_new_val
(
	ind_sid 			number(10),
	region_sid 			number(10),
	period_start_dtm	date,
	period_end_dtm		date,
	source_type_id		number(10),
	val_number			number(24,10)
) ON COMMIT DELETE ROWS;

grant select, insert, update, delete on temp_new_val to web_user;

CREATE TABLE scrag_queue
(
	app_sid				number(10),
	CONSTRAINT pk_scrag_queue PRIMARY KEY (app_sid)
	USING INDEX TABLESPACE INDX
);

CREATE GLOBAL TEMPORARY TABLE temp_scrag_queue
(
	app_sid				number(10)
) ON COMMIT PRESERVE ROWS;

set define off
@..\calc_pkg
@..\stored_calc_datasource_body
@..\calc_body
@..\region_body
@..\indicator_body

@update_tail
