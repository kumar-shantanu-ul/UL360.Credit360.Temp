-- Please update version.sql too -- this keeps clean builds in sync
define version=968
@update_header

declare
	v_user varchar2(30) := 'CHEM';
	v_synonyms varchar2(30) := 'Y';
	type t_pkgs is table of varchar2(30);
	v_list t_pkgs;
	i integer;
	object_exists EXCEPTION;
	PRAGMA EXCEPTION_INIT(object_exists,-955);	
begin
	v_list := t_pkgs(
		'ACL_PKG', 'Y',
		'ACT_PKG', 'Y',
		'ATTRIBUTE_PKG', 'Y',
		'BITWISE_PKG', 'Y',
		'CLASS_PKG', 'Y',
		'GROUP_PKG', 'Y',
		'SECURABLEOBJECT_PKG', 'Y',
		'SECURITY_PKG', 'Y',
		'USER_PKG', 'Y',
		'WEB_PKG', 'Y',
		'SOFTLINK_PKG', 'N',
		'ACCOUNTPOLICY_PKG', 'N',
		'ACCOUNTPOLICYHELPER_PKG', 'N',
		'SESSION_PKG', 'N',
		'MENU_PKG', 'N',
		'CONN_PKG', 'N',
		'T_ORDERED_SID_ROW', 'N',
		'T_ORDERED_SID_TABLE', 'N'
	);

	i := 0;
	loop
		execute immediate 'grant execute on SECURITY.'||v_list(1 + i * 2)||' to '||v_user;
		if v_list(i * 2 + 2) = 'Y' and v_synonyms = 'Y' then
			begin
				execute immediate 'create synonym '||v_user||'.'||v_list(1 + i * 2)||' for SECURITY.'||v_list(1 + i * 2);
			exception
				when object_exists then
					null;
			end;
		end if;
		i := i + 1;
		exit when i >= v_list.count / 2;
	end loop;
end;
/

@update_tail
