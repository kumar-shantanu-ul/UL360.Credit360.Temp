-- Please update version.sql too -- this keeps clean builds in sync
define version=585
@update_header

CREATE OR REPLACE FUNCTION from_tz_robust(
	in_timestamp					IN	TIMESTAMP,
	in_tz							IN	VARCHAR2
) RETURN TIMESTAMP WITH TIME ZONE
AS
	e_nonexistent_time	EXCEPTION;
	PRAGMA EXCEPTION_INIT(e_nonexistent_time, -1878);
	v_hour				NUMBER;
BEGIN
	BEGIN
		RETURN from_tz(in_timestamp, in_tz);
	EXCEPTION
		WHEN e_nonexistent_time THEN
			NULL;
	END;
	
	v_hour := EXTRACT(hour from in_timestamp);
	WHILE v_hour < 24 LOOP
		v_hour := v_hour + 1;
		BEGIN
			RETURN from_tz(cast(trunc(in_timestamp) + v_hour/24 as timestamp), in_tz);
		EXCEPTION
			WHEN e_nonexistent_time THEN
				NULL;
		END;
	END LOOP;
	
	v_hour := EXTRACT(hour from in_timestamp);
	WHILE v_hour > 0 LOOP
		v_hour := v_hour - 1;
		BEGIN
			RETURN from_tz(cast(trunc(in_timestamp) + v_hour/24 as timestamp), in_tz);
		EXCEPTION
			WHEN e_nonexistent_time THEN
				NULL;
		END;
	END LOOP;
	
	RAISE_APPLICATION_ERROR(-20001, 'Cannot find a time near '||in_timestamp||' in the timezone '||in_tz);
END;
/

create or replace view v$alert_batch_run_time as
	select app_sid, csr_user_sid, alert_batch_run_time, user_tz,
		   user_run_at, user_run_at at time zone 'Etc/GMT' user_run_at_gmt,
		   user_current_time, user_current_time at time zone 'Etc/GMT' user_current_time_gmt,
		   next_fire_time, next_fire_time at time zone 'Etc/GMT' next_fire_time_gmt,	
		   next_fire_time - numtodsinterval(1,'DAY') prev_fire_time,
		   (next_fire_time - numtodsinterval(1,'DAY')) at time zone 'Etc/GMT' prev_fire_time_gmt
	  from (select app_sid, csr_user_sid, alert_batch_run_time, user_run_at, user_current_time,
		   		   case when user_run_at < user_current_time then user_run_at + numtodsinterval(1,'DAY') else user_run_at end next_fire_time,
		   		   user_tz
			  from (select app_sid, csr_user_sid, alert_batch_run_time,
						   from_tz_robust(cast(trunc(user_current_time) + alert_batch_run_time as timestamp), user_tz) user_run_at,
						   user_current_time, user_tz
			  		  from (select cu.app_sid, cu.csr_user_sid, alert_batch_run_time,
								   systimestamp at time zone COALESCE(ut.timezone, a.timezone, 'Etc/GMT') user_current_time,
								   COALESCE(ut.timezone, a.timezone, 'Etc/GMT') user_tz
							  from security.user_table ut, security.application a, csr_user cu, customer c
							 where cu.csr_user_sid = ut.sid_id
							   and c.app_sid = cu.app_sid
							   and a.application_sid_id = c.app_sid)));

@update_tail
