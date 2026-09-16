// Licenses are injected at compile time with
// `--dart-define-from-file=.luxand.env.json` by the host application.
// Never place the actual Luxand serials in this source file.
const keyEnterpriseStandardAndroid = String.fromEnvironment(
  'LUXAND_ANDROID_KEY',
);

const keyIosStandard = String.fromEnvironment('LUXAND_IOS_KEY');

const lienceKey = keyEnterpriseStandardAndroid;
const lienceKeyIos = keyIosStandard;

const _android83RuntimeVerified = bool.fromEnvironment(
  'LUXAND_ANDROID_83_VERIFIED',
);
const _ios83RuntimeVerified = bool.fromEnvironment(
  'LUXAND_IOS_83_VERIFIED',
);

bool hasLuxandLicenseForCurrentPlatform({
  required bool isAndroid,
  required bool isIOS,
}) {
  if (isAndroid == isIOS) return false;
  final key = isAndroid ? keyEnterpriseStandardAndroid : keyIosStandard;
  return key.trim().isNotEmpty;
}

bool canUseLuxand83ForCurrentPlatform({
  required bool isAndroid,
  required bool isIOS,
}) {
  if (!hasLuxandLicenseForCurrentPlatform(
    isAndroid: isAndroid,
    isIOS: isIOS,
  )) {
    return false;
  }
  return isAndroid ? _android83RuntimeVerified : _ios83RuntimeVerified;
}
