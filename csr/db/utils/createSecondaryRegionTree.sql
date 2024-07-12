ACCEPT host CHAR                PROMPT 'Host (e.g. clientname.credit360.com)      :  '
ACCEPT secondaryTreeName CHAR   PROMPT 'Secondary Tree Name                       :  '

declare
begin
	security.user_pkg.logonadmin('&&host');
	csr.enable_pkg.CreateSecondaryRegionTree('&&secondaryTreeName');
	commit;
end;
/
exit;