declare
	v_host		csr.customer.host%TYPE := 'virginunite.credit360.com';
begin
    FOR r IN (SELECT scheme_sid FROM scheme s, csr.customer c where s.app_sid = c.app_sid and c.host=v_host)
    LOOP
        insert into custom_field values(r.scheme_sid,4,'Non-company time given',null,0,'Enter the number of hours given by outsourced employees, temps, contractors or employees'' non-work time - the value will be calculated automatically','hours_contractors_and_temps',0,null,'leverage');
        insert into custom_field values(r.scheme_sid,2,'Amount given by customers (as a result of the activity)',null,0,null,'leverage_customers',1,null,'leverage');
        insert into custom_field values(r.scheme_sid,7,'Any 3rd party in-kind giving',null,0,'Any in-kind donation by staff or any 3rd party generated as a result of the activity. Estimate value in £.','leverage_inkind',1,null,'leverage');
        insert into custom_field values(r.scheme_sid,6,'Amount given by any other 3rd party (as a result of the activity)',null,0,null,'leverage_other',1,null,'leverage');
        insert into custom_field values(r.scheme_sid,3,'Amount given by suppliers (as a result of the activity)',null,0,null,'leverage_suppliers',1,null,'leverage');
        insert into custom_field values(r.scheme_sid,8,'Total leverage','staff_fundraising + leverage_customers + leverage_suppliers + leverage_other + leverage_inkind + (hours_contractors_and_temps * contractor_hourly_rate)',0,'Automatically calculated when you save','leverage_total',1,null,'leverage');
        insert into custom_field values(r.scheme_sid,1,'Amount fundraised by staff',null,0,null,'staff_fundraising',1,null,'leverage');
        insert into custom_field values(r.scheme_sid,9,'Total contributions','cash_value + (time_hours * staff_hourly_rate) + inkind_value + staff_fundraising + leverage_customers + leverage_suppliers + leverage_other + leverage_inkind + (hours_contractors_and_temps * contractor_hourly_rate)',0,'Automatically calculated when you save','total_company_contrib',1,'The sum of all company contributions and leveraged contributions',null);
        insert into custom_field values(r.scheme_sid,10,'Total company contributions','cash_value + (time_hours * staff_hourly_rate) + inkind_value',0,null,'total_contributions',1,'This is the total of all cash, time and stuff given by the company','inkind');
        insert into custom_field values(r.scheme_sid,5,'Value of time given','time_hours * staff_hourly_rate',0,'Automatically calculated when you save','value_of_time_given',1,null,'time');
    END LOOP;
end;
/
