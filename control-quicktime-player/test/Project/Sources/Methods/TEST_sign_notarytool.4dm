//%attributes = {}
/*
Appleアカウント
*/

$credentials:=New object:C1471
$credentials.username:="keisuke.miyako@4d.com"

/*
キーチェーンに登録したApp用パスワードおよびプロフィール
*/

$credentials.password:="@keychain:altool"
$credentials.keychainProfile:="notarytool"

$signApp:=cs:C1710.SignApp.new($credentials)

/*
署名するアプリのパス
*/

$version:=Application version:C493($build)
$folderName:="4D v"+Substring:C12($version; 1; 2)+"."+Substring:C12($version; 4; 1)
$applicationsFolder:=Folder:C1567(fk applications folder:K87:20)
$app:=$applicationsFolder.folder($folderName).folder("4D.app")

/*
署名と公証
*/

$status:=New object:C1471
$status.sign:=$signApp.sign($app)
$status.archive:=$signApp.archive($app)
If ($status.archive.success)
	$status.notarize:=$signApp.notarize($status.archive.file)
End if 