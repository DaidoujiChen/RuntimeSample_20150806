Dig
======
![image](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Art/messaging1.gif)

從官方的附圖開始講, 打開程式碼後, 在 `MainViewController.m` `Line 23` 打上一個 breakpoint 如附圖

![image](https://s3-ap-northeast-1.amazonaws.com/daidoujiminecraft/Daidouji/%E8%9E%A2%E5%B9%95%E5%BF%AB%E7%85%A7+2015-08-07+%E4%B8%8B%E5%8D%887.45.38.png)

app 運行後, 按 Run button, app 會停在這個斷點上, 這邊先說明, 我用的是 Xcode(9.1) + iPhone7(11.1) 模擬器, 所以下面所講的 address, register 之類的, 不一定會跟大家玩的相同, 不過大抵上會是一致的, 哈哈.

玩法一
======

小試一下

`````
(lldb) po normalObject
<NormalObject: 0x7fbec0d43fe0>
`````

用 `po` 可以打出 `normalObject` 這個變數, 他會告訴我們這個東西是什麼, 以及他所在的 address, 所以現在我們知道這個東西是 `NormalObject` 型別, 在 `0x7fbec0d43fe0` 上.

按照官方圖所說, 所謂的 `instance` 會有一個 `isa` 指向本身的 `class`, 所以我們鍵入

`````
(lldb) po normalObject->isa
NormalObject
`````

嗯...打印出來是 `NormalObject`, 不過我們怎麼知道他是個 `class` 而不是 `instance` 呢? 換個打法

`````
(lldb) print normalObject->isa
(Class) $2 = NormalObject
`````

我們改用 `print` 取代 `po`, `print` 比較泛用, `po` 為 `print object` 的意思, 特別針對 `object`, ok 所以我們相信 `instance` 的 `isa` 指向自身的 `class` 了, 然後, 圖裡面說, `class` 裡面有好多 `selector...address`, 我們來檢查看看,
我們先找到 `class` 的 `address`

`````
(lldb) print (void *)normalObject->isa
(void *) $3 = 0x00000001064d1e70
`````

然後我們開始挖他的 `Method` 

`````
(lldb) expr unsigned int $count;
(lldb) expr Method *$methods = (Method *)class_copyMethodList((Class)0x00000001064d1e70, &$count);
(lldb) expr for (int i = 0; i < $count; i++) { (void)NSLog(@"%s", (const char*)method_getName($methods[i])); }
2015-08-07 20:04:54.412 RuntimeSample_20150806[4764:16999] setStorage:
2015-08-07 20:04:54.413 RuntimeSample_20150806[4764:16999] storage
2015-08-07 20:04:54.413 RuntimeSample_20150806[4764:16999] .cxx_destruct
2015-08-07 20:04:54.413 RuntimeSample_20150806[4764:16999] invoke
2015-08-07 20:04:54.413 RuntimeSample_20150806[4764:16999] init
`````

這段長些, 首先宣告一個 `count` 變數, 準備來裝看有幾個 `Method`, 然後, 將 `0x00000001064d1e70` 這個 `class` 內所包含的 `Method` 都裝進 `methods` 變數, 最後, 用個迴圈打印出總共有哪些, 我們先用 `method_getName` 取得大家的名字, 這邊我們可以看到, 一共有五個, 前兩個是 `property` 幫我們產生的 setter / getter, 第三個是 `object` 要 `dealloc` 前會調用的一個自動產生的 `method`, 最後的 `invoke` 與 `init` 則是我們自己寫在 `NormalObject.m` 裡面的.

假設我們很想在這邊運行 `invoke` 這個 `method` 可以怎麼做? 因為圖裡面說 `class` 裡面包含 `selector...address` !! 所以相信我們也可以做到, 於是, 換個打印

`````
(lldb) expr for (int i = 0; i < $count; i++) { (void)NSLog(@"%p", (long)method_getImplementation($methods[i])); }
2015-08-07 20:12:22.659 RuntimeSample_20150806[4764:16999] 0x1064cf930
2015-08-07 20:12:22.660 RuntimeSample_20150806[4764:16999] 0x1064cf910
2015-08-07 20:12:22.660 RuntimeSample_20150806[4764:16999] 0x1064cf970
2015-08-07 20:12:22.660 RuntimeSample_20150806[4764:16999] 0x1064cf760
2015-08-07 20:12:22.660 RuntimeSample_20150806[4764:16999] 0x1064cf800
`````

我們從 `method_getName` 換打 `method_getImplementation`, 可以打出這些 `method` 的 `function pointer`, 真是美妙! 所以我們來的 `IMP` 裝 `invoke` 的 `function pointer` 試試

`````
(lldb) expr IMP $invokeIMP = (IMP)(0x1064cf760);
(lldb) print $invokeIMP(nil, nil);
2015-08-07 20:15:26.928 RuntimeSample_20150806[4764:16999] NormalObject Cost : 0.000008s
(id) $4 = 0x0000000000000001
`````

結果不但可以裝, 還可以跑, 其中 `$invokeIMP(nil, nil);` 的 `nil` 們, 是我懶惰而已, 囧, 一般上是要帶 `id` 與 `SEL` 給他. 嗯, 所以圖片沒有騙人, 我們反過來看所謂的 `instance` 內的 `instance variable` 在哪? 雖然, `instance variable` 是跟在 `instance` 身上, 不過記載著一共有什麼, 卻是在 `class` 內

`````
(lldb) expr Ivar *$ivars = (Ivar *)class_copyIvarList((Class)0x00000001064d1e70, &$count);
(lldb) expr for (int i = 0; i < $count; i++) { (void)NSLog(@"%s", (const char*)ivar_getName($ivars[i])); }
2015-08-07 20:22:53.155 RuntimeSample_20150806[4764:16999] _storage
`````

因為我們只寫了一個 `property` 所以系統自動的幫我們產生了一個 `_storage`, 這是他的名字, 但是他在哪裡呢?

`````
(lldb) expr for (int i = 0; i < $count; i++) { (void)NSLog(@"%p", (long)ivar_getOffset($ivars[i])); }
2015-08-07 20:24:40.484 RuntimeSample_20150806[4764:16999] 0x8
`````

他告訴我們 `offset` 是 `0x8`, 這 `0x8` 是什麼意思? `0x8` 指的是說, 從 `instance` 起始的 `address` 往下算 `0x8` 的地方, 所以我們去算

`````
(lldb) po *(id *)(0x7fbec0d43fe0 + 0x8)
<__NSArrayM 0x7fbec0d437b0>(
1,
2
)
`````

喔喔, 原來這裡面裝了一個 `__NSArrayM` 的東西, 裡面還包含了 `1` 和 `2`! 既然都知道他住哪了, 我們想當然也可以動他, 比方說我想幫他加個家人

`````
(lldb) expr NSMutableArray *$myStorage = (NSMutableArray *)[*(id *)(0x7fbec0d43fe0 + 0x8) retain];
(lldb) expr [$myStorage addObject:@"3"];
(lldb) po *(id *)(0x7fbec0d43fe0 + 0x8)
<__NSArrayM 0x7fbec0d437b0>(
1,
2,
3
)
`````

我們先用一個 `myStorage` `retain` 他之後, 硬是幫他塞了個 `3` 進去, 不得不從的, 再次打印的時候, 他就多了個 `3` 哈哈.

說到這邊, 有個怪異的點! 我們剛剛打印的 `method` 們一共有

`````
2015-08-07 20:04:54.412 RuntimeSample_20150806[4764:16999] setStorage:
2015-08-07 20:04:54.413 RuntimeSample_20150806[4764:16999] storage
2015-08-07 20:04:54.413 RuntimeSample_20150806[4764:16999] .cxx_destruct
2015-08-07 20:04:54.413 RuntimeSample_20150806[4764:16999] invoke
2015-08-07 20:04:54.413 RuntimeSample_20150806[4764:16999] init
`````

五個! 但是那我在 `NormalObject.m` 裡面寫的 `+ (NSInteger)randomIntegerValue;`, `+ (NSInteger)randomPart1;`, `+ (NSInteger)randomPart2;` 他們去哪了勒? 該不會系統把我吃了吧.....

沒有...其實在 `class` 的上面, 還有一個 `meta class`, 就如同界王上面, 還有界王神一樣!! 我們一樣來證明這個部分, 複習一下, 剛剛我們 `class` 的 `address` 在 `0x00000001064d1e70`, 所以我們去找他的 `isa`

`````
(lldb) print (void *)((NSObject *)0x00000001064d1e70)->isa
(void *) $8 = 0x00000001064d1e98
(lldb) po 0x00000001064d1e98
NormalObject
`````

真的! 在 `class` 上面還有一個 `class`! 原來他就是 `meta class`, 我們來看看我們的 `class method` 是不是被他記載著

`````
(lldb) expr Method *$methods = (Method *)class_copyMethodList((Class)0x00000001064d1e98, &$count);
(lldb) expr for (int i = 0; i < $count; i++) { (void)NSLog(@"%s", (const char*)method_getName($methods[i])); }
2015-08-07 20:37:54.372 RuntimeSample_20150806[4764:16999] randomPart1
2015-08-07 20:37:54.372 RuntimeSample_20150806[4764:16999] randomPart2
2015-08-07 20:37:54.373 RuntimeSample_20150806[4764:16999] randomIntegerValue
`````

果然! 就都在這邊了.

到這個部分, 做一個小的總結,

	- instance method 在 class 內, 所以不管是要取得, 或是掛載, 需要從 class 去做
	- class method 在 meta class 內, 所以不管是要取得, 或是掛載, 需要從 meta class 去做

網路上面有一些比較好的圖來表達這個架構, 我選一張我喜歡的放上

![image](http://blog.ibireme.com/wp-content/uploads/2013/11/objctree.png)

玩法二
======

好滴, 回到外面, 這次我們多打一個斷點在 `Line 25` 的地方

![image](https://s3-ap-northeast-1.amazonaws.com/daidoujiminecraft/Daidouji/%E8%9E%A2%E5%B9%95%E5%BF%AB%E7%85%A7+2015-08-07+%E4%B8%8B%E5%8D%888.42.02.png)

然後再 run 一次, 讓他卡到第一個斷點的地方, 然後, 新增一個 `Symbolic Breakpoint`

![image](https://s3-ap-northeast-1.amazonaws.com/daidoujiminecraft/Daidouji/%E8%9E%A2%E5%B9%95%E5%BF%AB%E7%85%A7+2015-08-07+%E4%B8%8B%E5%8D%888.45.31.png)

內容寫

![image](https://s3-ap-northeast-1.amazonaws.com/daidoujiminecraft/Daidouji/%E8%9E%A2%E5%B9%95%E5%BF%AB%E7%85%A7+2015-08-07+%E4%B8%8B%E5%8D%888.47.04.png)

多一個斷點會變成

![image](https://s3-ap-northeast-1.amazonaws.com/daidoujiminecraft/Daidouji/%E8%9E%A2%E5%B9%95%E5%BF%AB%E7%85%A7+2015-08-07+%E4%B8%8B%E5%8D%888.47.18.png)

然後按下繼續跑

![image](https://s3-ap-northeast-1.amazonaws.com/daidoujiminecraft/Daidouji/%E8%9E%A2%E5%B9%95%E5%BF%AB%E7%85%A7+2015-08-07+%E4%B8%8B%E5%8D%888.49.39.png)

app 會斷在 `objc_msgSend` 裡面, 這時候可以一步一步的往下按, 按按按, 會走到一個這樣的地方

![image](https://s3-ap-northeast-1.amazonaws.com/daidoujiminecraft/Daidouji/%E8%9E%A2%E5%B9%95%E5%BF%AB%E7%85%A7+2015-08-07+%E4%B8%8B%E5%8D%888.51.29.png)

`_class_lookupMethodAndLoadCache`, 會走到這邊, 表示說從快取中找不到這次要運行的 `IMP` 在哪, `_class_lookupMethodAndLoadCache` 後面會去做找到這個 `IMP` 以及把他放入快取的動作, 到這邊, 先關掉 `objc_msgSend` 的 `Breakpoint`, 直接按下繼續跑, 他會卡在我們第二個斷點上, 這個時候, 再把 `objc_msgSend` 的 `Breakpoint` 打開, 重新一次剛剛的步驟, 會發現, 在中間的某一個段落, 就從組語的部分跳回 `- (void)invoke;` 了, 很快, 沒有幾行, 為什麼? 因為同一個 `method` 被運行第二次的時候, 不再需要經過查找的動作! 同樣的招式, 無法對聖鬥士用第二次!

組語的部分我也不是頂熟, 不過有機會的話, 我們可以再找時間看看.

玩法三
======
同樣的, 又回到外面, 並且先把 `objc_msgSend` 的 `Breakpoint` 關掉, 然後又讓他 run 到第一個 `Breakpoint` 後, 再開啟 `objc_msgSend` 的 `Breakpoint`, 我們要斷在 `objc_msgSend` 裡面看一些東西

![image](https://s3-ap-northeast-1.amazonaws.com/daidoujiminecraft/Daidouji/%E8%9E%A2%E5%B9%95%E5%BF%AB%E7%85%A7+2015-08-07+%E4%B8%8B%E5%8D%889.02.46.png)

從 runtime 的 source code 裡面, 我們可以知道 `%rdi` 是 `reciver`, `%rsi` 是 `message` 所以我們也試著打印看看

`````
(lldb) po *(id *)$rdi
NormalObject

(lldb) po (const char*)$rsi
"invoke"
`````

成功地看出來他們是誰 (雖然本來也就知道他們是誰, 哈哈, 我們把他串燒一下

`````
(lldb) expr (void)NSLog(@"[%s - %s]", (const char*)object_getClassName(*(id *)$rdi), (const char*)$rsi);
2015-08-07 21:16:08.957 RuntimeSample_20150806[5628:69913] [NormalObject - invoke]
`````

把這一行 code 放回 `objc_msgSend` 的 `Breakpoint` 試試

![image](https://s3-ap-northeast-1.amazonaws.com/daidoujiminecraft/Daidouji/%E8%9E%A2%E5%B9%95%E5%BF%AB%E7%85%A7+2015-08-07+%E4%B8%8B%E5%8D%889.17.21.png)

之所以 `%rdi` 不能是 0, 是因為我們不想理 `nil` 的人, 在不等於 0 的情況下, 我們都用我們剛剛那行 code, 然後, 又一次的...先關掉 `objc_msgSend` 的 `Breakpoint` 到第一個斷點後, 再開, 再繼續...這時候, 你會發現他這次段在 `objc_msgSend` 裡面的時候, 多打了一行 log

`````
2015-08-07 21:18:30.625 RuntimeSample_20150806[5695:72866] [NormalObject - invoke]
`````

但是我們總不能每次都停下來吧...也太累了...因此, 我們把 Option `Automatically continue after....` 的選項打勾, 然後再按繼續

`````
2015-08-07 21:18:30.625 RuntimeSample_20150806[5695:72866] [NormalObject - invoke]
2015-08-07 21:22:17.659 RuntimeSample_20150806[5695:72866] [NSObject - date]
2015-08-07 21:22:17.668 RuntimeSample_20150806[5695:72866] [NSObject - alloc]
2015-08-07 21:22:17.677 RuntimeSample_20150806[5695:72866] [NSObject - allocWithZone:]
2015-08-07 21:22:17.686 RuntimeSample_20150806[5695:72866] [NSObject - self]
2015-08-07 21:22:17.694 RuntimeSample_20150806[5695:72866] [NSObject - immutablePlaceholder]
2015-08-07 21:22:17.703 RuntimeSample_20150806[5695:72866] [__NSPlaceholderDate - initWithTimeIntervalSinceReferenceDate:]
2015-08-07 21:22:17.711 RuntimeSample_20150806[5695:72866] [NSObject - __new:]
2015-08-07 21:22:17.720 RuntimeSample_20150806[5695:72866] [NSObject - __new:]
2015-08-07 21:22:17.728 RuntimeSample_20150806[5695:72866] [NSObject - initialize]
2015-08-07 21:22:17.736 RuntimeSample_20150806[5695:72866] [__NSDate - autorelease]
2015-08-07 21:22:17.745 RuntimeSample_20150806[5695:72866] [__NSDate - timeIntervalSinceNow]
2015-08-07 21:22:17.753 RuntimeSample_20150806[5695:72866] [__NSDate - timeIntervalSinceReferenceDate]
2015-08-07 21:22:17.755 RuntimeSample_20150806[5695:72866] NormalObject Cost : 0.058910s
2015-08-07 21:22:17.762 RuntimeSample_20150806[5695:72866] [__NSDate - dealloc]
`````

我們可以列出所有經過 `objc_msgSend` 訊息傳遞的孩子們, 在有限的情況下, 也許是幫助 debug 的契機.

故事結束, 謝謝.
