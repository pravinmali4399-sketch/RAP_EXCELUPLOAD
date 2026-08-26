@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Sales price'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZPM_I_SALES_PRICE
  as select from zpm_sales_price
{
  key id              as uuid,
      sales_org       as SalesOrg,
      distr_channel   as DistrChannel,
      material        as Material,
      customer        as Customer,
      valid_from      as ValidFrom,
      valid_to        as ValidTo,
      @Semantics.amount.currencyCode: 'Currency'
      sales_price     as SalesPrice,
      currency        as Currency,
      @Semantics.user.createdBy: true
      created_by      as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at      as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt
}
