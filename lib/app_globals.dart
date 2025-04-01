
enum SubscriptionType {live, sandbox}


const revenueCatKey = 'appl_kouZaGpqPtKUTMsQldiVYJpXAej';
const revenueCatAndroidKey = 'goog_JcKdiOsktzDIZLWBEcdoMxSmFYN';
const revenueCatFooterText = """A purchase will be applied to your account upon confirmation of the amount selected. Subscriptions will automatically renew unless canceled within 24 hours of the end of the current period. You can cancel any time using your account settings. Any unused portion of a free trial will be forfeited if you purchase a subscription.""";
const revenueCatEntitlementID = 'ENTITLEMENT_ID';

class AppGlobals {
  // Set to live mode for production
  static SubscriptionType subscriptionType = SubscriptionType.live;
}
