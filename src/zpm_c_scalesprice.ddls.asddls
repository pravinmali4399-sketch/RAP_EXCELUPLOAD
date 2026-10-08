@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection view for scales price'
@Metadata.allowExtensions: true
define view entity ZPM_C_SCALESPRICE
//  provider contract transactional_query
  as projection on ZPM_I_SCALESPRICE

{
  key Id,
      SalesPriceUuid,
      MinimumQuantity,
      Unit,
      ScalePrice,
      currency,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      /* Associations */
      _Parent : redirected to parent ZPM_C_SALES_PRICE
}
