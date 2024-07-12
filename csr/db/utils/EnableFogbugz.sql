ACCEPT host CHAR                            PROMPT 'Host (e.g. clientname.credit360.com)                                            :  '
ACCEPT customer_fogbugz_project_id NUMBER   PROMPT 'Customer fogbugz project id (old id for pulling historical cases, or 0 if none) :  '
ACCEPT customer_fogbugz_area CHAR           PROMPT 'Customer fogbugz area (text of the new area to search for in XLog projects)     :  '

begin
	security.user_pkg.logonadmin('&&host');
	csr.enable_pkg.EnableFogbugz('&&customer_fogbugz_project_id', '&&customer_fogbugz_area');
	commit;
end;
/
exit;