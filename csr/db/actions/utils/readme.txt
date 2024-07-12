There are some useful scripts for helping set-up initiatives in:

...\csr\db\actions\utils

I've put them there rather than under csr\db\utils as they have to be run using the actions db user once actions has been enables using csr\db\utils\enableActions.sql

enableInitiatives.sql Just updates customer options, creates user groups, roles, menus etc. but does not actually create any base data.

You then have the choice of creating some base data yourself (long winded), creating some standard data using initiativesDemoBaseData.sql or just porting the base data from another site using portInitiatives.sql (porting the base is the easiest thing to do).

If you cock it up and want to start from scratch then you can zap the lot using zapInitiatives.sql, be warned this will delete any data too,

BE WARNED THAT ZAPPING INITIATIVES WILL ALSO DELETE ANY ACTIONS PROJECTS AND DATA!!
