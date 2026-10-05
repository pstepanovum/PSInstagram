# PSInstagram
**Instagram without the addictive parts.**\
`Version v1.0.0` | `Tested on Instagram 449.0.0`

PSInstagram is an iOS tweak that turns Instagram into a messaging and people-finding app. The feed, reels, explore grid, suggestions and ads are gone by default, so there is nothing left to scroll. What stays: your DMs, your profile, posting, and search for finding and following people.

Where the feed used to be, there are two small games instead: mental math that levels up from `45 + 41` to logarithms and derivatives, and a five-letter word game for practicing English.

Sister projects: [PSLinkedIn](https://github.com/pstepanovum/PSLinkedIn), [PSYoutube](https://github.com/pstepanovum/PSYoutube) and [PSSoundcloud](https://github.com/pstepanovum/PSSoundcloud), the same idea for other apps.

---

## What you get

### Locked down by default
A fresh install starts distraction-free, without any setup:
- No home feed, no stories tray, no suggested posts, reels, accounts or Threads posts. Hiding the feed blocks everything in it, so new sections Instagram adds later (like "Expiring Stories") are hidden too
- No Reels tab, no swiping into it from Home, and reels can't be scrolled
- No explore grid, topic pills, trending searches, or recents and suggestions under the search bar
- No "Discover people" or "Suggested for you" on profiles
- No ads, no Meta AI

Every option can still be changed in the PSInstagram settings.

### Settings that don't slip
- Defaults are applied before any Instagram code runs, so a missing value always means "locked down"
- Settings are backed up to the iOS keychain and restored automatically after a reinstall
- Instagram's crash-recovery "safe mode" is disabled, so it can't reset anything

### Brain break
Shown on the home tab while the feed is hidden. Switch between the two games at the top.

**Math**
- Five correct answers per level, with new problem types as you level up: `+`, `−`, `×`, missing numbers, `÷`, mixed operations, squares, powers, percentages, logarithms, roots, derivatives and integrals

**Words**
- Guess the five-letter word in six tries. Green letters are in the right spot, orange ones are in the word but somewhere else
- Answers are common English words, guesses are checked against the iOS dictionary, and after each round **Define** opens the word in the iOS dictionary
- Its own on-screen keyboard shows which letters you've ruled out

Progress and stats for both games survive reinstalls, and the games can be turned off in settings.

### Everything else from SCInsta
PSInstagram keeps the full SCInsta feature set: downloading posts, reels and stories, keeping deleted messages, disabling read receipts and typing status, confirmation prompts for likes, follows and calls, tab bar customization, and more.

## Opening the settings
- **Profile → ☰ → Settings and activity → PSInstagram** (top right), or
- Hold **four fingers** anywhere on the screen for a second

## Installing
PSInstagram is sideloaded: you inject it into a decrypted Instagram IPA and sign that with your own certificate. It gets its own bundle ID (`com.pstepanovum.psinstagram`), so it installs next to the official Instagram app.

### Prerequisites
- Xcode with the command-line tools, and [Homebrew](https://brew.sh)
- [Theos](https://theos.dev/docs/installation) with the iOS 16.2 SDK in `~/theos/sdks` ([SDKs](https://github.com/xybp888/iOS-SDKs))
- [cyan](https://github.com/asdfzxcvbn/pyzule-rw) and [zsign](https://github.com/zhlynn/zsign)
- A decrypted Instagram IPA

> [!NOTE]
> Newer Theos versions ship a Logos change that breaks `%orig` inside macros. Pin Logos to the last working commit:
> ```sh
> cd ~/theos/vendor/logos && git checkout a62370066a97e36d59b200a9fa10c5091f5e8972
> ```

### Setup
```sh
git clone --recurse-submodules https://github.com/pstepanovum/PSInstagram
cd PSInstagram
mkdir -p packages certs
```
Then add:
- `packages/com.burbn.instagram.ipa`: the decrypted Instagram IPA
- `certs/dev.p12`: your signing certificate
- `certs/dev.mobileprovision`: its provisioning profile
- `certs/p12-password`: the certificate password

`packages/` and `certs/` are ignored by git.

### Build, sign and install
With your iPhone connected:
```sh
./dev.sh              # build, sign and install
./dev.sh --clean      # full rebuild first
./dev.sh --no-install # only create packages/PSInstagram-signed.ipa
BUNDLE_ID=com.example.instagram ./dev.sh   # use a different bundle ID
```

`dev.sh` signs with a minimal set of entitlements taken from your profile, because some reseller profiles contain malformed wildcard entitlements that crash apps.

To build an unsigned IPA for another signing tool, or a `.deb` for jailbroken devices:
```sh
./build.sh <sideload/rootless/rootful>
```

## Known limitations
- **Updating over an existing install can fail**, in which case `dev.sh` reinstalls it. Your PSInstagram settings come back from the keychain. Instagram may log you back in with your saved login info, or it may need a new login.
- **App extensions are removed** (widgets, share sheet, rich notifications), because a single-app provisioning profile can't sign them.
- **Use at your own risk.** Modified clients are against Instagram's terms of use, and frequent new logins from "new devices" can get an account temporarily restricted.

## Credits
PSInstagram is a fork of **[SCInsta](https://github.com/SoCuul/SCInsta) by SoCuul**, which is based on **[BHInstagram](https://github.com/BandarHL/BHInstagram) by BandarHL**. The original copyright notices are kept in [NOTICE](NOTICE).

Bundled libraries:
- [FLEXing](https://github.com/SoCuul/FLEXing) / [FLEX](https://github.com/FLEXTool/FLEX): in-app debugging
- [JGProgressHUD](https://github.com/JonasGessner/JGProgressHUD): progress overlays
- [fishhook](https://github.com/facebook/fishhook): symbol rebinding for the keychain fixes

## License
[GNU General Public License v3.0](LICENSE), the same license as SCInsta.
