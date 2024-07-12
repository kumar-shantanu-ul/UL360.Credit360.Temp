-- Run this script from this folder to calculate the PL/SQL code coverage
-- of the database unit tests
--
-- Run it as the profiler user (see create_profiler_user)

BEGIN
	DBMS_OUTPUT.PUT_LINE('Starting to run tests with profiling');
	DBMS_PROFILER.START_PROFILER(run_comment1 => 'run_tests_with_coverage');
END;
/

@all_tests

BEGIN
	DBMS_PROFILER.STOP_PROFILER;
	DBMS_OUTPUT.PUT_LINE('Done');
END;
/

