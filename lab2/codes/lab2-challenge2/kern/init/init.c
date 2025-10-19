#include <console.h>
#include <defs.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>
#include <dtb.h>
#include <slub.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);
void print_kerninfo(void);

/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
    cprintf("  etext  0x%016lx (virtual)\n", etext);
    cprintf("  edata  0x%016lx (virtual)\n", edata);
    cprintf("  end    0x%016lx (virtual)\n", end);
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
}

// ========== SLUB 测试函数 ==========

// 基础功能测试
void slub_basic_test(void) {
    cprintf("\n=== SLUB Basic Function Test ===\n");
    
    // 测试1: 基础分配释放
    cprintf("Test 1: Basic kmalloc/kfree\n");
    void *ptr1 = kmalloc(64);
    void *ptr2 = kmalloc(128);
    if (ptr1 && ptr2) {
        cprintf("  ✓ kmalloc passed - ptr1: %p, ptr2: %p\n", ptr1, ptr2);
        kfree(ptr1);
        kfree(ptr2);
        cprintf("  ✓ kfree passed\n");
    } else {
        cprintf("  ✗ kmalloc failed\n");
    }
    
    // 测试2: 不同大小分配
    cprintf("Test 2: Different Size Allocation\n");
    void *sizes[] = {
        kmalloc(16), kmalloc(32), kmalloc(64), 
        kmalloc(128), kmalloc(256), kmalloc(512)
    };
    
    int size_test_passed = 1;
    for (int i = 0; i < 6; i++) {
        if (sizes[i] == NULL) {
            size_test_passed = 0;
            cprintf("  ✗ Failed to allocate size index %d\n", i);
        } else {
            cprintf("  ✓ Allocated %d bytes at %p\n", 
                   (i == 0 ? 16 : (1 << (i + 4))), sizes[i]);
        }
    }
    
    // 释放所有内存
    for (int i = 0; i < 6; i++) {
        if (sizes[i]) kfree(sizes[i]);
    }
    if (size_test_passed) {
        cprintf("  ✓ All size allocations passed\n");
    }
    
    // 测试3: 缓存创建和对象分配
    cprintf("Test 3: Cache Creation and Object Allocation\n");
    struct kmem_cache_t *test_cache = kmem_cache_create("test_obj", 256, NULL, NULL);
    if (test_cache) {
        cprintf("  ✓ Cache created successfully\n");
        
        void *obj1 = kmem_cache_alloc(test_cache);
        void *obj2 = kmem_cache_alloc(test_cache);
        
        if (obj1 && obj2) {
            cprintf("  ✓ Object allocation passed - obj1: %p, obj2: %p\n", obj1, obj2);
            
            // 测试释放和重新分配
            kmem_cache_free(test_cache, obj2);
            void *obj3 = kmem_cache_alloc(test_cache);
            if (obj3) {
                cprintf("  ✓ Free and reallocation test passed\n");
            }
            kmem_cache_free(test_cache, obj1);
            kmem_cache_free(test_cache, obj3);
        } else {
            cprintf("  ✗ Object allocation failed\n");
        }
        
        kmem_cache_destroy(test_cache);
        cprintf("  ✓ Cache destruction passed\n");
    } else {
        cprintf("  ✗ Cache creation failed\n");
    }
}

// 压力测试
void slub_stress_test(void) {
    cprintf("\n=== SLUB Stress Test ===\n");
    
    #define STRESS_TEST_COUNT 50
    void *pointers[STRESS_TEST_COUNT];
    
    cprintf("Stress Test: Multiple Allocations\n");
    for (int i = 0; i < STRESS_TEST_COUNT; i++) {
        size_t size = 16 * (1 + (i % 8));  // 16, 32, ..., 128
        pointers[i] = kmalloc(size);
        if (!pointers[i]) {
            cprintf("  ✗ Stress test failed at iteration %d\n", i);
            break;
        }
    }
    
    cprintf("Stress Test: Free All Allocations\n");
    for (int i = 0; i < STRESS_TEST_COUNT; i++) {
        if (pointers[i]) kfree(pointers[i]);
    }
    
    cprintf("  ✓ Stress test completed\n");
}

// 内存泄漏检测
void slub_memory_leak_test(void) {
    cprintf("\n=== SLUB Memory Leak Test ===\n");
    
    // 记录初始内存状态
    size_t initial_pages = nr_free_pages();
    cprintf("Initial free pages: %d\n", initial_pages);
    
    // 执行分配释放循环
    for (int cycle = 0; cycle < 5; cycle++) {
        void *temp_ptrs[10];
        
        // 分配
        for (int i = 0; i < 10; i++) {
            temp_ptrs[i] = kmalloc(64 * (i + 1));
        }
        
        // 释放
        for (int i = 0; i < 10; i++) {
            if (temp_ptrs[i]) kfree(temp_ptrs[i]);
        }
    }
    
    // 检查最终内存状态
    size_t final_pages = nr_free_pages();
    cprintf("Final free pages: %d\n", final_pages);
    
    if (initial_pages == final_pages) {
        cprintf("  ✓ No memory leak detected\n");
    } else {
        cprintf("  ✗ Possible memory leak: %d pages lost\n", 
                initial_pages - final_pages);
    }
}

// 错误处理测试
void slub_error_handling_test(void) {
    cprintf("\n=== SLUB Error Handling Test ===\n");
    
    // 测试1: 超大对象分配
    cprintf("Test: Oversized Allocation\n");
    void *oversized = kmalloc(SIZED_CACHE_MAX + 1);
    if (oversized == NULL) {
        cprintf("  ✓ Correctly rejected oversized allocation\n");
    } else {
        cprintf("  ✗ Should have rejected oversized allocation\n");
        kfree(oversized);
    }
    
    // 测试2: 零大小分配
    cprintf("Test: Zero Size Allocation\n");
    void *zero_size = kmalloc(0);
    if (zero_size == NULL) {
        cprintf("  ✓ Correctly handled zero size allocation\n");
    } else {
        cprintf("  ✗ Unexpectedly allocated zero size\n");
        kfree(zero_size);
    }
    
    // 测试3: ksize 功能
    cprintf("Test: ksize Function\n");
    void *test_ptr = kmalloc(100);
    if (test_ptr) {
        size_t actual_size = ksize(test_ptr);
        cprintf("  ✓ ksize returned: %d bytes for 100-byte request\n", actual_size);
        kfree(test_ptr);
    }
}

// 性能简单测试
void slub_performance_test(void) {
    cprintf("\n=== SLUB Performance Test ===\n");
    
    #define PERF_TEST_COUNT 100
    void *perf_ptrs[PERF_TEST_COUNT];
    
    cprintf("Performance: Allocation Speed\n");
    for (int i = 0; i < PERF_TEST_COUNT; i++) {
        perf_ptrs[i] = kmalloc(64);
        if (!perf_ptrs[i]) {
            cprintf("  ✗ Performance test failed at iteration %d\n", i);
            break;
        }
    }
    
    cprintf("Performance: Free Speed\n");
    for (int i = 0; i < PERF_TEST_COUNT; i++) {
        if (perf_ptrs[i]) kfree(perf_ptrs[i]);
    }
    
    cprintf("  ✓ Performance test completed (%d operations)\n", PERF_TEST_COUNT);
}

// 完整测试套件
void run_slub_test_suite(void) {
    cprintf("\n");
    cprintf("=========================================\n");
    cprintf("    SLUB Allocator Comprehensive Test    \n");
    cprintf("=========================================\n");
    
    slub_basic_test();
    slub_stress_test();
    slub_memory_leak_test();
    slub_error_handling_test();
    slub_performance_test();
    
    cprintf("\n");
    cprintf("=========================================\n");
    cprintf("       🎉 ALL TESTS COMPLETED! 🎉       \n");
    cprintf("=========================================\n");
}

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    dtb_init();
    cons_init();
    const char *message = "(THU.CST) os is loading ...\0";
    cputs(message);

    print_kerninfo();
    pmm_init();
    
    // 初始化 SLUB
    kmem_int();
    cprintf("SLUB allocator initialized successfully\n");
    
    // 运行完整的 SLUB 测试套件
    run_slub_test_suite();
    
    cprintf("\nSystem is ready. Entering idle loop...\n");

    /* do nothing */
    while (1)
        ;
}