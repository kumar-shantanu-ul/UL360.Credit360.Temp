CREATE OR REPLACE PACKAGE BODY CSR.test_period_pkg AS

v_site_name		VARCHAR2(200);
C_DEFAULT_SET CONSTANT period_interval.period_set_id%TYPE := 1;
C_ANNUAL_SET CONSTANT period_interval.period_set_id%TYPE := 97;
C_WEEKLY_SET CONSTANT period_interval.period_set_id%TYPE := 98;
C_13_PERIOD_SET CONSTANT period_interval.period_set_id%TYPE := 99;
C_5P_ANNUAL_SET CONSTANT period_interval.period_set_id%TYPE := 96;

PROCEDURE RunPeriodNumberSequenceTest(
	in_period_set		IN period_interval.period_set_id%TYPE, 
	in_start_date		IN DATE)
AS
	v_date				DATE		:= in_start_date;
	v_expected_period	NUMBER(9)	:= 1;
	v_computed_period	NUMBER(9);
BEGIN
	-- Count up in increments of 1 month from the start date, making sure period number goes up by 1 each time
	WHILE v_date <= DATE'2021-01-01' LOOP
		v_computed_period := period_pkg.GetPeriodNumber(in_period_set, v_date);
		unit_test_pkg.AssertAreEqual(
			v_expected_period, v_computed_period, 
			'Period number mismatch in set ' || in_period_set);

		v_expected_period := v_expected_period + 1;
		v_date := ADD_MONTHS(v_date, 1);
	END LOOP;
END;

PROCEDURE TestGetPeriodNumber
AS
BEGIN
	-- Get the period number for some random dates and make sure it matches what we expect

	-- Non-default start annual
	unit_test_pkg.AssertAreEqual(1380, period_pkg.GetPeriodNumber(C_ANNUAL_SET, DATE'2015-06-01'), null);
	unit_test_pkg.AssertAreEqual(1380, period_pkg.GetPeriodNumber(C_ANNUAL_SET, DATE'2015-06-20'), null);
	unit_test_pkg.AssertAreEqual(1381, period_pkg.GetPeriodNumber(C_ANNUAL_SET, DATE'2015-07-01'), null);
	unit_test_pkg.AssertAreEqual(1381, period_pkg.GetPeriodNumber(C_ANNUAL_SET, DATE'2015-07-10'), null);
	unit_test_pkg.AssertAreEqual(1383, period_pkg.GetPeriodNumber(C_ANNUAL_SET, DATE'2015-09-01'), null);

	-- Weekly 
	unit_test_pkg.AssertAreEqual(1180, period_pkg.GetPeriodNumber(C_WEEKLY_SET, DATE'2012-09-02'), null); -- 2012/W36
	unit_test_pkg.AssertAreEqual(1180, period_pkg.GetPeriodNumber(C_WEEKLY_SET, DATE'2012-09-08'), null); -- 2012/W36
	unit_test_pkg.AssertAreEqual(1445, period_pkg.GetPeriodNumber(C_WEEKLY_SET, DATE'2017-10-08'), null); -- 2017/W41
	unit_test_pkg.AssertAreEqual(1445, period_pkg.GetPeriodNumber(C_WEEKLY_SET, DATE'2017-10-14'), null); -- 2017/W41
	unit_test_pkg.AssertAreEqual(1446, period_pkg.GetPeriodNumber(C_WEEKLY_SET, DATE'2017-10-15'), null); -- 2017/W42

	-- Weekly (long week 52)
	unit_test_pkg.AssertAreEqual(1195, period_pkg.GetPeriodNumber(C_WEEKLY_SET, DATE'2012-12-16'), null); -- 2012/W51
	unit_test_pkg.AssertAreEqual(1195, period_pkg.GetPeriodNumber(C_WEEKLY_SET, DATE'2012-12-22'), null); -- 2012/W51
	unit_test_pkg.AssertAreEqual(1196, period_pkg.GetPeriodNumber(C_WEEKLY_SET, DATE'2012-12-23'), null); -- 2012/W52
	unit_test_pkg.AssertAreEqual(1196, period_pkg.GetPeriodNumber(C_WEEKLY_SET, DATE'2013-01-01'), null); -- 2012/W52
	unit_test_pkg.AssertAreEqual(1197, period_pkg.GetPeriodNumber(C_WEEKLY_SET, DATE'2013-01-06'), null); -- 2013/W01

	-- 13p
	unit_test_pkg.AssertAreEqual(46, period_pkg.GetPeriodNumber(C_13_PERIOD_SET, DATE'2012-09-16'), null); -- 2013/07
	unit_test_pkg.AssertAreEqual(46, period_pkg.GetPeriodNumber(C_13_PERIOD_SET, DATE'2012-10-13'), null); -- 2013/07
	unit_test_pkg.AssertAreEqual(47, period_pkg.GetPeriodNumber(C_13_PERIOD_SET, DATE'2012-10-14'), null); -- 2013/08
	unit_test_pkg.AssertAreEqual(91, period_pkg.GetPeriodNumber(C_13_PERIOD_SET, DATE'2016-03-06'), null); -- 2016/13
	unit_test_pkg.AssertAreEqual(91, period_pkg.GetPeriodNumber(C_13_PERIOD_SET, DATE'2016-03-31'), null); -- 2016/13
	unit_test_pkg.AssertAreEqual(92, period_pkg.GetPeriodNumber(C_13_PERIOD_SET, DATE'2016-04-01'), null); -- 2017/01

	-- 5p
	unit_test_pkg.AssertAreEqual(575, period_pkg.GetPeriodNumber(C_5P_ANNUAL_SET, DATE'2015-03-01'), null);
	unit_test_pkg.AssertAreEqual(575, period_pkg.GetPeriodNumber(C_5P_ANNUAL_SET, DATE'2015-03-31'), null);
	unit_test_pkg.AssertAreEqual(576, period_pkg.GetPeriodNumber(C_5P_ANNUAL_SET, DATE'2015-04-01'), null);
	unit_test_pkg.AssertAreEqual(576, period_pkg.GetPeriodNumber(C_5P_ANNUAL_SET, DATE'2015-06-12'), null);
	unit_test_pkg.AssertAreEqual(577, period_pkg.GetPeriodNumber(C_5P_ANNUAL_SET, DATE'2015-06-13'), null);
END;

PROCEDURE TestGetPeriodNumberMonthly
AS
BEGIN
	RunPeriodNumberSequenceTest(C_DEFAULT_SET, DATE'1900-01-01');
	RunPeriodNumberSequenceTest(C_ANNUAL_SET, DATE'1900-07-01');
END;

PROCEDURE TestGetPeriodDate
AS
BEGIN
	-- Get the period date for some random period numbers and make sure it matches what we expect

	-- Standard annual
	unit_test_pkg.AssertAreEqual(DATE'1903-06-01', period_pkg.GetPeriodDate(C_DEFAULT_SET, 42), null);
	unit_test_pkg.AssertAreEqual(DATE'2008-12-01', period_pkg.GetPeriodDate(C_DEFAULT_SET, 1308), null);
	unit_test_pkg.AssertAreEqual(DATE'2016-01-01', period_pkg.GetPeriodDate(C_DEFAULT_SET, 1393), null);

	-- Non-default start annual
	unit_test_pkg.AssertAreEqual(DATE'2015-06-01', period_pkg.GetPeriodDate(C_ANNUAL_SET, 1380), null);
	unit_test_pkg.AssertAreEqual(DATE'2015-07-01', period_pkg.GetPeriodDate(C_ANNUAL_SET, 1381), null);
	unit_test_pkg.AssertAreEqual(DATE'2015-09-01', period_pkg.GetPeriodDate(C_ANNUAL_SET, 1383), null);

	-- Weekly
	unit_test_pkg.AssertAreEqual(DATE'2012-09-02', period_pkg.GetPeriodDate(C_WEEKLY_SET, 1180), null);
	unit_test_pkg.AssertAreEqual(DATE'2017-10-08', period_pkg.GetPeriodDate(C_WEEKLY_SET, 1445), null);
	unit_test_pkg.AssertAreEqual(DATE'2017-10-15', period_pkg.GetPeriodDate(C_WEEKLY_SET, 1446), null);
	unit_test_pkg.AssertAreEqual(DATE'2012-12-16', period_pkg.GetPeriodDate(C_WEEKLY_SET, 1195), null);
	unit_test_pkg.AssertAreEqual(DATE'2012-12-23', period_pkg.GetPeriodDate(C_WEEKLY_SET, 1196), null);
	unit_test_pkg.AssertAreEqual(DATE'2013-01-06', period_pkg.GetPeriodDate(C_WEEKLY_SET, 1197), null);

	-- 13p
	unit_test_pkg.AssertAreEqual(DATE'2012-09-16', period_pkg.GetPeriodDate(C_13_PERIOD_SET, 46), null); -- 2013/07
	unit_test_pkg.AssertAreEqual(DATE'2012-10-14', period_pkg.GetPeriodDate(C_13_PERIOD_SET, 47), null); -- 2013/08
	unit_test_pkg.AssertAreEqual(DATE'2016-03-06', period_pkg.GetPeriodDate(C_13_PERIOD_SET, 91), null); -- 2016/13

	-- 5p
	unit_test_pkg.AssertAreEqual(DATE'2015-01-18', period_pkg.GetPeriodDate(C_5P_ANNUAL_SET, 575), null); 
	unit_test_pkg.AssertAreEqual(DATE'2015-04-01', period_pkg.GetPeriodDate(C_5P_ANNUAL_SET, 576), null); 
	unit_test_pkg.AssertAreEqual(DATE'2015-06-13', period_pkg.GetPeriodDate(C_5P_ANNUAL_SET, 577), null); 
END;

PROCEDURE TestPeriodDatesCannotBeInvalid
AS
BEGIN
	BEGIN
		INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm)
		VALUES (1,1,2099, DATE'2099-12-01',DATE'2099-01-01');
		unit_test_pkg.TestFail('Insert of bad data should not succeed.'); 
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN NULL;
	END;
END;


PROCEDURE SetUp
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE TearDown
AS
BEGIN
	NULL;
END;

PROCEDURE CreateAnnualPeriodSet(in_set_id IN csr.period_set.period_set_id%type)
AS
BEGIN
	-- Otherwise normal setup, but starting in Jully
	INSERT INTO csr.period_set (period_set_id, annual_periods, label)
	VALUES (in_set_id, 1, 'Test set');
	
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (in_set_id, 1, 'Jan', date '1901-01-01', date '1901-02-01');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (in_set_id, 2, 'Feb', date '1901-02-01', date '1901-03-01');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (in_set_id, 3, 'Mar', date '1901-03-01', date '1901-04-01');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (in_set_id, 4, 'Apr', date '1901-04-01', date '1901-05-01');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (in_set_id, 5, 'May', date '1901-05-01', date '1901-06-01');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (in_set_id, 6, 'Jun', date '1901-06-01', date '1901-07-01');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (in_set_id, 7, 'Jul', date '1900-07-01', date '1900-08-01');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (in_set_id, 8, 'Aug', date '1900-08-01', date '1900-09-01');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (in_set_id, 9, 'Sep', date '1900-09-01', date '1900-10-01');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (in_set_id, 10, 'Oct', date '1900-10-01', date '1900-11-01');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (in_set_id, 11, 'Nov', date '1900-11-01', date '1900-12-01');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (in_set_id, 12, 'Dec', date '1900-12-01', date '1901-01-01');
	
	-- months
	INSERT INTO csr.period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES (in_set_id, 1, '{0:PL} {0:YYYY}', '{0:PL} {0:YYYY} - {1:PL} {1:YYYY}', 'Monthly', '{0:PL}');
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 1, 1, 1);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 1, 2, 2);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 1, 3, 3);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 1, 4, 4);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 1, 5, 5);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 1, 6, 6);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 1, 7, 7);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 1, 8, 8);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 1, 9, 9);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 1, 10, 10);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 1, 11, 11);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 1, 12, 12);
		
	-- quarters
	INSERT INTO csr.period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES (in_set_id, 2, 'Q{0:I} {0:YYYY}', 'Q{0:I} {0:YYYY} - Q{1:I} {1:YYYY}', 'Quarterly', 'Q{0:I}');
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 2, 1, 3);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 2, 4, 6);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 2, 7, 9);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 2, 10, 12);
	
	-- halves
	INSERT INTO csr.period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES (in_set_id, 3, 'H{0:I} {0:YYYY}', 'H{0:I} {0:YYYY} - H{1:I} {1:YYYY}', 'Half-yearly', 'H{0:I}');
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 3, 1, 6);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 3, 7, 12);

	-- years
	INSERT INTO csr.period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES (in_set_id, 4, '{0:YYYY}', '{0:YYYY} - {1:YYYY}', 'Annually', 'Year');
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (in_set_id, 4, 1, 12);
END;

PROCEDURE CreateAnnual5PeriodSet(in_set_id IN csr.period_set.period_set_id%type)
AS
BEGIN
	-- Split the year into 5 periods of 73 days (yes, this is completly contrived)
	INSERT INTO csr.period_set (period_set_id, annual_periods, label)
		VALUES (in_set_id, 1, 'Annual repeating 5 period');

	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm) VALUES (in_set_id, 1, 'P1', DATE'1900-04-01', DATE'1900-06-13');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm) VALUES (in_set_id, 2, 'P2', DATE'1900-06-13', DATE'1900-08-25');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm) VALUES (in_set_id, 3, 'P3', DATE'1900-08-25', DATE'1900-11-06');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm) VALUES (in_set_id, 4, 'P4', DATE'1900-11-06', DATE'1901-01-18');
	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm) VALUES (in_set_id, 5, 'P5', DATE'1901-01-18', DATE'1901-04-01');
	
	INSERT INTO csr.period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
		VALUES (in_set_id, 1, '{0:PL} {0:YYYY}', '{0:PL} {0:YYYY} - {1:PL} {1:YYYY}', 'Period', '{0:PL}');

	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
		VALUES (in_set_id, 1, 1, 1);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
		VALUES (in_set_id, 1, 2, 2);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
		VALUES (in_set_id, 1, 3, 3);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
		VALUES (in_set_id, 1, 4, 4);
	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
		VALUES (in_set_id, 1, 5, 5);
END;

PROCEDURE CreateWeeklyPeriodSet(in_set_id IN csr.period_set.period_set_id%type)
AS
	v_dtm date := date '1990-01-07'; -- sun 7th jan
	v_end_dtm date;
	v_week number := 1;
BEGIN
	insert into csr.period_set (app_sid, period_set_id, annual_periods, label)
	select sys_context('security', 'app'), in_set_id, 0, 'Weeks'
	  from dual;
	for i in 1 .. 52 loop
		insert into csr.period (period_set_id, period_id, label)
		values (in_set_id, i, 'Week '||i);
	end loop;
	while v_dtm < date '2021-01-01' loop
		--dbms_output.put_line(v_dtm || ' to ' || (v_dtm+7) || ' year ' || extract(year from v_dtm) || ' week ' || v_week);
		
		-- last week might be long
		v_end_dtm := v_dtm + 7;
		if v_week = 52 and extract(year from v_dtm) = extract(year from v_end_dtm) then
			v_end_dtm := v_end_dtm + 7;
		end if;
		
		insert into csr.period_dates (period_set_id, period_id, year, start_dtm, end_dtm)
		values (in_set_id, v_week, extract(year from v_dtm), v_dtm, v_end_dtm);
		
		if extract(year from (v_end_dtm)) != extract(year from v_dtm) then
			v_week := 1;
		else
			v_week := v_week + 1;		
		end if;
		v_dtm := v_end_dtm;
	end loop;

	insert into csr.period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	values (in_set_id, 1, '{0:PL} {0:YYYY}', '{0:PL} {0:YYYY} - {1:PL} {1:YYYY}', 'Week', '{0:PL}');
	for i in 1 .. 52 loop
		insert into csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
		values (in_set_id, 1, i, i);
	end loop;

	insert into csr.period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	values (in_set_id, 2, '{0:YYYY}', '{0:YYYY} - {1:YYYY}', 'Year', 'Year');

	insert into csr.period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	values (in_set_id, 2, 1, 52);
END;

PROCEDURE Create13PeriodSet(in_set_id IN csr.period_set.period_set_id%type)
AS 
BEGIN
	-- This is a straight clone of firstgroup's period setup
	INSERT INTO csr.period_set (period_set_id,annual_periods,label) VALUES (in_set_id, 0, 'Rail periods');

	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,1,'RP01',null,null);
	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,2,'RP02',null,null);
	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,3,'RP03',null,null);
	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,4,'RP04',null,null);
	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,5,'RP05',null,null);
	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,6,'RP06',null,null);
	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,7,'RP07',null,null);
	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,8,'RP08',null,null);
	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,9,'RP09',null,null);
	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,10,'RP10',null,null);
	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,11,'RP11',null,null);
	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,12,'RP12',null,null);
	INSERT INTO csr.period (period_set_id,period_id,label,start_dtm,end_dtm) VALUES (in_set_id,13,'RP13',null,null);

	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,1,2010, DATE'2009-04-01',DATE'2009-05-03');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,2,2010, DATE'2009-05-03',DATE'2009-05-31');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,3,2010, DATE'2009-05-31',DATE'2009-06-28');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,4,2010, DATE'2009-06-28',DATE'2009-07-26');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,5,2010, DATE'2009-07-26',DATE'2009-08-23');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,6,2010, DATE'2009-08-23',DATE'2009-09-20');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,7,2010, DATE'2009-09-20',DATE'2009-10-18');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,8,2010, DATE'2009-10-18',DATE'2009-11-15');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,9,2010, DATE'2009-11-15',DATE'2009-12-13');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,10,2010,DATE'2009-12-13',DATE'2010-01-10');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,11,2010,DATE'2010-01-10',DATE'2010-02-07');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,12,2010,DATE'2010-02-07',DATE'2010-03-07');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,13,2010,DATE'2010-03-07',DATE'2010-04-01');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,1,2011, DATE'2010-04-01',DATE'2010-05-02');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,2,2011, DATE'2010-05-02',DATE'2010-05-30');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,3,2011, DATE'2010-05-30',DATE'2010-06-27');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,4,2011, DATE'2010-06-27',DATE'2010-07-25');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,5,2011, DATE'2010-07-25',DATE'2010-08-22');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,6,2011, DATE'2010-08-22',DATE'2010-09-19');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,7,2011, DATE'2010-09-19',DATE'2010-10-17');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,8,2011, DATE'2010-10-17',DATE'2010-11-14');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,9,2011, DATE'2010-11-14',DATE'2010-12-12');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,10,2011,DATE'2010-12-12',DATE'2011-01-09');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,11,2011,DATE'2011-01-09',DATE'2011-02-06');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,12,2011,DATE'2011-02-06',DATE'2011-03-06');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,13,2011,DATE'2011-03-06',DATE'2011-04-01');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,1,2012, DATE'2011-04-01',DATE'2011-05-01');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,2,2012, DATE'2011-05-01',DATE'2011-05-29');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,3,2012, DATE'2011-05-29',DATE'2011-06-26');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,4,2012, DATE'2011-06-26',DATE'2011-07-24');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,5,2012, DATE'2011-07-24',DATE'2011-08-21');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,6,2012, DATE'2011-08-21',DATE'2011-09-18');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,7,2012, DATE'2011-09-18',DATE'2011-10-16');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,8,2012, DATE'2011-10-16',DATE'2011-11-13');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,9,2012, DATE'2011-11-13',DATE'2011-12-11');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,10,2012,DATE'2011-12-11',DATE'2012-01-08');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,11,2012,DATE'2012-01-08',DATE'2012-02-05');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,12,2012,DATE'2012-02-05',DATE'2012-03-04');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,13,2012,DATE'2012-03-04',DATE'2012-04-01');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,1,2013, DATE'2012-04-01',DATE'2012-04-29');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,2,2013, DATE'2012-04-29',DATE'2012-05-27');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,3,2013, DATE'2012-05-27',DATE'2012-06-24');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,4,2013, DATE'2012-06-24',DATE'2012-07-22');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,5,2013, DATE'2012-07-22',DATE'2012-08-19');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,6,2013, DATE'2012-08-19',DATE'2012-09-16');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,7,2013, DATE'2012-09-16',DATE'2012-10-14');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,8,2013, DATE'2012-10-14',DATE'2012-11-11');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,9,2013, DATE'2012-11-11',DATE'2012-12-09');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,10,2013,DATE'2012-12-09',DATE'2013-01-06');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,11,2013,DATE'2013-01-06',DATE'2013-02-03');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,12,2013,DATE'2013-02-03',DATE'2013-03-03');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,13,2013,DATE'2013-03-03',DATE'2013-04-01');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,1,2014, DATE'2013-04-01',DATE'2013-04-28');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,2,2014, DATE'2013-04-28',DATE'2013-05-26');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,3,2014, DATE'2013-05-26',DATE'2013-06-23');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,4,2014, DATE'2013-06-23',DATE'2013-07-21');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,5,2014, DATE'2013-07-21',DATE'2013-08-18');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,6,2014, DATE'2013-08-18',DATE'2013-09-15');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,7,2014, DATE'2013-09-15',DATE'2013-10-13');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,8,2014, DATE'2013-10-13',DATE'2013-11-10');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,9,2014, DATE'2013-11-10',DATE'2013-12-08');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,10,2014,DATE'2013-12-08',DATE'2014-01-05');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,11,2014,DATE'2014-01-05',DATE'2014-02-02');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,12,2014,DATE'2014-02-02',DATE'2014-03-02');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,13,2014,DATE'2014-03-02',DATE'2014-04-01');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,1,2015, DATE'2014-04-01',DATE'2014-04-27');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,2,2015, DATE'2014-04-27',DATE'2014-05-25');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,3,2015, DATE'2014-05-25',DATE'2014-06-22');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,4,2015, DATE'2014-06-22',DATE'2014-07-20');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,5,2015, DATE'2014-07-20',DATE'2014-08-17');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,6,2015, DATE'2014-08-17',DATE'2014-09-14');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,7,2015, DATE'2014-09-14',DATE'2014-10-12');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,8,2015, DATE'2014-10-12',DATE'2014-11-09');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,9,2015, DATE'2014-11-09',DATE'2014-12-07');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,10,2015,DATE'2014-12-07',DATE'2015-01-04');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,11,2015,DATE'2015-01-04',DATE'2015-02-01');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,12,2015,DATE'2015-02-01',DATE'2015-03-01');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,13,2015,DATE'2015-03-01',DATE'2015-04-01');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,1,2016, DATE'2015-04-01',DATE'2015-05-03');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,2,2016, DATE'2015-05-03',DATE'2015-05-31');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,3,2016, DATE'2015-05-31',DATE'2015-06-28');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,4,2016, DATE'2015-06-28',DATE'2015-07-26');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,5,2016, DATE'2015-07-26',DATE'2015-08-23');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,6,2016, DATE'2015-08-23',DATE'2015-09-20');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,7,2016, DATE'2015-09-20',DATE'2015-10-18');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,8,2016, DATE'2015-10-18',DATE'2015-11-15');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,9,2016, DATE'2015-11-15',DATE'2015-12-13');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,10,2016,DATE'2015-12-13',DATE'2016-01-10');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,11,2016,DATE'2016-01-10',DATE'2016-02-07');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,12,2016,DATE'2016-02-07',DATE'2016-03-06');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,13,2016,DATE'2016-03-06',DATE'2016-04-01');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,1,2017, DATE'2016-04-01',DATE'2016-05-01');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,2,2017, DATE'2016-05-01',DATE'2016-05-29');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,3,2017, DATE'2016-05-29',DATE'2016-06-26');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,4,2017, DATE'2016-06-26',DATE'2016-07-24');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,5,2017, DATE'2016-07-24',DATE'2016-08-21');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,6,2017, DATE'2016-08-21',DATE'2016-09-18');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,7,2017, DATE'2016-09-18',DATE'2016-10-16');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,8,2017, DATE'2016-10-16',DATE'2016-11-13');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,9,2017, DATE'2016-11-13',DATE'2016-12-11');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,10,2017,DATE'2016-12-11',DATE'2017-01-08');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,11,2017,DATE'2017-01-08',DATE'2017-02-05');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,12,2017,DATE'2017-02-05',DATE'2017-03-05');
	INSERT INTO csr.period_dates (period_set_id,period_id,year,start_dtm,end_dtm) VALUES (in_set_id,13,2017,DATE'2017-03-05',DATE'2017-03-31');

	INSERT INTO csr.period_interval (period_set_id,period_interval_id,single_interval_label,multiple_interval_label,label,single_interval_no_year_label) 
		VALUES (in_set_id,1,'{0:PL} {0:YYYY/ZZ}','{0:PL} {0:YYYY} - {1:PL} {1:YYYY}','Period','{0:PL}');
	INSERT INTO csr.period_interval (period_set_id,period_interval_id,single_interval_label,multiple_interval_label,label,single_interval_no_year_label)
		VALUES (in_set_id,2,'Q{0:I} {0:YYYY/ZZ}','Q{0:I} {0:YYYY} - Q{1:I} {1:YYYY}','Quarter','Q{0:I}');
	INSERT INTO csr.period_interval (period_set_id,period_interval_id,single_interval_label,multiple_interval_label,label,single_interval_no_year_label)
		VALUES (in_set_id,3,'{0:YYYY/ZZ}','{0:YYYY} - {1:YYYY}','Year','Whole year');

	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,1,1);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,2,1,3);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,3,1,13);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,2,2);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,3,3);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,4,4);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,2,4,6);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,5,5);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,6,6);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,7,7);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,2,7,9);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,8,8);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,9,9);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,10,10);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,2,10,13);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,11,11);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,12,12);
	INSERT INTO csr.period_interval_member (period_set_id,period_interval_id,start_period_id,end_period_id) VALUES (in_set_id,1,13,13);
END;

PROCEDURE DeletePeriodSet(in_set_id IN NUMBER)
AS
BEGIN
	DELETE FROM csr.period_interval_member WHERE period_set_id = in_set_id;
	DELETE FROM csr.period_interval WHERE period_set_id = in_set_id;
	DELETE FROM csr.period_dates WHERE period_set_id = in_set_id;
	DELETE FROM csr.period WHERE period_set_id = in_set_id;
	DELETE FROM csr.period_set WHERE period_set_id = in_set_id;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	-- Log on to test site
	security.user_pkg.logonadmin(v_site_name);

	CreateAnnualPeriodSet(C_ANNUAL_SET);
	CreateWeeklyPeriodSet(C_WEEKLY_SET);
	Create13PeriodSet(C_13_PERIOD_SET);
	CreateAnnual5PeriodSet(C_5P_ANNUAL_SET);
END;

PROCEDURE TearDownFixture
AS
BEGIN
	-- Clear down data after all tests have ran
	DeletePeriodSet(C_ANNUAL_SET);
	DeletePeriodSet(C_WEEKLY_SET);
	DeletePeriodSet(C_13_PERIOD_SET);
	DeletePeriodSet(C_5P_ANNUAL_SET);
END;

END test_period_pkg;
/
