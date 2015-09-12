先来说一个很简单的实例
在scrollView中添加一个timer来刷新视图的时候，如果只是简单的声明
```Objective-Cself.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timeUpdate:) userInfo:nil repeats:YES];
```
那么当你滑动或者保持你的手指在scrollView上的时候，timer是不会被响应的，这不是因为刷新视图的操作被占用，而是因为当你没有显式声明的时候，你所定义的timer默认都是加在主线程上，并且，当你在对scrollView进行操作的时候，你的timer的事件根本不会被响应到，这就得说到runloop了。而runloop也是底层原理中相当重要的一部分。我们先从它说起。Runloop，顾名思义就是运行的循环。简单理解就是多线程机制中的基础，它能够接收外部事件的输入，并且在有事件的时候保持运行，在没有事件的时候进入休眠。并且它对于线程的消息处理机制进行了很好的封装。
对于线程来说，每一个线程都有一个runloop对象，是否能向某个线程的runloop发送事件取决于你是否启动了这个runloop，系统会默认在你的程序启动的时候运行主线程上的runloop，但是你自定义创建出来的线程可以不需要运行runloop，一些第三方框架，例如AFNetworking，就有在自己的线程上维护一个runloop对象。
在你的程序中，runloop的过程实际上是一个无限循环的循环体，这个循环体是由你的程序来运行的，而runloop对象负责不断地在循环体中运行传进来的事件，然后将事件发给相应的响应。
以下是事件传进来的源，根据苹果的官方文档，事件源分为两种，一种是输入源，一种就是计时器源，也就是Cocoa封装的NSTimer。而根据响应源的不同，runloop也被分成了许多种不同的模式，这就是被Cocoa和Core Foundation都封装了的runloopMode。主要是这么几种：
* NSDefaultRunLoopMode: 大多数工作中默认的运行方式。* NSConnectionReplyMode: 使用这个Mode去监听NSConnection对象的状态。* NSModalPanelRunLoopMode: 使用这个Mode在Model Panel情况下去区分事件(OS X开发中会遇到)。* UITrackingRunLoopMode: 使用这个Mode去跟踪来自用户交互的事件（比如UITableView上下滑动）。* GSEventReceiveRunLoopMode: 用来接受系统事件，内部的Run Loop Mode。* NSRunLoopCommonModes: 这是一个伪模式，其为一组run loop mode的集合。如果将Input source加入此模式，意味着关联Input source到Common Modes中包含的所有模式下。在iOS系统中NSRunLoopCommonMode包含NSDefaultRunLoopMode、NSTaskDeathCheckMode、UITrackingRunLoopMode.可使用CFRunLoopAddCommonMode方法向Common Modes中添加自定义mode。
在文首的情况中，我们可以根据苹果官方文档的定义知道当你在滑动页面的时候，主线程的runloop自动进入的UITrackingRunLoopMode，而你的timer只是运行在DefaultMode下，所以不能响应。那么最简单的办法就是将你的timer添加在其他的mode下，像这样即可：
```Objective-C[[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
```
需要注意的是CommonModes其实并不是一种Mode，而是一个集合。因此runloop并不能在CommonModes下运行，相反，你可以将需要输入的事件源添加为这个mode，这样无论runloop运行在哪个mode下都可以响应这个输入事件，否则这个事件将不会得到响应。