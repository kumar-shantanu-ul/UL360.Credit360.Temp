CREATE OR REPLACE FUNCTION csr.from_tz_robust(
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
