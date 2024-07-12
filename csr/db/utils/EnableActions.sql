-- This is for Scorecarding, formerly called Actions (*NOT* for Actions,
-- formerly called Issues)
--
-- If you're running this, you probably also want to apply the translations
-- from C:\cvs\csr\db\actions\tr_scorecards.xlsx
--
-- See FB43940 for RK's commentary

ACCEPT host CHAR     PROMPT 'Host (e.g. clientname.credit360.com)  :  '

begin
	security.user_pkg.logonadmin('&&host');
	csr.enable_pkg.EnableActions;
	commit;
end;
/
exit;
