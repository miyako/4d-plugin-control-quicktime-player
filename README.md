# 4d-plugin-control-quicktime-player
QuickTime PlayerをScriptingBridge APIで制御する

## はじめに

macOS Mojave以降，アプリやプログラムがカメラやマイクを使用するためには，システム環境設定の「セキュリティとプライバシー」でアクセスを許可しなければなりません。どんなアプリでも許可できるわけではなく，一定の条件を満たしている必要があります。

* *Info.plist*に[`NSCameraUsageDescription`](https://developer.apple.com/documentation/bundleresources/information_property_list/nscamerausagedescription?language=objc)キーが存在すること
* アプリが[*Hardened Runtime*](https://developer.apple.com/documentation/security/hardened_runtime?language=objc)オプション付き・セキュアなタイムスタンプ付き・でコード署名されていること
* コード署名*entitlements*の[`com.apple.security.device.audio-input`](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_device_audio-input?changes=l_2&language=objc)が`True`であること
* コード署名*entitlements*の[`com.apple.security.device.camera`](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_device_camera?language=objc)が`True`であること
* アプリがAppleの公証にパスしていること

これらの条件を満たしていないソフトウェアにカメラやマイクの使用を許可することはできません。

4Dはコード署名されており，公証もパスしていますが，カメラやマイクを使用するための*entitlements*や*Info.plist*キーが不足しているため，**カメラやマイクを使用することができません**。

カメラやマイクを使用するためには，Apple Developer ID（App Storeに出品せず，インターネット経由でアプリを配付しても良い開発者の資格）証明書で4Dをコード署名また公証する必要があります。Apple Developer IDは，Apple Developer Program - 1年間のメンバーシップ - 12,980円の特典です。

4Dから直接カメラやマイクを使用するのではなく，AppleScriptでQuickTime Playerなどのアプリをコントロール（オートメーション）する，という方法もあります。しかし，オートメーションを実行するためには，やはり，システム環境設定の「セキュリティとプライバシー」でアクセスを許可しなければなりません。下記の条件を満たしていることも必要です。

* *Info.plist*に[`NSAppleEventsUsageDescription`](https://developer.apple.com/documentation/bundleresources/information_property_list/nsappleeventsusagedescription)キーが存在すること
* アプリが[*Hardened Runtime*](https://developer.apple.com/documentation/security/hardened_runtime?language=objc)オプション付き・セキュアなタイムスタンプ付き・でコード署名されていること
* コード署名*entitlements*の[`com.apple.security.automation.apple-events`](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_automation_apple-events?changes=l_2&language=objc)が`True`であること
* アプリがAppleの公証にパスしていること

これらの条件を満たしていないソフトウェアにオートメーションを許可することはできません。

4Dはコード署名されており，公証もパスしていますが，オートメーションを実行するための*entitlements*や*Info.plist*キーが不足しているため，**AppleScriptで他のアプリをコントロールを使用することができません**。

---

Apple Developer Programの有効なメンバーシップがあれば，Apple Developer ID証明書を発行し，アプリをコード署名また公証することができます。

4Dのサインツール（シェルスクリプト）を利用する例題は[こちら](https://github.com/miyako/4d-utility-sign-app)

4Dコードで実行する例題は[こちら](https://github.com/miyako/4d-class-build-application)

アプリを配付するわけではなく，自分のMacで実行するだけであれば，[無料メンバーシップでコード署名する](https://github.com/miyako/4d-plugin-scard-v3/blob/main/with-free-account.md)ことができます。

## QuickTime Player Execute


```4d
status:=QuickTime Player Execute(command;options)
```

|Parameter|Type|Description|
|-|-|-|
|command|Integer||
|options|Object||
|status|Object||

### command

* new movie recording
* new audio recording
* new screen recording
* play
* start
* pause
* resume
* stop
* present
* open
* close
* save
* quit

