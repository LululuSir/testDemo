# iOS图片加载内存实用分析手册
## 简介
对于大多数App来说，内存占用主要就是图片。本文将从实用的角度分析，iOS图片的内存占用、测量、优化等。

## iOS内存-有什么影响
在移动操作系统设备中，是不能像PC一样进行内存swap的，而随着用户的实用，打开的应用越来越多，应用使用的内存也越来越多。当占用的内存达到某个临界值时，iOS系统会尝试按照优先级逐个kill掉应用程序，以维护系统的流畅和稳定。

当iOS系统在清理内存过程中，优先级到了前台正在运行的应用程序，那么就会出现前台应用程序闪退的现象，也就是通常所说的OOM。


## iOS内存-关注什么
实际上，对于iOS系统内存，根据划分的方法方式，有很多内存种类，比较常见的有clean memory, dirty memory，有virtual memory, resident memory，等等。那么这么多的内存，重点要关注什么呢？

>For the purposes of this guide, Persistent Bytes for All Heap & Anonymous VM represents your app's memory footprint.

这句话来自[苹果的官方技术文档](https://developer.apple.com/library/archive/technotes/tn2434/_index.html)，翻译过来就是，在内存优化中，需要关注的memory footprint就是“Persistent Bytes for All Heap & Anonymous VM”。也就是下图中instruments-Allocation中的①。至于提到的memory footprint，可以参考[wiki](https://en.wikipedia.org/wiki/Memory_footprint)。

![](https://developer.apple.com/library/archive/technotes/tn2434/Art/tn2434_resultsPane_sized.png)


也就是说，iOS内存优化看“memory footprint”，“memory footprint”优化看“Persistent Bytes for All Heap & Anonymous VM”

## iOS内存-图片内存怎么算
先打一个比喻，我们平时为了传输方便，往往会对文件进行压缩，得到一个.rar或者.zip的压缩包，当我们要阅读文件时，需要先解压压缩包，得到.doc或者.txt等文档，然后再打开阅读。

类似的，我们平时看到的.jpg，.png，就是上面所说的压缩包，这个文件是不能直接上屏渲染的，需要先解压缩，然后才能在上屏。而我们平时无感知，直接打开文件就能看，是因为解码渲染很快，在你点击的时候就完成了解码+渲染的操作了，类似.zip压缩包也可以不解压直接预览一样。

那么显而易见，我们看到的磁盘上的图片和最终渲染出来的图片是不同的，那么图片实际加载渲染时的内存要怎么算呢。在iOS中可以通过以下公式快速计算。其中4是每个像素占用的byte，在iOS中固定为4(至少目前为止是的)，Android中需要根据实际的调整，一般也是4。
>内存大小=像素宽\*像素高\*4

## iOS内存-图片内存怎么取
如果要进行图片内存的优化，首先得保证能监测到图片的内存大小。图片内存的测量，各家有各家的方案，但是总的来说，都是在某个或多个图片加载的入口，进行侵入或非侵入AOP，进行相关的计算。

这里推荐一个方法，实用NSHashtable，弱引用持有对象。将图片的对象放到这个弱引用的hash表中，可以实时查看当前仍存活的所有图片对象，并据此计算图片占用的内存。

iOS中UIImage内存占用：
>UIImage内存占用大小：image.size.width\*image.size.height\*image.scale

## iOS内存-图片内存优化
iOS图片内存优化，大的方向就是：
>少用，勤释放

就是在页面中同时加载的图片数量要少，单张图片的大小要小，图片占用的内存要勤释放，用CPU换内存。

一个典型的优化就是，UITableView中，cell的reuse。单个cell的高度推荐小于1屏，cell要能够重用，列表滚动时，cell中的图片按需加载和释放。能够做到这些，一般的图片内存问题都能够很好的解决。

## iOS内存-图片按需加载
目前流行的图片加载，都会选取CDN，将原图进行初步的压缩，然后加载，但是这个更多的考虑的是服务的的性能，负载均衡等等，客户端的收益基本就只有流量一条。客户端内存的优化微乎其微。

根据上面说的图片内存解释，我们知道图片内存暴涨就是在对其解压缩时。如果看过iOS最流行的图片加载框架SDWebImage，和腾讯开源图片框架LKImageKit，可以发现LKImageKit有一个很精细的图片加载优化，就是在图片解码时，根据加载图片的view的frame，进行解码。这样就避免了一个很小的view，加载一张很大的图片，消耗大量内存的情况。

在SDWebImage中，要实现这个feature会有点麻烦。需要将上层调用的frame透传到最下面的解码部分，且需要做一些错误校验。

此外，需要注意的是，压缩率比较高的图片，在进行这种二次压缩时，压缩后的图片有可能会有很严重的失真。
