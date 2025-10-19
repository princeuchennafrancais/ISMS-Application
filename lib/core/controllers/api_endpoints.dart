class APIEndpoints {
  static String baseUrl = "https://api.ceemact.com/";

  static String loginUserEndpoint = "${baseUrl}auth_users/login";
  static String logoutUserEndpoint = "${baseUrl}auth_api/logout";
  static String createWalletEndpoint = "${baseUrl}wallet_api/createWallet";
  static String getProfileEndpoint = "${baseUrl}student_api/getProfile";
  static String getBalanceEndpoint = "${baseUrl}wallet_api/getWalletBalance";
  static String CreatePinEndpoint = "${baseUrl}wallet_api/createPin";
  static String ChangePinEndpoint = "${baseUrl}wallet_api/changePin";
  static String getWalletDetailsEndpoint = "${baseUrl}wallet_api/getWalletDetails";
  static String getBanksEndpoint = "${baseUrl}wallet_api/getBanks";
  static String getBanksDetailsEndpoint = "https://api.ceemact.com/wallet_api/getBankDetails";
  static String getTransactionHistEndpoint = "${baseUrl}wallet_api/getWalletTransactions";
  static String makePaymentEndpoint = "${baseUrl}wallet_api/payout";
  static String notificationsEndpoint = "${baseUrl}notifications_api/getNewsletters";
  static String withdrawFromWallet = "${baseUrl}wallet_api/withdraw";
}
