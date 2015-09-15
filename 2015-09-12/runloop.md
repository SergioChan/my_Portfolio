##先来说一个很简单的实例
在scrollView中添加一个timer来刷新视图的时候，如果只是简单的声明
```Objective-Cself.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timeUpdate:) userInfo:nil repeats:YES];```
那么当你滑动或者保持你的手指在scrollView上的时候，timer是不会被响应的，这不是因为刷新视图的操作被占用，而是因为当你没有显式声明的时候，你所定义的timer默认都是加在主线程上，并且，当你在对scrollView进行操作的时候，你的timer的事件根本不会被响应到，这就得说到runloop了。而runloop也是底层原理中相当重要的一部分。我们先从它说起。##什么是runloop
Runloop，顾名思义就是运行的循环。简单理解就是多线程机制中的基础，它能够接收外部事件的输入，并且在有事件的时候保持运行，在没有事件的时候进入休眠。并且它对于线程的消息处理机制进行了很好的封装。
对于线程来说，每一个线程都有一个runloop对象，是否能向某个线程的runloop发送事件取决于你是否启动了这个runloop，系统会默认在你的程序启动的时候运行主线程上的runloop，但是你自定义创建出来的线程可以不需要运行runloop，一些第三方框架，例如AFNetworking，就有在自己的线程上维护一个runloop对象。
在 Core Foundation 里面关于 RunLoop 有5个类:

*     CFRunLoopRef
*     CFRunLoopModeRef
*     CFRunLoopSourceRef 
*     CFRunLoopTimerRef 
*     CFRunLoopObserverRef

他们的关系可以从NSRunloop对象的结构定义中得出。首先，runloop对象在Cocoa和Core Foundation中都有实现，但是他们做了很好的桥接，你可以直接调用

```Objective-C
CFRunLoopRef runLoopRef = currentThreadRunLoop.getCFRunLoop;
```

来获取一个CoreFoundation中的runloop对象。然后，当你在查看NSRunloop的结构的时候，你应该能看到：

```
<CFRunLoop 0x7fd360f5af30 [0x1090a1180]>{wakeup port = 0x4507, stopped = false, ignoreWakeUps = true, 
current mode = (none),
common modes = <CFBasicHash 0x7fd360f5a470 [0x1090a1180]>{type = mutable set, count = 1,
entries =>
	2 : <CFString 0x10907d080 [0x1090a1180]>{contents = "kCFRunLoopDefaultMode"}},
common mode items = (null),
modes = <CFBasicHash 0x7fd360f5b2b0 [0x1090a1180]>{type = mutable set, count = 1,
entries =>
	2 : <CFRunLoopMode 0x7fd360f5aff0 [0x1090a1180]>{name = kCFRunLoopDefaultMode, port set = 0x4703, timer port = 0x4803, 
	sources0 = (null),
	sources1 = (null),
	observers = <CFArray 0x7fd360f5b1a0 [0x1090a1180]>{type = mutable-small, count = 1, values = (
	0 : <CFRunLoopObserver 0x7fd360f5c7f0 [0x1090a1180]>{valid = Yes, activities = 0xfffffff, repeats = Yes, order = 0, callout = currentRunLoopObserver (0x10855b340), context = <CFRunLoopObserver context 0x7fd361213d70>}
)},
	timers = <CFArray 0x7fd360e020d0 [0x1090a1180]>{type = mutable-small, count = 1, values = (
	0 : <CFRunLoopTimer 0x7fd360e01f90 [0x1090a1180]>{valid = Yes, firing = No, interval = 1, tolerance = 0, next fire date = 463742311 (-2.53606331 @ 23607719248079), callout = (NSTimer) [SCCustomThread handleTimerTask] (0x1086416f1 / 0x10855b560) (/Users/useruser/Library/Developer/CoreSimulator/Devices/424D3C6E-8DC0-418B-A2EC-8EDF89507348/data/Containers/Bundle/Application/4D07AF38-9BFC-4617-BAE0-4CB0D7966CC8/runloopTest.app/runloopTest), context = <CFRunLoopTimer context 0x7fd360e01f70>}
)},
	currently 463742313 (23610255156065) / soft deadline in: 1.84467441e+10 sec (@ 23607719248079) / hard deadline in: 1.84467441e+10 sec (@ 23607719248079)
},}}
```

可以看到一个runloop对象包含各种Mode——currentMode，common mode，modes等等，这里的示例我只指定了一个defaultMode。每个mode对应了source，observers和timers，底下的currently则显示的是当前状态的优先级，这个优先级实际上是一个带符号的整型数，后面的观察器部分我会提到。

> 也许你会注意到 source 包括了source0和source1两个版本。
> 
> * Source0 只包含了一个回调（函数指针），它并不能主动触发事件。使用时，你需要先调用 CFRunLoopSourceSignal(source)，将这个 Source 标记为待处理，然后手动调用 CFRunLoopWakeUp(runloop) 来唤醒 RunLoop，让其处理这个事件。
> * Source1 包含了一个 mach_port 和一个回调（函数指针），被用于通过内核和其他线程相互发送消息。这种 Source 能主动唤醒 RunLoop 的线程。

CFRunLoopObserver类型的对象也可以称之为观察者。每个观察者都包含了一个回调，当runloop的状态发生变化时，你可以通过回调来知道当前的状态。
##Mode

![image](https://developer.apple.com/library/prerelease/ios/documentation/Cocoa/Conceptual/Multithreading/Art/runloop.jpg)在你的程序中，runloop的过程实际上是一个无限循环的循环体，这个循环体是由你的程序来运行的。主线程的runloop由于系统已经实现并且没有它程序就不能运行，因此不需要我们手动去运行这个runloop。然而如果我们需要在自定义的线程中使用到runloop，我们则需要用一个do...while循环来驱动它。而runloop对象负责不断地在循环体中运行传进来的事件，然后将事件发给相应的响应。

> 如果你打开你的程序的main.m，你就会发现其实主线程的runloop就是在main函数中进行的，并且系统已经为你生成好了autoreleasepool，因此你也无需操心主线程上的内存释放到底是在什么时候执行了：
> ```Objective-C
> int main(int argc, char * argv[]) {
>      @autoreleasepool {
>         return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
>     }
> }
> ```
根据响应源的不同，runloop也被分成了许多种不同的模式，这就是被Cocoa和Core Foundation都封装了的runloopMode。主要是这么几种：
* NSDefaultRunLoopMode: 大多数工作中默认的运行方式。* NSConnectionReplyMode: 使用这个Mode去监听NSConnection对象的状态。* NSModalPanelRunLoopMode: 使用这个Mode在Model Panel情况下去区分事件(OS X开发中会遇到)。* NSEventTrackingRunLoopMode: 使用这个Mode去跟踪来自用户交互的事件（比如UITableView上下滑动）。* NSRunLoopCommonModes: 这是一个伪模式，其为一组run loop mode的集合。如果将Input source加入此模式，意味着关联Input source到Common Modes中包含的所有模式下。在iOS系统中NSRunLoopCommonMode包含NSDefaultRunLoopMode、NSTaskDeathCheckMode、NSEventTrackingRunLoopMode.可使用CFRunLoopAddCommonMode方法向Common Modes中添加自定义mode。
在文首的情况中，我们可以根据苹果官方文档的定义知道，当你在滑动页面的时候，主线程的runloop自动进入了NSEventTrackingRunLoopMode，而你的timer只是运行在DefaultMode下，所以不能响应。那么最简单的办法就是将你的timer添加在其他的mode下，像这样即可：
```Objective-C[[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];```
需要注意的是CommonModes其实并不是一种Mode，而是一个集合。因此runloop并不能在CommonModes下运行，相反，你可以将需要输入的事件源添加为这个mode，这样无论runloop运行在哪个mode下都可以响应这个输入事件，否则这个事件将不会得到响应。##Input Source
    输入源包括三种，端口，自定义输入源和performSelector的消息。根据上面的图我们可以看出，在runloop接收到消息并执行了指定方法的时候，它会执行runUntilDate:这个方法来退出当前循环。
端口源是基于Mach port的，其他进程或线程可以通过端口来发送消息。这里的知识点需要深入到Mach，就已经比较晦涩难懂了……这里你只需要知道你可以用Cocoa封装的NSPort对象来进行线程之间的通信，而这种通信方式所产生的事件就是通过端口源来传入runloop的。关于Mach port的更深层介绍可以看[这篇](http://segmentfault.com/a/1190000002400329)。自定义输入源。Core Foundation提供了CFRunLoopSourceRef类型的相关函数，可以用来创建自定义输入源。
performSelector输入源:
```Objective-C
//在主线程的Run Loop下执行指定的 @selector 方法
performSelectorOnMainThread:withObject:waitUntilDone:
performSelectorOnMainThread:withObject:waitUntilDone:modes:

//在当前线程的Run Loop下执行指定的 @selector 方法
performSelector:onThread:withObject:waitUntilDone:
performSelector:onThread:withObject:waitUntilDone:modes:

//在当前线程的Run Loop下延迟加载指定的 @selector 方法
performSelector:withObject:afterDelay:
performSelector:withObject:afterDelay:inModes:

//取消当前线程的调用
cancelPreviousPerformRequestsWithTarget:
cancelPreviousPerformRequestsWithTarget:selector:object:```
## runloop生命周期
每一次runloop其实都是一次循环，runloop会在循环中执行runUntilDate: 或者runMode: beforeDate: 来开始每一个循环。而每一个循环又分为下面几个阶段，也就是runloop的生命周期：
* kCFRunLoopEntry 进入循环* kCFRunLoopBeforeTimers 先接收timer的事件* kCFRunLoopBeforeSources 接收来自input source的事件* kCFRunLoopBeforeWaiting 如果没有事件，则准备进入休眠模式，在这里，如果没有事件传入，runloop会运行直到循环中给定的日期，如果你给的是distantFuture，那么这个runloop会无限等待下去* kCFRunLoopAfterWaiting 从休眠中醒来，直接回到kCFRunLoopBeforeTimers状态* kCFRunLoopExit 退出循环
这些状态也是一个枚举类型，系统是这么定义的，你可以使用observer来观测到这些状态：
```Objective-C
/* Run Loop Observer Activities */
typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
    kCFRunLoopEntry = (1UL << 0),
    kCFRunLoopBeforeTimers = (1UL << 1),
    kCFRunLoopBeforeSources = (1UL << 2),
    kCFRunLoopBeforeWaiting = (1UL << 5),
    kCFRunLoopAfterWaiting = (1UL << 6),
    kCFRunLoopExit = (1UL << 7),
    kCFRunLoopAllActivities = 0x0FFFFFFFU
};```
我们下面做一个测试，在demo中我们定义了一个新的线程类，这样我们可以自己启动和维护它的runloop对象。
```Objective-C
- (void)main
{
    @autoreleasepool {
        NSLog(@"Thread Enter");
        [[NSThread currentThread] setName:@"This is a test thread"];
        NSRunLoop *currentThreadRunLoop = [NSRunLoop currentRunLoop];
        // 或者
        // CFRunLoopRef currentThreadRunLoop = CFRunLoopGetCurrent();
        

        CFRunLoopObserverContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
        CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &currentRunLoopObserver, &context);
        
        if (observer) {
            CFRunLoopRef runLoopRef = currentThreadRunLoop.getCFRunLoop;
            CFRunLoopAddObserver(runLoopRef, observer, kCFRunLoopDefaultMode);
        }
        
        // 创建一个Timer，重复调用来驱动Run Loop
        //[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(handleTimerTask) userInfo:nil repeats:YES];
        do {
            [currentThreadRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:3]];
        } while (1);
    }
}```
输入源或者timer对于runloop来说是必要条件，如果没有添加任何输入源，则runloop根本不会启动，所以上面的代码中添加timer的操作，实际上是添加了一个默认的事件输入源，能让runloop保持运行。但是实际上，当你创建好一个runloop对象后，任何输入的事件都可以触发runloop的启动。
例如下面的：
```Objective-C
[self performSelector:@selector(selectorTest) onThread:self.runLoopThread withObject:nil waitUntilDone:NO];```
记住，如果你需要自己来启动和维护runloop的话，核心就在于一个do...while循环，你可以为runloop的跳出设置一个条件，也可以让runloop无限进行下去。在runloop没有接收到事件进入休眠状态之后，如果调用performSelector，runloop的状态变化如下：
```
2015-09-15 09:30:07.492 runloopTest[49521:1482478] Current thread Run Loop activity: kCFRunLoopAfterWaiting
2015-09-15 09:30:07.492 runloopTest[49521:1482478] Current thread Run Loop activity: kCFRunLoopBeforeTimers
2015-09-15 09:30:07.492 runloopTest[49521:1482478] Current thread Run Loop activity: kCFRunLoopBeforeSources
2015-09-15 09:30:07.492 runloopTest[49521:1482478] fuck
2015-09-15 09:30:07.493 runloopTest[49521:1482478] fuck_1
2015-09-15 09:30:07.493 runloopTest[49521:1482478] Current thread Run Loop activity: kCFRunLoopExit
2015-09-15 09:30:07.493 runloopTest[49521:1482478] Current thread Run Loop activity: kCFRunLoopEntry
2015-09-15 09:30:07.493 runloopTest[49521:1482478] Current thread Run Loop activity: kCFRunLoopBeforeTimers
2015-09-15 09:30:07.494 runloopTest[49521:1482478] Current thread Run Loop activity: kCFRunLoopBeforeSources
2015-09-15 09:30:07.494 runloopTest[49521:1482478] Current thread Run Loop activity: kCFRunLoopExit
2015-09-15 09:30:07.494 runloopTest[49521:1482478] Current thread Run Loop activity: kCFRunLoopEntry
2015-09-15 09:30:07.495 runloopTest[49521:1482478] Current thread Run Loop activity: kCFRunLoopBeforeTimers
2015-09-15 09:30:07.495 runloopTest[49521:1482478] Current thread Run Loop activity: kCFRunLoopBeforeSources
2015-09-15 09:30:07.495 runloopTest[49521:1482478] Current thread Run Loop activity: kCFRunLoopBeforeWaiting```
在这里我连续调用了两次performSelector，可以看到runloop也经历了两个循环，而如果只调用一次的话，不会有多出来的那次runloop（你可以自己尝试一下），这是否说明每一次performSelector执行完毕之后都会立即结束当前runloop开始新的，苹果的官方文档里有一句话：
> The run loop processes all queued perform selector calls each time through the loop, rather than processing one during each loop iteration
应该意思是并不是像上面看到的结果那样每一次循环执行一次，而是有一个待执行的操作队列。如果我同时执行四次performSelector，像这样：
```Objective-C
[self performSelector:@selector(selectorTest) onThread:self.runLoopThread withObject:nil waitUntilDone:NO];
    [self performSelector:@selector(selectorTest_1) onThread:self.runLoopThread withObject:nil waitUntilDone:NO];
    [self performSelector:@selector(selectorTest_2) onThread:self.runLoopThread withObject:nil waitUntilDone:NO];
    [self performSelector:@selector(selectorTest_2) onThread:self.runLoopThread withObject:nil waitUntilDone:NO];
```
实际上得到的结果和上面是一样的，然而当我将他们的waitUntilDone参数都设置为YES之后，我们可以看到不一样的地方：

```
2015-09-15 21:30:02.144 runloopTest[89070:1961439] Thread Enter
2015-09-15 21:30:03.463 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopEntry
2015-09-15 21:30:03.463 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopBeforeTimers
2015-09-15 21:30:03.464 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopBeforeSources
2015-09-15 21:30:03.464 runloopTest[89070:1961439] fuck
2015-09-15 21:30:03.464 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopExit
2015-09-15 21:30:03.464 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopEntry
2015-09-15 21:30:03.464 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopBeforeTimers
2015-09-15 21:30:03.464 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopBeforeSources
2015-09-15 21:30:03.464 runloopTest[89070:1961439] fuck_1
2015-09-15 21:30:03.464 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopExit
2015-09-15 21:30:03.464 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopEntry
2015-09-15 21:30:03.464 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopBeforeTimers
2015-09-15 21:30:03.464 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopBeforeSources
2015-09-15 21:30:03.465 runloopTest[89070:1961439] fuck_2
2015-09-15 21:30:03.465 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopExit
2015-09-15 21:30:03.465 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopEntry
2015-09-15 21:30:03.465 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopBeforeTimers
2015-09-15 21:30:03.465 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopBeforeSources
2015-09-15 21:30:03.465 runloopTest[89070:1961439] fuck_2
2015-09-15 21:30:03.465 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopExit
2015-09-15 21:30:03.465 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopEntry
2015-09-15 21:30:03.465 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopBeforeTimers
2015-09-15 21:30:03.466 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopBeforeSources
2015-09-15 21:30:03.466 runloopTest[89070:1961439] Current thread Run Loop activity: kCFRunLoopBeforeWaiting
```

你可以看到每一个performSelector操作都单独执行了一个runloop，从苹果的文档中我们可以找到这个方法的定义：

> * performSelector:onThread:withObject:waitUntilDone:> * performSelector:onThread:withObject:waitUntilDone:modes:
> > Performs the specified selector on any thread for which you have an NSThread object. These methods give you the option of blocking the current thread until the selector is performed.
也就是说，waitUntilDone意味着这个操作是否会在当前线程阻塞其他的输入源，如果等于True，则每一次runloop循环只会处理这一个selector的调用，如果为False，则队列中后面等待着的selector调用都会在同一次runloop循环中执行。至于上文的执行了两个runloop循环的现象，我猜测应该是当runloop从休眠模式被唤醒的时候，当前循环执行完唤醒的操作后就会立即结束，释放掉之前可能累积下来的内存，然后开始新的循环，将队列中的其他输入逐个放进runloop循环中执行。
