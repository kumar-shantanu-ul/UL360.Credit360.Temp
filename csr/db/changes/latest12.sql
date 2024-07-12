-- Please update version.sql too -- this keeps clean builds in sync
define version=12
@update_header

alter table ind add (
    AGGREGATE            VARCHAR2(24)       DEFAULT 'SUM' NOT NULL);


alter table ind add (
	calc_start_dtm_adjustment	number(10)	default 0 not null);

alter table ind add (
	default_interval	char(1)	default 'y' not null);


declare
begin
	for r in ( 
		select ind_sid from ind 
		 where calc_xml like '%ytd%' 
		 or calc_xml like '%rollingyear%' 
		 or calc_xml like '%previousperiod%' 
		 or calc_xml like '%periodpreviousyear%'
         )
     loop
     	update ind set calc_Start_dtm_adjustment = -12 where ind_sid = r.ind_sid;
		for r2 in (
        	select ind_sid from table (calc_pkg.GetCalcsUsingIndAsTable(r.ind_sid))
            )
        loop
	     	update ind set calc_Start_dtm_adjustment = -12 where ind_sid = r2.ind_sid;        	
        end loop;        
     end loop;
end;
/

@update_tail
