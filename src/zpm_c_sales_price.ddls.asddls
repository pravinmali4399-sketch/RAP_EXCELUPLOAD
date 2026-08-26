@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection view for sales price'
@Metadata.allowExtensions: true
define root view entity ZPM_C_SALES_PRICE 
provider contract transactional_query
as projection on ZPM_I_SALES_PRICE

{
key uuid,
    SalesOrg,
    DistrChannel,
    Material,
    Customer,
    ValidFrom,
    ValidTo,
    SalesPrice,
    Currency,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt
}
