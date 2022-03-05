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

## セキュリティとプライバシーの仕組み

コード署名はアプリが改竄されていないことを保証するための仕組みです。署名されていないアプリはGateKeeperにより，実行を阻止されます。

公証は，アプリの開発元が信頼できることを確認するための仕組みです。デベロッパーは署名したアプリをAppleに提出し，チェックしてもらうことにより，公証を受けます。問題のあることが判明したアプリは公証を取り下げられ，世界中のMacで起動ができなくなります。公証を受けるためには，通常よりも厳しい基準のコード署名が必要です。具体的には，Hardened Runtimeおよびセキュアなタイムスタンプ付きの署名でなければなりません。Macは，インターネットからダウンロードしたアプリを初めた起動した時にAppleのサーバーに問い合わせてそのアプリが公証されているかどうかをチェックします。.dmgファイルおよび.pkgファイルは，このチェックを省略するために公証をアプリに埋め込むこともできます（ステープル）。.zipファイルに公証をステープルすることはできません。

連絡先やカレンダーのようなプライベート情報・カメラ・マイク・スマートカードリーダーなどの機能にアクセスするアプリは，そうする正当な目的をユーザーに説明し，ユーザーの同意を得なければなりません。ユーザーはいつでもコンセントを取り下げることができます。アクセスの目的は*Info.plist*に記述します。アクセスする対象はコード署名*entitlements*で特定します。

Apple Developer Programの有効なメンバーシップがあれば，Apple Developer ID証明書を発行し，アプリをコード署名また公証することができます。

4Dのサインツール（シェルスクリプト）を利用する例題は[こちら](https://github.com/miyako/4d-utility-sign-app)

4Dコードで実行する例題は[こちら](https://github.com/miyako/4d-class-build-application)

アプリを配付するわけではなく，自分のMacで実行するだけであれば，[無料メンバーシップでコード署名する](https://github.com/miyako/4d-plugin-scard-v3/blob/main/with-free-account.md)ことができます。

## プラグインの仕組み

* `com.apple.QuickTimePlayerX`のオートメーション許可をリクエストする

**注記**: [QuickTime Player](https://support.apple.com/ja-jp/guide/quicktime-player/welcome/mac)のバンドルIDは`com.apple.QuickTimePlayer`ではない（`X`（テン）がついている）

macOS 10.14 Catalina SDKのAPI[AEDeterminePermissionToAutomateTarget](https://developer.apple.com/documentation/coreservices/3025784-aedeterminepermissiontoautomatet?language=objc)を呼び出す

こんな感じの画面が表示される

<img width="260" alt="request" src="https://user-images.githubusercontent.com/1725068/156720171-47fc5852-b1fa-403c-8d06-ad8d5717196e.png">

4Dの*Info.plist*に`NSAppleEventsUsageDescription`がなければ画面は表示されない

コード署名*entitlements*の`com.apple.security.automation.apple-events`がなければ即クラッシュする（プライバシー侵害のためGateKeeperによって実行を阻止されたことがコンソースログに記録される）

アクセスを許可するとシステム環境設定の「セキュリティとプライバシー」にアプリが追加される

<img width="668" alt="granted" src="https://user-images.githubusercontent.com/1725068/156722667-d3a2960b-9f48-4d89-ad59-0c34f4c9b60b.png">

* [`applicationWithBundleIdentifier:`](https://developer.apple.com/documentation/scriptingbridge/sbapplication/1588086-applicationwithbundleidentifier?language=objc)でスクリプティングのハンドルを取得

**注記**: Appleのバグ?`applicationWithBundleIdentifier:`を繰り返し呼び出すとクラッシュする。内部的に`NSString*`が`Release`されているのかもしれない。回避策は`applicationWithProcessIdentifier:`

## QuickTime Player Execute


```4d
status:=QuickTime Player Execute(command;options)
```

|Parameter|Type|Description|
|-|-|-|
|command|Integer||
|options|Object||
|options.name|Object||
|options.path|Text|open save close|
|status|Object||
|status.name|Text|new movie recording|
|status.names|Collection of Text|open|

### command

* new movie recording
* new audio recording
* new screen recording
* play - 再生を開始
* start - 録画を開始
* stop - 再生を停止（録画には無効）
* pause - 再生を停止（録画には無効）
* resume - playと同じ
* present - 全画面モードに移行
* open - ファイルを開く（すでに開いていれば何もしない）
* close - saveと同じ
* save - 録画を終了〜ファイルに保存〜閉じる
* quit - アプリケーションを終了
