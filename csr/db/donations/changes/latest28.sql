-- Please update version.sql too -- this keeps clean builds in sync
define version=28
@update_header

PROMPT compile donation package
@ ..\donation_pkg.sql
@ ..\donation_body.sql

PROMPT Recompiling invalid packages
@c:\cvs\aspen2\tools\recompile_packages.sql

@update_tail
