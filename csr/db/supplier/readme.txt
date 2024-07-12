CREATE THE SITE (one off)
===============
Setup notes based on the assupmption that bs.credit360.com is your local site

Set up bs.credit360.com

-- does menus and security structure
cd c:\cvs\csr\db\supplier
sqlplus csr/csr@aspen @enableSupplier bs.credit360.com

BUILDING THE SUPPLIER DATABASE
=====================
The main supplier schema should now be created as part of the overall db build process

ADDING IN THE MODULES
=======================
There are 3 modules, Wood, Natural Products and Green Tick. These can be cleaned / recreated as needed (locally!)

To add in other parts, e.g. 'wood':

cd C:\cvs\csr\db\supplier\wood
clean.bat

cd C:\cvs\csr\db\supplier\naturalProducts
clean.bat

cd C:\cvs\csr\db\supplier\greenTick
clean.bat

clean.bat should also run basedata in each case

ENABLING SUPPLIER FOR A CUSTOMER
================================

For Boots 
---------
cd c:\cvs\csr\db\supplier\boots
sqlplus supplier/supplier@aspen @enableForHost bs.credit360.com

To turn on 'wood' for a specific customer:

cd c:\cvs\csr\db\supplier\wood
sqlplus supplier/supplier@aspen @enableForHost bs.credit360.com

cd c:\cvs\csr\db\supplier\NaturalProducts
sqlplus supplier/supplier@aspen @enableForHost bs.credit360.com

cd c:\cvs\csr\db\supplier\greenTick
sqlplus supplier/supplier@aspen @enableForHost bs.credit360.com

For GT then run DoPCTagsforhost
sqlplus supplier/supplier@aspen @doPCTagsForHost bs.credit360.com

GENERATING THE DATABASE FROM ER/STUDIO
======================================
The model is structured as follows:

LOGICAL
|
|_ GENERIC
|  |_ CHAIN
|  |_ COMPANY
|  |_ PRODUCT
|  |_ QUESTIONNAIRES
|
|_ z GREENTICK
|_ z NATURAL PRODUCTS
|_ z NOVONORDISK
|_ z WOOD

PHYSICAL
|
|_ GENERIC
|_ z GREENTICK
|_ z NATURAL PRODUCTS
|_ z NOVONORDISK
|_ z WOOD


The GENERIC logical model has a number of submodels to make different parts clearer to understand and edit. Adding tables to the submodels (e.g. CHAIN) will automatically add tables to the GENERIC parent model.

This means that you can change the submodel, and then right-click on GENERIC and do a "Compare and merge" with the GENERIC physical model.

You should create different "create_schema.sql" scripts for each of the physical models in their respective folders (e.g. c:\cvs\csr\db\supplier\greentick\create_schema.sql). The specific parts (e.g. greentick) currenlty have "DROP TABLES" selected when creating them so that the clean script really does clean things. We might want to change this (since strictly speaking 'create_schema' is really 'clean_and_create_schema'), but it's just how it's done at the moment.

This means that someone can build supplier, without having to build all the greentick specific tables and stored procedures.

When you create new versions of the "create_schema.sql" files you can check you've done it correctly by doing a 'svn diff' on the new file - check that it shows the changes you're expecting and not a ton of other things that have changed because you've created the schema in a different way. ER/Studio is pretty crap and preserving settings, hence all this guff.

If in doubt, ask Richard.
