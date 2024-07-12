-- Please update version.sql too -- this keeps clean builds in sync
define version=2373
@update_header

DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT count(*) INTO v_cnt
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'BENCHMARK_DASHBOARD'
	   AND column_name = 'LOOKUP_KEY';

	IF v_cnt = 0 THEN

		EXECUTE IMMEDIATE 'ALTER TABLE csr.benchmark_dashboard ADD ( lookup_key VARCHAR(255) )';
		EXECUTE IMMEDIATE 'UPDATE csr.benchmark_dashboard SET lookup_key = ''DEFAULT_BENCHMARKING_DASHBOARD'' WHERE name = ''Default dashboard''';
		EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX csr.uk_benchmark_dash_lookup ON csr.benchmark_dashboard (app_sid, NVL(UPPER(lookup_key), TO_CHAR(benchmark_dashboard_sid)))';

	END IF;
END;
/

DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT count(*) INTO v_cnt
	  FROM dba_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'METRIC_DASHBOARD'
	   AND column_name = 'LOOKUP_KEY';

	IF v_cnt = 0 THEN

		EXECUTE IMMEDIATE 'ALTER TABLE csr.metric_dashboard ADD ( lookup_key VARCHAR(255) )';
		EXECUTE IMMEDIATE 'UPDATE csr.metric_dashboard SET lookup_key = ''DEFAULT_METRIC_DASHBOARD'' WHERE name = ''Default metric dashboard''';
		EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX csr.uk_metric_dash_lookup ON csr.metric_dashboard (app_sid, NVL(UPPER(lookup_key), TO_CHAR(metric_dashboard_sid)))';

	END IF;
END;
/

@..\benchmarking_dashboard_pkg
@..\metric_dashboard_pkg

@..\benchmarking_dashboard_body
@..\metric_dashboard_body

@update_tail
