set serveroutput on
declare
    type t_tests is table of varchar2(4000);
    type t_results is table of csr.t_recurrence_dates;
    type t_dates is table of date;
    		
    v_recurrence				csr.recurrence_pattern;
    v_tests 					t_tests;
    v_after						t_dates;
    v_dates						t_dates;
    v_results 					t_results;
    v_after_results				t_results;
    v_result					csr.t_recurrence_dates;
    v_fail						boolean;
    v_next_result				DATE;
    v_next_expected				DATE;
BEGIN
	security.user_pkg.logonadmin(:bv_site_name,86400);
	v_tests := t_tests(
-- 1
'<recurrences>
	<daily every-n="2"/>
</recurrences>',
-- 2
'<recurrences>
	<monthly every-n="1">
		<day-varying type="first" day="wednesday"/>
	</monthly>
</recurrences>',
-- 3
'<recurrences>
	<daily every-n="weekday"/>
</recurrences>',
-- 4
'<recurrences>
	<weekly every-n="3">
		<monday/>
		<wednesday/>
	</weekly>
</recurrences>',
-- 5
'<recurrences>
	<monthly every-n="1">
		<day number="6"/>
	</monthly>
</recurrences>',
-- 6
'<recurrences>
	<yearly>
		<day number="6" month="jul"/>
	</yearly>
</recurrences>',
-- 7
'<recurrences>
	<yearly>
		<day-varying type="first" day="wednesday" month="jul"/>
	</yearly>
</recurrences>',
-- 8
'<recurrences>
	<monthly>
		<day-varying type="last" day="sunday"/>
	</monthly>
</recurrences>',
-- 9
'<recurrences>
	<yearly every-n="1">
		<day-varying type="first" day="monday"/>
	</yearly>
</recurrences>',
-- 10
'<recurrences>
	<monthly every-n="1">
		<day number="31"/>
	</monthly>
</recurrences>',
-- 11
'<recurrences>
	<monthly every-n="1">
		<day number="45"/>
	</monthly>
</recurrences>',
-- 12
'<recurrences>
	<monthly every-n="1">
		<day number="1"/>
	</monthly>
</recurrences>',
-- 13
'<recurrences>
	<monthly every-n="2">
		<day number="5"/>
	</monthly>
</recurrences>',
-- 14
'<recurrences>
	<monthly every-n="1">
		<x-day-b number="5"/>
	</monthly>
</recurrences>',
-- 15, for leap year
'<recurrences>
	<monthly every-n="1">
		<x-day-b number="5"/>
	</monthly>
</recurrences>',
-- 16
'<recurrences>
	<monthly every-n="3">
		<day-varying type="first" day="tuesday"></day-varying>
	</monthly>
</recurrences>'
	);
	v_dates := t_dates(
		date '2012-01-01', date '2012-03-01',
		date '2012-01-01', date '2013-01-01',
		date '2012-01-01', date '2012-03-01',
		date '2012-01-01', date '2012-03-01',
		date '2012-01-01', date '2013-01-01',
		date '2012-01-01', date '2014-01-01',
		date '2012-01-01', date '2014-01-01',
		date '2012-01-01', date '2013-01-01',
		date '2013-01-01', date '2014-01-01',
		date '2012-01-01', date '2013-01-01',
		date '2012-01-01', date '2013-01-01',
		date '2012-09-27', date '2013-09-27',
		date '2014-04-01', date '2015-03-01',
		date '2014-01-01', date '2015-02-01',
		date '2012-02-01', date '2013-02-01',
		date '2013-05-01', date '2014-04-01'
	);
	v_after := t_dates(
		date '2012-02-04',
		date '2012-06-03',
		date '2012-02-04',
		date '2012-02-04',
		date '2012-06-03',
		date '2012-09-03',
		date '2012-09-03',
		date '2012-06-24',
		date '2013-01-01',
		date '2012-01-01',
		date '2012-01-01',
		date '2013-09-02',
		date '2014-03-31',
		date '2014-01-01',
		date '2012-02-01',
		date '2013-05-01'
	);
	v_results := t_results(
		-- 1
		csr.T_RECURRENCE_DATES(
			date '2012-01-01',
			date '2012-01-03',
			date '2012-01-05',
			date '2012-01-07',
			date '2012-01-09',
			date '2012-01-11',
			date '2012-01-13',
			date '2012-01-15',
			date '2012-01-17',
			date '2012-01-19',
			date '2012-01-21',
			date '2012-01-23',
			date '2012-01-25',
			date '2012-01-27',
			date '2012-01-29',
			date '2012-01-31',
			date '2012-02-02',
			date '2012-02-04',
			date '2012-02-06',
			date '2012-02-08',
			date '2012-02-10',
			date '2012-02-12',
			date '2012-02-14',
			date '2012-02-16',
			date '2012-02-18',
			date '2012-02-20',
			date '2012-02-22',
			date '2012-02-24',
			date '2012-02-26',
			date '2012-02-28'
		),
		-- 2
		csr.T_RECURRENCE_DATES(
			date '2012-01-04',
			date '2012-02-01',
			date '2012-03-07',
			date '2012-04-04',
			date '2012-05-02',
			date '2012-06-06',
			date '2012-07-04',
			date '2012-08-01',
			date '2012-09-05',
			date '2012-10-03',
			date '2012-11-07',
			date '2012-12-05'
		),
		-- 3
		csr.T_RECURRENCE_DATES(
			date '2012-01-02',
			date '2012-01-03',
			date '2012-01-04',
			date '2012-01-05',
			date '2012-01-06',
			date '2012-01-09',
			date '2012-01-10',
			date '2012-01-11',
			date '2012-01-12',
			date '2012-01-13',
			date '2012-01-16',
			date '2012-01-17',
			date '2012-01-18',
			date '2012-01-19',
			date '2012-01-20',
			date '2012-01-23',
			date '2012-01-24',
			date '2012-01-25',
			date '2012-01-26',
			date '2012-01-27',
			date '2012-01-30',
			date '2012-01-31',
			date '2012-02-01',
			date '2012-02-02',
			date '2012-02-03',
			date '2012-02-06',
			date '2012-02-07',
			date '2012-02-08',
			date '2012-02-09',
			date '2012-02-10',
			date '2012-02-13',
			date '2012-02-14',
			date '2012-02-15',
			date '2012-02-16',
			date '2012-02-17',
			date '2012-02-20',
			date '2012-02-21',
			date '2012-02-22',
			date '2012-02-23',
			date '2012-02-24',
			date '2012-02-27',
			date '2012-02-28',
			date '2012-02-29'
		),
		-- 4
		csr.T_RECURRENCE_DATES(
			date '2012-01-02',
			date '2012-01-04',
			date '2012-01-23',
			date '2012-01-25',
			date '2012-02-13',
			date '2012-02-15'
		),
		-- 5
		csr.T_RECURRENCE_DATES(
			date '2012-01-06',
			date '2012-02-06',
			date '2012-03-06',
			date '2012-04-06',
			date '2012-05-06',
			date '2012-06-06',
			date '2012-07-06',
			date '2012-08-06',
			date '2012-09-06',
			date '2012-10-06',
			date '2012-11-06',
			date '2012-12-06'
		),
		-- 6
		csr.T_RECURRENCE_DATES(
			date '2012-07-06',
			date '2013-07-06'
		),
		-- 7
		csr.T_RECURRENCE_DATES(
			date '2012-07-04',
			date '2013-07-03'
		),
		-- 8
		csr.T_RECURRENCE_DATES(
			date '2012-01-29',
			date '2012-02-26',
			date '2012-03-25',
			date '2012-04-29',
			date '2012-05-27',
			date '2012-06-24',
			date '2012-07-29',
			date '2012-08-26',
			date '2012-09-30',
			date '2012-10-28',
			date '2012-11-25',
			date '2012-12-30'
		),
		-- 9
		csr.T_RECURRENCE_DATES(
			date '2013-01-07'
		),
		-- 10
		csr.T_RECURRENCE_DATES(
			date '2012-01-31',
			date '2012-02-29',
			date '2012-03-31',
			date '2012-04-30',
			date '2012-05-31',
			date '2012-06-30',
			date '2012-07-31',
			date '2012-08-31',
			date '2012-09-30',
			date '2012-10-31',
			date '2012-11-30',
			date '2012-12-31'
		),
		-- 11
		csr.T_RECURRENCE_DATES(
			date '2012-02-14',
			date '2012-03-16',
			date '2012-04-14',
			date '2012-05-15',
			date '2012-06-14',
			date '2012-07-15',
			date '2012-08-14',
			date '2012-09-14',
			date '2012-10-15',
			date '2012-11-14',
			date '2012-12-15',
			date '2013-01-14'
		),
		-- 12
		csr.T_RECURRENCE_DATES(
			date '2012-10-01',
			date '2012-11-01',
			date '2012-12-01',
			date '2013-01-01',
			date '2013-02-01',
			date '2013-03-01',
			date '2013-04-01',
			date '2013-05-01',
			date '2013-06-01',
			date '2013-07-01',
			date '2013-08-01',
			date '2013-09-01'
		),
		-- 13, recurrence_pattern_pkg returns more values than NPSL.Recurrence.dll if every-n > 1. Usually we pick up the 1st date which is after sheet
		csr.T_RECURRENCE_DATES(
			date '2014-04-05',
			date '2014-06-05',
			date '2014-08-05',
			date '2014-10-05',
			date '2014-12-05',
			date '2015-02-05',
			date '2015-04-05'
		),
		-- 14, recurrence_pattern_pkg returns less values than NPSL.Recurrence.dll for x-day-b
		csr.T_RECURRENCE_DATES(
			date '2014-01-27',
			date '2014-02-24',
			date '2014-03-27',
			date '2014-04-26',
			date '2014-05-27',
			date '2014-06-26',
			date '2014-07-27',
			date '2014-08-27',
			date '2014-09-26',
			date '2014-10-27',
			date '2014-11-26',
			date '2014-12-27',
			date '2015-01-27'			
		),
		-- 15, leap year, x-day-b
		csr.T_RECURRENCE_DATES(
			date '2012-02-25',
			date '2012-03-27',
			date '2012-04-26',
			date '2012-05-27',
			date '2012-06-26',
			date '2012-07-27',
			date '2012-08-27',
			date '2012-09-26',
			date '2012-10-27',
			date '2012-11-26',
			date '2012-12-27',
			date '2013-01-27'			
		),
		-- 16, NPSL.Recurrence.dll returns date every-n months (2013-05-07, 2013-08-06, 2013-11-05, 2014-02-04) as it adds every-n
		-- but recurrence_pattern_pkg adds 1 if repeat_every is monthly else 12
		csr.T_RECURRENCE_DATES(
			date '2013-05-07',
			date '2013-06-04',
			date '2013-07-02'
		)
	);
	v_after_results := t_results(
		-- 1
		csr.T_RECURRENCE_DATES(
			date '2012-02-04',
			date '2012-02-06',
			date '2012-02-08',
			date '2012-02-10',
			date '2012-02-12',
			date '2012-02-14',
			date '2012-02-16',
			date '2012-02-18',
			date '2012-02-20',
			date '2012-02-22',
			date '2012-02-24',
			date '2012-02-26',
			date '2012-02-28'
		),
		-- 2
		csr.T_RECURRENCE_DATES(
			date '2012-06-06',
			date '2012-07-04',
			date '2012-08-01',
			date '2012-09-05',
			date '2012-10-03',
			date '2012-11-07',
			date '2012-12-05'
		),
		-- 3
		csr.T_RECURRENCE_DATES(
			date '2012-02-06',
			date '2012-02-07',
			date '2012-02-08',
			date '2012-02-09',
			date '2012-02-10',
			date '2012-02-13',
			date '2012-02-14',
			date '2012-02-15',
			date '2012-02-16',
			date '2012-02-17',
			date '2012-02-20',
			date '2012-02-21',
			date '2012-02-22',
			date '2012-02-23',
			date '2012-02-24',
			date '2012-02-27',
			date '2012-02-28',
			date '2012-02-29'
		),
		-- 4
		csr.T_RECURRENCE_DATES(
			date '2012-02-13',
			date '2012-02-15'
		),
		-- 5
		csr.T_RECURRENCE_DATES(
			date '2012-06-06',
			date '2012-07-06',
			date '2012-08-06',
			date '2012-09-06',
			date '2012-10-06',
			date '2012-11-06',
			date '2012-12-06'
		),
		-- 6
		csr.T_RECURRENCE_DATES(
			date '2013-07-06'
		),
		-- 7
		csr.T_RECURRENCE_DATES(
			date '2013-07-03'
		),
		-- 8
		csr.T_RECURRENCE_DATES(
			date '2012-06-24',
			date '2012-07-29',
			date '2012-08-26',
			date '2012-09-30',
			date '2012-10-28',
			date '2012-11-25',
			date '2012-12-30'
		),
		-- 9
		csr.T_RECURRENCE_DATES(
			date '2013-01-07'
		),
		-- 10
		csr.T_RECURRENCE_DATES(
			date '2012-01-31',
			date '2012-02-29',
			date '2012-03-31',
			date '2012-04-30',
			date '2012-05-31',
			date '2012-06-30',
			date '2012-07-31',
			date '2012-08-31',
			date '2012-09-30',
			date '2012-10-31',
			date '2012-11-30',
			date '2012-12-31'
		),
		-- 11
		csr.T_RECURRENCE_DATES(
			date '2012-02-14',
			date '2012-03-16',
			date '2012-04-14',
			date '2012-05-15',
			date '2012-06-14',
			date '2012-07-15',
			date '2012-08-14',
			date '2012-09-14',
			date '2012-10-15',
			date '2012-11-14',
			date '2012-12-15',
			date '2013-01-14'
		),
		-- 12
		csr.T_RECURRENCE_DATES(),
		-- 13
		csr.T_RECURRENCE_DATES(
			date '2014-04-05',
			date '2014-06-05',
			date '2014-08-05',
			date '2014-10-05',
			date '2014-12-05',
			date '2015-02-05',
			date '2015-04-05'
		),
		-- 14, recurrence_pattern_pkg, x-day-b, after returns all the occurrences rather than after a given date
		csr.T_RECURRENCE_DATES(
			date '2014-01-27',
			date '2014-02-24',
			date '2014-03-27',
			date '2014-04-26',
			date '2014-05-27',
			date '2014-06-26',
			date '2014-07-27',
			date '2014-08-27',
			date '2014-09-26',
			date '2014-10-27',
			date '2014-11-26',
			date '2014-12-27',
			date '2015-01-27'			
		),
		-- 15, recurrence_pattern_pkg, x-day-b, after returns all the occurrences rather than after a given date
		csr.T_RECURRENCE_DATES(
			date '2012-02-25',
			date '2012-03-27',
			date '2012-04-26',
			date '2012-05-27',
			date '2012-06-26',
			date '2012-07-27',
			date '2012-08-27',
			date '2012-09-26',
			date '2012-10-27',
			date '2012-11-26',
			date '2012-12-27',
			date '2013-01-27'
		),
		-- 16
		csr.T_RECURRENCE_DATES(
			date '2013-05-07',
			date '2013-06-04',
			date '2013-07-02'
		)
	);
		
	for i in 1 .. v_tests.count loop	
		v_recurrence := csr.RECURRENCE_PATTERN(XMLTYPE(v_tests(i)));		
		v_result := v_recurrence.MakeOccurrences(v_dates(i * 2 - 1), v_dates(i * 2));
		
		v_fail := v_result.count != v_results(i).count;
		--dbms_output.put_line(v_result.count || ' -> ' || v_results(i).count);
		if not v_fail then
			for j in v_result.first .. v_result.last loop
				v_fail := v_result(j) != v_results(i)(j);
				exit when v_fail;
			end loop;
		end if;
		if v_fail then
			if v_result.count != 0 then
				for j in v_result.first .. v_result.last loop
					dbms_output.put_line(''''||v_result(j)||''',');
				end loop;
			end if;
			raise_application_error(-20001, 'test '||i||' failed');
		end if;
		
		v_result := v_recurrence.GetOccurrencesOnOrAfter(v_after(i));
		v_fail := v_result.count != v_after_results(i).count;
		if not v_fail and v_result.count > 0 then
			for j in v_result.first .. v_result.last loop
				v_fail := v_result(j) != v_after_results(i)(j);
				exit when v_fail;
			end loop;
		end if;
		if v_fail then
			if v_result.count != 0 then
				for j in v_result.first .. v_result.last loop
					dbms_output.put_line(''''||v_result(j)||''',');
				end loop;
			end if;
			raise_application_error(-20001, 'after '||v_after(i)||' for test '||i||' failed');
		end if;
	end loop;
	
	for i in 1 .. v_tests.count loop
		-- Skip tests 4, 14 and 15 as they don't apply properly 
		-- to this procedure call for one reason or another.
		-- XXX: Also skipping test 13 too because:
		-- The UI says something like "The frst monday following every nth month".
		-- This is a little tricky as we don't know which month it's supposed to start on.
		-- So should this be a modulus type thing, so for every 3 months it only ever outputs Jan, Apr, Jul, Oct,
		-- or should it count from the given date, so if we tell it to start with the 1st Feb then it will return May?
		if i not in (4, 13, 14, 15) and v_after_results(i).count > 0 then
			
			v_next_result := csr.recurrence_pattern_pkg.GetNextOccurrence(XMLTYPE(v_tests(i)), v_after(i));
			v_next_expected := v_after_results(i)(1);
			-- We're interested in the procedure outputting the *next* date only
			if v_next_expected = v_after(i) THEN
				v_next_expected := v_after_results(i)(2);
			end if;
			if v_next_result != v_next_expected THEN
				raise_application_error(-20001, 'next '||v_after(i)||' for test '||i||' failed');
			end if;
		end if;
	end loop;
end;
/
