# 白话iOS内存闪退(OOM)

## 前话
本文会尝试使用通俗易懂的语言解释iOS内存闪退，以及一些可行的方案，一些猜想。

## Jetsam模型
iOS使用的是低内存处理机制Jetsam，这是一个基于优先级队列的机制。相关的探究推荐[这篇文章](https://satanwoo.github.io/2017/10/18/abort/)

Jetsam可以简单的抽象为：前台应用程序，在触发某个或多个条件时，触发系统事件，被系统kill掉。而OOM也就是因为触发了内存相关的系统事件，被系统kill掉了。也就是说，研究内存OOM问题，一个无法绕开的话题就是，这个触发系统事件的条件是什么。

## footprint
内存相关的，第一个想到的就是内存的度量。在[上一篇文章](https://www.jianshu.com/p/6934d0bdb8ae)中，我们能够知道，footprint是苹果推荐的内存度量及优化的指标。通过对footprint的研究，我们发现，内存OOM的系统事件，其中之一就是这个footprint。

当footprint达到特定值时，系统就会发送内存警告的消息，进一步则会直接导致被系统kill，导致OOM。

## OOM触发的其他事件
那么OOM是1个条件还是多个条件导致的呢。看了部分开源XNU代码，并没有什么发现。但是在最新的Xcode 9.3升级后，有了一些新的发现。

这个发现告诉我们，OOM的触发事件不只是footprint，至少还有另一个指标。目前已经向苹果提交了TSI，等待回复中。反馈给苹果的邮件如下，展示下我的Chinglish:

```
PLATFORM AND VERSION
iOS
IDE: Xcode 9.3 and above.
iOS:iOS 9 and above.
Device:iPhone 6p, iPhone 5s, iPhone x, iPhone 6sp, etc.

This appeared after I update Xcode 9.3, and 
performed normal when I downgrade to Xcode 9.2. 


DESCRIPTION OF PROBLEM
Memory Tool:IDE footprint memory, instruments-Allocations, source code;
Usually, when I load a 6000(px)*4000(px) image, it will cost 96MB memory. But I fount that, when I load some kind of picture, the footprint memory did not change obviously. And I can't find any memory increase in instruments-Allocations.

In addition, I find OOM is closely related to footprint memory level. But when I use this kind of picture, it can breakthroughs footprint memory limit.In other words, I can load more picture in my App when I use this kind of picture.


So, my question is, why this kind of picture has this feature, and what kind of picture will have this feature.

Usual picture:https://monkeytest.oss-cn-shanghai.aliyuncs.com/TestImageLarge.jpg

Unusual picture:https://monkeytest.oss-cn-shanghai.aliyuncs.com/gratisography-400H.jpg

or:https://gratisography.com/fullsize/gratisography-400H.jpg

Demo project:https://github.com/LululuSir/testDemo.git

STEPS TO REPRODUCE
1.Load some kind of picture.
2.Check the footprint memory use Xcode memory tool or source code.


NAME AND APPLE ID OF APP
```