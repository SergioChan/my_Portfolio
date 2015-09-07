#Objective-C runtime是什么
##当你调用一个方法的时候，发生了什么

在Objective-C里，当你调用一个方法的时候，例如

```Objective-C[foo method];```
的时候，实际上编译器会将它转化为这样
```Objective-Cobjc_msgSend(foo,selector)```
`selector`就是你能够经常用到的那个addTarget中使用到的，它在runtime机制中相当于一个函数的名牌，而IMP则是函数的实现。
消息机制的关键是编译器是如何处理每一个类和对象的。一般来说，一个类会被编译成这样的结构，一个指向父类的指针，一个类的分派表。这个列表里存的是所有的`selector`和他们对应的方法的地址。没错，每个方法都有一个地址，通过地址来调用方法。而这个地址，就是由函数指针IMP来得到的。
> 如果你学过编译原理，并且用其他语言自己写过一个编译器的话，你应该了解写一个基础语言调用方法的时候都会有一个全局的方法表，然后调用的过程实际上是去这个方法表中查找对应方法地址的过程。而Objective-C也是类似的，但是由于它是面向对象的，而且又有着这个runtime的特性，也就意味着在Objective-C中的函数调用实际上是在运行时动态的查询当前类和其父类的分派表。
> 在分派表中，每一个selector都是由SEL对应IMP的形式存储着。我们可以找到SEL的定义
> 
> ```Objective-C> typedef struct objc_selector   *SEL;   > ```
> > 所以SEL实际上表示的是方法的签名。在不同的类中如果有相同名称相同参数的方法，则他们的SEL是一样的。但是对应的IMP，也就是函数指针，是在runtime的时候才会动态的去查询然后调用的。
> > > IMP的定义则是：
> 
> ```Objective-C
> typedef id (*IMP)(id, SEL, ...);
> ```
> 
> 我们可以看出，这个被指向的函数包含一个接收消息的对象id, 调用方法的签名 SEL，以及不定个数的方法参数，并返回一个id。也就是说 IMP 是消息最终调用的执行代码，是方法真正的实现代码。对于对象来说，当一个对象被分配空间并初始化之后，对象有一个指向它的类结构，也就是上面提到的这些东西的指针。这就是你所熟悉的`isa`，这样可以通过自身访问到自身的类以及无穷的父类里的方法列表。
比方说，有一个继承于`NSObject`的foo类，然后又有一个foo1类继承于foo，这时候我们初始化一个foo1的实例对象A，然后调用A的某个方法B，这时候其实也就是向A发了一个消息，要调用B的`selector`。首先会做的是判断接收对象是不是nil，要记住空对象可以接收消息，因为当你向一个空对象发消息的时候，实际上处理的是一个`nil-handler`，而这个handler是啥也不会做的，因此什么也不会发生。
接下来系统在运行时会先从foo1的分派表中寻找B的`selector`，如果没有，则向foo类找，如果有，则直接调用了，然后直到找到`NSObject`，如果这时候还找不到，那么就会报经典的**‘UnRecognized selector sent to instance’**，如果找到了，那就按照对应的地址找到函数，然后把需要的参数一起传过去。

> 这里有个黑科技，其实也很简单，这个报错和崩溃来源于动态查询函数实现最终失败的调用`doesNotRecognizeSelector`，如果你重写了这个方法，那么对于这个类的对象的错误函数调用就可以避免crash了。但是实际上并没有什么卵用，这反而还掩盖了在消息发送和转发的过程中出现的一些异常。当然，系统为了加快这个速度，在上面这一步之前加上了分派表的缓存，秉承着你调用过的函数就有可能再次被调用的原则，你所调用过的函数会被加入到这个缓存表里来。因此，你可以认为当你的应用运行了一会儿之后，这个缓存会变大，然后这时候消息机制也会越变越快。
最关键的点是在当这个查询最后在分派表中没有找到相应实现的时候，会进行一系列调用。而在这个过程中，我们可以做到动态绑定函数地址，动态重定向实现对象和动态重定向实现的函数地址。函数的地址也就是你常见的`IMP`。如果找到函数实现，则不会进入下面的流程。如果没有找到函数的实现，则会先调用`resolveInstanceMethod`这个函数。这个函数是在没有找到函数实现的情况下的第一道补救，这时候你可以通过`class_addMethod`动态添加函数。
一个Objective-C的函数实际上就是一个简单地带有至少两个参数self和_cmd的C方法体。如官方文档给出的这样结构：
```Objective-Cvoid dynamicMethodIMP(id self, SEL _cmd) {    // implementation ....}
```在`resolveInstanceMethod`的时候，你可以这样动态添加一个函数，并且如果当你添加了函数的时候，你需要return YES。
```Objective-C@implementation MyClass
+ (BOOL)resolveInstanceMethod:(SEL)aSEL{    if (aSEL == @selector(resolveThisMethodDynamically)) {          class_addMethod([self class], aSEL, (IMP) dynamicMethodIMP, "v@:");          return YES;    }    return [super resolveInstanceMethod:aSEL];}@end```
这是第一个解决办法，当然，如果你返回了YES，则消息就将被发送到你刚添加的这个IMP去了，也就不会继续下面的消息转发机制了。因此苹果的官方文档就说，动态添加函数是在消息转发机制之前进行的。如果你动态添加了某些函数的实现，但还是希望他们能进入下面的消息转发机制里，你也可以让指定的`selector`返回NO就好了。
接下去就是消息转发的流程了。
一进入消息转发机制之后，runtime首先会调用`forwardingTargetForSelector`。这是让你能够指定对象来响应这个方法的地方，返回值是一个id对象，如果返回的是非空且不是自身的时候，runtime会将消息发送给这个对象，试图获得返回。当这一步仍然为空，则会进入下一步的流程。在下一步调用`forwardInvocation`之前，会走一个函数调用叫做`- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector`，在这里你可以为没有找到对应IMP的selector添加修改他们的方法签名，这里如果你抛出了一个函数的签名，则会继续传递到下一步中，如果抛出了nil，则你再也不会进到下一步了，在这里就直接报错了。你可以在这里做一些有趣的事情，例如修改一些没有实现的selector签名为一些已知的或者固定格式的，然后再由下面的`forwardInvocation`来提供分发之类的实现。当通过了上一步仍然没有函数实现能够响应这条消息的时候，runtime会向对象发送一个 `forwardInvocation：`的消息，并且会把**对函数的调用和附带的参数**封装成一个`NSInvocation`对象传过来。下面设想的是这么一个场景，你希望对A类对象的B方法调用由C类对象的B方法来响应。是的，你可以让A类来继承B类，但是很多情况下这会让情况变得更糟糕，特别是OC并不支持多继承的情况下。这时候就可以用消息转发机制来实现动态绑定啦！当消息不能被正确响应的时候，你需要确定消息将要发送的对象，然后将最开始的调用和参数列表一起发送过去。消息可以用`invokeWithTarget`来发送：
```Objective-C- (void)forwardInvocation:(NSInvocation *)anInvocation{    if ([someOtherObject respondsToSelector:            [anInvocation selector]])        [anInvocation invokeWithTarget:someOtherObject];    else        [super forwardInvocation:anInvocation];}
```
还有，记住每个`NSObject`的子类都继承了这个方法，但是如果你没有手动去重写的话，NSObject里的实现只会马上调用`doesNotRecognizeSelector`，也就是前面经典的报错。因此你需要手动重写它。
这个方法所获得的返回都会返回给最初调用的发送者，不管他是谁。
`forwardInvocation`可以作为未知消息的分发器，让他们各自发送到合理的对象那里去，也可以在这里就过滤掉一些可能会出错的返回和错误信息。
利用消息转发机制我们也可以实现类似多继承的功能。如果A类中不存在B方法，而C类中有B方法，通过消息转发，我们就可以从A类调用B方法，并且通过`forwardInvocation`来分发，我们可以实现类似多继承的功能。但是这两者毕竟还是有区别的，因为多继承是一个可以在一个类中拥有许多父类的方法和属性。但是通过消息转发，我们也只是在消息层面上实现了拥有许多父类方法的能力。
另外要提的就是，即使你做了消息转发来实现类似多继承的能力，当你调用`respondToSelector`或`isKindOfClass`的时候，他们只会去你自身的继承树里面去寻找`selector`，而并不会去识别你的消息转发机制。
因此，当你需要为你的超级对象生成一个小的代理对象（surrodate object）的时候，或者你确实需要动态扩展你的类的时候，你需要重写很多方法。
```Objective-C- (BOOL)respondsToSelector:(SEL)aSelector{    if ( [super respondsToSelector:aSelector] )        return YES;    else {        /* Here, test whether the aSelector message can     *         * be forwarded to another object and whether that  *         * object can respond to it. Return YES if it can.  */    }    return NO;}
```
按照官方文档，你总共需要重写下面几个方法，并且都加上你的消息转发机制。
* `respondsToSelector`* `isKindOfClass`* `instancesRespondToSelector`* `conformsToProtocol`（如果有用到协议）* `methodSignatureForSelector`
哎，可是谁又会用得到呢。官方文档最后的小贴士说，这项技术不在走投无路的时候不要用，它不是用来替代继承的。对于我们最多只能是了解并且用到最表层的例如消息转发还有错误的拦截之类，在实际运用中也只对程序运行时的机制有了更好的了解，但是仍然并没有什么卵用。