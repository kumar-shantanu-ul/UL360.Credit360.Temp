del basedata_db.log

cd basedata


sqlplus supplier/supplier@aspen @common_basedata bs.credit360.com

sqlplus supplier/supplier@aspen @tags_basedata bs.credit360.com

sqlplus supplier/supplier@aspen @product_info_basedata bs.credit360.com
sqlplus supplier/supplier@aspen @formulation_basedata bs.credit360.com

sqlplus supplier/supplier@aspen @GT_audit_type_basedata bs.credit360.com
sqlplus supplier/supplier@aspen @packaging_basedata bs.credit360.com
sqlplus supplier/supplier@aspen @product_design_basedata bs.credit360.com
sqlplus supplier/supplier@aspen @food_basedata bs.credit360.com
                                
sqlplus supplier/supplier@aspen @score_type_basedata bs.credit360.com
sqlplus supplier/supplier@aspen @supplier_relation_basedata bs.credit360.com
sqlplus supplier/supplier@aspen @transport_basedata bs.credit360.com

cd ..

