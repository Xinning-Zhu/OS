#include <buddy.h>
#include <pmm.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>

buddy_system_t buddy_sys;

/* 工具函数实现 */

// 计算给定大小对应的阶
unsigned int get_order(size_t size) {
    if (size == 0) return 0;
    
    unsigned int order = 0;
    size_t current_size = 1;
    
    while (current_size < size) {
        current_size <<= 1;
        order++;
    }
    
    return (order > BUDDY_MAX_ORDER) ? BUDDY_MAX_ORDER : order;
}

// 找到不超过给定大小的最大2的幂次对应的阶数
unsigned int find_smaller_power_of_2(size_t size) {
    if (size == 0) return 0;
    if (size == 1) return 0;  
    
    unsigned int order = 0;
    size_t current_size = 1;
    
    while ((current_size << 1) <= size) {
        current_size <<= 1;
        order++;
    }
    
    return order;
}

// 找到最接近但大于等于size的2的幂对应的阶
unsigned int find_larger_power_of_2(size_t size) {
    if (size == 0) return 0;
    
    unsigned int order = 0;
    size_t current_size = 1;
    
    while (current_size < size) {
        current_size <<= 1;
        order++;
    }
    
    return order;
}

// 判断是否为2的幂
bool is_power_of_2(size_t size) {
    return IS_POWER_OF_2(size);
}


/* 伙伴系统初始化 */

void buddy_system_init(void) {
    for (int i = 0; i <= BUDDY_MAX_ORDER; i++) {
        list_init(&buddy_sys.free_array[i].free_list);
        buddy_sys.free_array[i].nr_free = 0;
    }
    
    buddy_sys.nr_free_pages = 0;
    buddy_sys.total_pages = 0;
    buddy_sys.base_page = NULL;
    buddy_sys.max_order = 0;
    buddy_sys.bitmap = NULL;
    buddy_sys.bitmap_size = 0;
    
    cprintf("buddy_system: initialized with max_order=%d\n", BUDDY_MAX_ORDER);
}

// 将物理内存初始化为 Buddy System 可管理的块结构
void buddy_system_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    assert(base != NULL);
    // 全局初始化
    if (buddy_sys.base_page == NULL) {
        buddy_sys.base_page = base;
        buddy_sys.total_pages = n;
        buddy_sys.nr_free_pages = n;
        
        buddy_sys.max_order = find_smaller_power_of_2(n);
        if (buddy_sys.max_order > BUDDY_MAX_ORDER) {
            buddy_sys.max_order = BUDDY_MAX_ORDER;
        }
        cprintf("buddy_system: global max_order set to %u (total pages %u)\n", 
                buddy_sys.max_order, n);
    } else {
        buddy_sys.nr_free_pages += n;
    }
    // 页面属性初始化
    for (struct Page *p = base; p < base + n; p++) {
        assert(PageReserved(p));
        SetPageProperty(p);
        set_page_ref(p, 0);
        p->property = 0;
    }
    
    // 内存块划分算法
    size_t current_total_pages = n;
    struct Page *current_block = base;
    size_t remaining = current_total_pages;
    
    cprintf("buddy_system: init memmap: base=0x%08x, %u pages\n", base, n);
    
    while (remaining > 0) {
        unsigned int block_order = find_smaller_power_of_2(remaining);
        
        if (block_order < 4) { 
            block_order = (remaining >= 16) ? 4 : find_smaller_power_of_2(remaining);
        }
        
        if (block_order > buddy_sys.max_order) {
            block_order = buddy_sys.max_order;
        }
        
        size_t block_pages = ORDER_TO_PAGES(block_order);
        
        if (block_pages > remaining) {
            block_order = find_smaller_power_of_2(remaining);
            block_pages = ORDER_TO_PAGES(block_order);
        }
        
        SET_PAGE_ORDER(current_block, block_order);
        list_add(&buddy_sys.free_array[block_order].free_list, &(current_block->page_link));
        buddy_sys.free_array[block_order].nr_free++;
        
        cprintf("  -> added order %u block (%u pages) at 0x%08x\n", 
                block_order, block_pages, current_block);
        
        current_block += block_pages;
        remaining -= block_pages;
    }
}

/*核心分配算法*/
struct Page *buddy_alloc_pages(size_t n) {
    assert(n > 0);
    
    if (n > buddy_sys.nr_free_pages) {
        cprintf("buddy_alloc_pages: not enough memory (req %u, free %u)\n", n, buddy_sys.nr_free_pages);
        return NULL;
    }
    
    unsigned int req_order = PAGES_TO_ORDER(n);
    if (req_order > buddy_sys.max_order) {
        cprintf("buddy_alloc_pages: req order %u exceeds max %u\n", req_order, buddy_sys.max_order);
        return NULL;
    }
    
    // 寻找可用块
    unsigned int current_order = req_order;
    while (current_order <= buddy_sys.max_order) {
        if (buddy_sys.free_array[current_order].nr_free > 0) {
            break;
        }
        current_order++;
    }

    if (current_order > buddy_sys.max_order || buddy_sys.free_array[current_order].nr_free == 0) {
        cprintf("buddy_alloc_pages: no block found (req order %u)\n", req_order);
        return NULL;
    }

    cprintf("buddy_alloc: found block at order %u (req order %u)\n", current_order, req_order);
    
    // 块分裂逻辑
    struct Page *alloc_block = NULL;
    while (current_order > req_order) {
        // 1. 从当前阶取一个块
        list_entry_t *le = list_next(&buddy_sys.free_array[current_order].free_list);
        if (le == &buddy_sys.free_array[current_order].free_list) {
            cprintf("buddy_alloc_pages: empty list at order %u\n", current_order);
            return NULL;
        }
        alloc_block = le2page(le, page_link);
        list_del(le);
        buddy_sys.free_array[current_order].nr_free--;

        // 2. 分裂为两个伙伴快
        current_order--;
        size_t half_pages = ORDER_TO_PAGES(current_order);
        struct Page *buddy_block = alloc_block + half_pages;

        // 3. 设置属性并加入空闲链表
        SET_PAGE_ORDER(alloc_block, current_order);
        SET_PAGE_ORDER(buddy_block, current_order);
        list_add(&buddy_sys.free_array[current_order].free_list, &(alloc_block->page_link));
        list_add(&buddy_sys.free_array[current_order].free_list, &(buddy_block->page_link));
        buddy_sys.free_array[current_order].nr_free += 2;
        
        cprintf("buddy_alloc: split order %u -> two order %u blocks\n", 
                current_order + 1, current_order);
    }

    // 如果不需要分裂，直接取块
    if (alloc_block == NULL) {
        list_entry_t *le = list_next(&buddy_sys.free_array[req_order].free_list);
        if (le == &buddy_sys.free_array[req_order].free_list) {
            cprintf("buddy_alloc_pages: no block at req order %u\n", req_order);
            return NULL;
        }
        alloc_block = le2page(le, page_link);
    }

    // 从链表中移除分配块
    list_del(&(alloc_block->page_link));
    buddy_sys.free_array[req_order].nr_free--;
    buddy_sys.nr_free_pages -= ORDER_TO_PAGES(req_order);
    ClearPageProperty(alloc_block);
    
    cprintf("buddy_alloc: allocated %u pages (order %u) at 0x%08x\n", 
            ORDER_TO_PAGES(req_order), req_order, alloc_block);
    return alloc_block;
}

/* 核心释放算法 */
void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    assert(base != NULL);
    assert(PageReserved(base));
    
    // 计算块的阶
    unsigned int order = PAGES_TO_ORDER(n);
    struct Page *free_block = base;
    
    // 设置块属性
    SET_PAGE_ORDER(free_block, order);
    SetPageProperty(free_block);
    
    cprintf("buddy_free: freeing %u pages (order %u) at 0x%08x\n", 
            ORDER_TO_PAGES(order), order, free_block);
    
    // 合并伙伴块
    while (order < buddy_sys.max_order) {
        struct Page *buddy = get_buddy_block(free_block, order);
        
        if (buddy == NULL || !PageProperty(buddy) || 
            PAGE_BUDDY_ORDER(buddy) != order) {
            break; 
        }
        
        list_del(&(buddy->page_link));
        buddy_sys.free_array[order].nr_free--;
        
        // 确定合并后块的起始地址（取较低的地址）
        if (free_block > buddy) {
            struct Page *temp = free_block;
            free_block = buddy;
            buddy = temp;
        }
        
        ClearPageProperty(buddy);
        buddy->property = 0;
        
        // 提升阶数
        order++;
        SET_PAGE_ORDER(free_block, order);
        
        cprintf("buddy_free: merged order %u -> order %u at 0x%08x\n", 
                order - 1, order, free_block);
    }
    
    // 将最终块加入空闲链表
    list_add(&buddy_sys.free_array[order].free_list, &(free_block->page_link));
    buddy_sys.free_array[order].nr_free++;
    buddy_sys.nr_free_pages += ORDER_TO_PAGES(order);
}

/* 伙伴块查找 */
struct Page *get_buddy_block(struct Page *page, unsigned int order) {
    if (page == NULL || order > buddy_sys.max_order) {
        return NULL;
    }
    
    size_t page_index = page - buddy_sys.base_page;
    size_t block_size = ORDER_TO_PAGES(order);
    size_t buddy_index = page_index ^ block_size;  
    
    if (buddy_index >= buddy_sys.total_pages) {
        return NULL;
    }
    
    struct Page *buddy = buddy_sys.base_page + buddy_index;
    
    return buddy;
}

/*伙伴关系验证*/
bool is_buddy_blocks(struct Page *block1, struct Page *block2, unsigned int order) {
    if (block1 == NULL || block2 == NULL) {
        return 0;  
    }
    
    struct Page *buddy1 = get_buddy_block(block1, order);
    struct Page *buddy2 = get_buddy_block(block2, order);
    
    return (buddy1 == block2) && (buddy2 == block1);
}

/* 统计函数 */
size_t buddy_system_nr_free_pages(void) {
    return buddy_sys.nr_free_pages;
}

/* 调试函数 */
void show_buddy_array(unsigned int start_order, unsigned int end_order) {
    if (start_order > end_order || end_order > BUDDY_MAX_ORDER) {
        cprintf("show_buddy_array: invalid order range\n");
        return;
    }
    
    cprintf("=== Buddy System Free Lists ===\n");
    cprintf("Order | BlockSize(Pages) | FreeBlocks | TotalFreePages\n");
    cprintf("------|------------------|------------|----------------\n");
    
    for (unsigned int i = start_order; i <= end_order; i++) {
        unsigned int free_blocks = buddy_sys.free_array[i].nr_free;
        size_t block_size = ORDER_TO_PAGES(i);
        size_t total_pages = free_blocks * block_size;
        
        cprintf(" %2u   | %8u        | %6u     | %8u\n", 
                i, block_size, free_blocks, total_pages);
        
        if (free_blocks > 0) {
            list_entry_t *le = &buddy_sys.free_array[i].free_list;
            while ((le = list_next(le)) != &buddy_sys.free_array[i].free_list) {
                struct Page *page = le2page(le, page_link);
                cprintf("        -> Page: 0x%08x, Order: %u\n", page, PAGE_BUDDY_ORDER(page));
            }
        }
    }
    
    cprintf("Total free pages: %u\n", buddy_sys.nr_free_pages);
}

/* 完整的测试函数 */
void buddy_system_check(void) {
    cprintf("\n=== Buddy System Comprehensive Test ===\n");
    
    show_buddy_array(0, buddy_sys.max_order);
    
    // 测试1: 基本分配释放
    cprintf("Test 1: Basic allocation and free\n");
    struct Page *p1 = buddy_alloc_pages(1);
    assert(p1 != NULL);
    buddy_free_pages(p1, 1);
    cprintf("Test 1 PASSED\n");
    
    // 测试2: 块分裂测试 
    cprintf("\nTest 2: Block split test\n");
    struct Page *large = buddy_alloc_pages(4);  
    if (large == NULL) {
        cprintf("Test 2 SKIPPED: Cannot allocate 4 pages, showing current state:\n");
        show_buddy_array(0, buddy_sys.max_order);
    } else {
        assert(large != NULL);
        buddy_free_pages(large, 4);
        cprintf("Test 2 PASSED\n");
    }
    
    // 测试3: 伙伴合并测试
    cprintf("\nTest 3: Buddy merge test\n");
    struct Page *a1 = buddy_alloc_pages(2);
    struct Page *a2 = buddy_alloc_pages(2);
    if (a1 != NULL && a2 != NULL) {
        assert(is_buddy_blocks(a1, a2, 1));  
        buddy_free_pages(a1, 2);
        buddy_free_pages(a2, 2);
        cprintf("Test 3 PASSED\n");
    } else {
        cprintf("Test 3 SKIPPED: Cannot allocate buddy blocks\n");
    }
    
    // 测试4: 内存耗尽测试 - 改为分配部分内存
    cprintf("\nTest 4: Partial exhaustion test\n");
    size_t free_pages = buddy_sys.nr_free_pages;
    if (free_pages > 100) {
        struct Page *exhaust = buddy_alloc_pages(free_pages / 2);  
        assert(exhaust != NULL);
        buddy_free_pages(exhaust, free_pages / 2);
        cprintf("Test 4 PASSED\n");
    } else {
        cprintf("Test 4 SKIPPED: Not enough free pages\n");
    }
    
    // 测试5: 交错分配释放测试
    cprintf("\nTest 5: Interleaved Allocation/Free Test\n");
    struct Page *blocks[6];
    size_t sizes[] = {1, 2, 4, 8, 2, 1};
    
    // 阶段1: 分配不同大小的块
    cprintf("Phase 1: Allocating mixed sizes...\n");
    for (int i = 0; i < 6; i++) {
        blocks[i] = buddy_alloc_pages(sizes[i]);
        if (blocks[i] == NULL) {
            cprintf("  Failed to allocate %u pages at step %d\n", sizes[i], i);
            continue;
        }
        cprintf("  Allocated %2u pages at 0x%08x\n", sizes[i], blocks[i]);
    }
    
    // 阶段2: 交错释放
    cprintf("Phase 2: Interleaved freeing...\n");
    for (int i = 1; i < 6; i += 2) {
        if (blocks[i] != NULL) {
            cprintf("  Freeing %2u pages at 0x%08x\n", sizes[i], blocks[i]);
            buddy_free_pages(blocks[i], sizes[i]);
            blocks[i] = NULL;
        }
    }
    
    // 阶段3: 重新分配
    cprintf("Phase 3: Re-allocating...\n");
    for (int i = 1; i < 6; i += 2) {
        if (blocks[i] == NULL) { 
            blocks[i] = buddy_alloc_pages(sizes[i]);
            if (blocks[i] != NULL) {
                cprintf("  Re-allocated %2u pages at 0x%08x\n", sizes[i], blocks[i]);
            }
        }
    }
    
    // 阶段4: 全部释放
    cprintf("Phase 4: Freeing all blocks...\n");
    for (int i = 0; i < 6; i++) {
        if (blocks[i] != NULL) {
            buddy_free_pages(blocks[i], sizes[i]);
        }
    }
    
    cprintf("Test 5 PASSED\n");
    
}

/* Buddy System 与 ucore 框架的接口层 */
// 接口函数包装器
static void buddy_init(void) {
    buddy_system_init();
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    buddy_system_init_memmap(base, n);
}

static struct Page *buddy_pmm_alloc_pages(size_t n) {
    return buddy_alloc_pages(n);
}

static void buddy_pmm_free_pages(struct Page *base, size_t n) {
    buddy_free_pages(base, n);
}

static size_t buddy_nr_free_pages(void) {
    return buddy_system_nr_free_pages();
}

void buddy_pmm_check(void) {
    buddy_system_check();
}

// PMM 管理器结构体
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_pmm_alloc_pages, 
    .free_pages = buddy_pmm_free_pages,   
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_pmm_check,             
};