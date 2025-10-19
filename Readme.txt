为方便测试，我们将练习2、扩展1和扩展2的代码分别呈现，下面对三个编程题的代码修改做简单解释。
练习2：根据要求完成了best_fit_pmm.c的代码编写。
扩展1：在kern/mm文件夹下添加了buddy.h和buddy.c两个文件，default_pmm.c注释了默认物理内存管理器，pmm.c添加了buddy.h的宏定义。
扩展2：在kern/mm文件夹下添加了slub.h和slub.c两个文件，kern_init的init.c文件中调用了slub，并且添加了测试。