define version=2096
@update_header

BEGIN
	FOR chk IN (
		SELECT * FROM dual WHERE NOT EXISTS (
			SELECT * FROM all_tab_columns
			 WHERE owner = 'CSR'
			   AND table_name = 'CALENDAR_EVENT_INVITE'
			   AND column_name = 'DECLINED_DTM'
		)
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.calendar_event_invite ADD (declined_dtm DATE)';
	END LOOP;
END;
/

@update_tail