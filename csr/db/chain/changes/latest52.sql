define version=52
@update_header

/***********************************************************
	RUN OLD UPDATE HEADER
***********************************************************/
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

DECLARE
	v_version	version.db_version%TYPE;
	v_user		varchar2(30);
BEGIN
	SELECT user
	  INTO v_user
	  FROM dual;
	IF v_user <> 'CHAIN' THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||' CANNOT BE APPLIED TO THE '||v_user||' SCHEMA =======');
	END IF;
	SELECT db_version INTO v_version FROM version;
	IF v_version >= &version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> &version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/
/**********************************************************/

begin
	for r in (select constraint_name from user_constraints where constraint_name='PK45' and table_name = 'VERSION') loop
		execute immediate 'alter table version drop constraint pk45';
	end loop;
	for r in (select constraint_name from user_constraints where table_name='VERSION' and constraint_type = 'P') loop
		execute immediate 'alter table version drop primary key drop index';
	end loop;
end;
/

declare
	v_cnt number;
begin
	select count(*)
	  into v_cnt
	  from user_tab_columns
	 where table_name='VERSION' and column_name='PART';
	 
	if v_cnt = 0 then
		execute immediate 'alter table version add (part varchar2(100))';
		execute immediate 'update version set part = ''trunk''';
	end if;
	for r in (select column_name from user_tab_columns where table_name='VERSION' and column_name='PART' and nullable='Y') loop
		execute immediate 'alter table version modify part not null';
	end loop;		
	execute immediate 'begin select count(*) into :x from version where part=''rap4''; end;' using out v_cnt;
	if v_cnt = 0 then
		execute immediate 'insert into version (db_version, part) values (0, ''rap4'')';
	end if;
end;
/

@update_tail

