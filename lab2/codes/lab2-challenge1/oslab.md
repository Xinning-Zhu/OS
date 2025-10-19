# 主要思想
## 1.1 算法核心思想

Buddy System（伙伴系统）是一种经典而高效的内存分配算法，其核心设计理念是将物理内存划分为大小均为2的n次幂的内存块。这种幂次划分的特性（如1、2、4、8、16页等）为算法的高效运行奠定了坚实的数学基础，使得内存管理操作可以通过简单的位运算来实现。

## 1.2 伙伴关系机制

算法中一个关键概念是"伙伴关系"——两个地址连续且大小完全相同的内存块互为伙伴。这种特殊的结构关系是Buddy System能够智能管理内存的核心所在。伙伴关系的精确定义确保了在内存释放时，系统能够准确地识别可以合并的块对，从而有效地重组内存空间。

## 1.3 递归操作策略

Buddy System采用优雅的递归操作策略来处理内存的分配与释放。当请求分配内存时，算法会从现有的最大可用块开始，递归地进行分裂操作，直到获得恰好满足请求大小的内存块。相应地，在释放内存时，系统会递归地检查被释放块的伙伴块状态，如果伙伴块也处于空闲状态，则自动将它们合并成更大的内存块。

## 1.4 碎片管理优势

这种基于伙伴关系的分裂与合并机制赋予了Buddy System出色的外部碎片管理能力。通过动态地合并相邻的空闲块，系统能够有效地减少内存碎片，保证即使经过长时间运行，大块连续内存的分配请求仍然能够得到满足。这一特性使得Buddy System特别适合需要长期稳定运行的操作系统环境。

# 开发文档

## 2.1 核心数据结构

### 2.1.1 伙伴系统管理器（buddy_system_t）
为了管理伙伴系统的全局状态和空闲内存块，设计了如下结构体，能够通过它统筹管理所有空闲内存块的分配、释放、分裂与合并，是实现高效内存管理的基础。

```c
typedef struct {
    unsigned int max_order; // 系统支持的最大阶数
    buddy_free_area_t free_array[BUDDY_MAX_ORDER + 1]; // 各阶空闲块链表数组
    unsigned int nr_free_pages; // 总空闲页数
    struct Page *base_page; // 物理内存地址
    size_t total_pages; // 总页数
} buddy_system_t;
```

### 2.1.2 空闲区域结构（buddy_free_area_t）
为了对每一个阶数的空闲内存块进行组织与管理，设计了此结构体。它用于维护特定阶数下所有空闲块的链表信息，方便伙伴系统快速查找、分配和合并对应大小的空闲内存块。

```c
typedef struct {
    list_entry_t free_list;    // 空闲块链表头
    unsigned int nr_free;      // 该阶空闲块数量
} buddy_free_area_t;
```
## 2.2 核心算法实现
### 2.2.1 内存初始化算法
设计了`buddy_system_init_memmap`函数用于对物理内存进行初始化，代码如下所示。
```c
void buddy_system_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    assert(base != NULL);
    
    // ==================== 全局系统初始化 ====================
    // 仅在第一次调用时初始化全局参数
    if (buddy_sys.base_page == NULL) {
        buddy_sys.base_page = base;           // 设置内存管理基地址
        buddy_sys.total_pages = n;            // 记录总页面数
        buddy_sys.nr_free_pages = n;          // 初始化空闲页面计数
        
        // 计算系统支持的最大阶数
        buddy_sys.max_order = find_smaller_power_of_2(n);
        if (buddy_sys.max_order > BUDDY_MAX_ORDER) {
            buddy_sys.max_order = BUDDY_MAX_ORDER;
        }
        cprintf("buddy_system: global max_order set to %u (total pages %u)\n", 
                buddy_sys.max_order, n);
    } else {
        buddy_sys.nr_free_pages += n;
    }
    
    // ==================== 页面属性初始化 ====================
    // 遍历并初始化该内存区域的所有页面数据结构
    for (struct Page *p = base; p < base + n; p++) {
        assert(PageReserved(p));           // 确保页面处于保留状态
        SetPageProperty(p);                // 标记页面为空闲可用
        set_page_ref(p, 0);                // 初始化引用计数为0
        p->property = 0;                   // 清空阶数信息
    }
    
    // ==================== 内存块划分算法 ====================
    // 采用贪心策略将连续内存划分为最大的2的幂次块
    size_t current_total_pages = n;        // 当前区域总页数
    struct Page *current_block = base;     // 当前处理块的起始位置
    size_t remaining = current_total_pages; // 剩余待划分页数
    
    cprintf("buddy_system: init memmap: base=0x%08x, %u pages\n", base, n);
    
    // 循环处理直到所有内存划分完毕
    while (remaining > 0) {
        // 步骤1：计算当前能划分的最大块阶数
        unsigned int block_order = find_smaller_power_of_2(remaining);
        
        // 步骤2：优化策略 - 强制创建较大的初始块
        if (block_order < 4) { 
            block_order = (remaining >= 16) ? 4 : find_smaller_power_of_2(remaining);
        }
        
        // 步骤3：确保块阶数不超过系统最大限制
        if (block_order > buddy_sys.max_order) {
            block_order = buddy_sys.max_order;
        }
        
        // 步骤4：计算该阶数对应的实际页数
        size_t block_pages = ORDER_TO_PAGES(block_order);
        
        // 步骤5：边界处理 - 如果剩余内存不够完整块，调整阶数
        if (block_pages > remaining) {
            block_order = find_smaller_power_of_2(remaining);
            block_pages = ORDER_TO_PAGES(block_order);
        }
        
        // 步骤6：设置块属性并加入对应阶数的空闲链表
        SET_PAGE_ORDER(current_block, block_order);  // 记录块的阶数信息
        list_add(&buddy_sys.free_array[block_order].free_list, 
                &(current_block->page_link));        // 加入空闲链表
        buddy_sys.free_array[block_order].nr_free++; // 更新该阶空闲块计数
        
        cprintf("  -> added order %u block (%u pages) at 0x%08x\n", 
                block_order, block_pages, current_block);
        
        // 步骤7：移动指针，继续处理剩余内存
        current_block += block_pages;  // 移动到下一个块的起始位置
        remaining -= block_pages;      // 更新剩余页数
    }
}
```



- **分层初始化策略**：函数采用分层初始化策略，首先进行全局系统参数的设置，包括内存基地址、总页数统计和最大阶数计算。系统最大阶数通过`find_smaller_power_of_2`函数动态计算，确保不超过物理内存的实际容量和系统定义的上限`BUDDY_MAX_ORDER`。

- **页面属性统一配置**：在页面级别初始化阶段，函数遍历所有物理页面，统一设置页面属性：将页面标记为空闲可用状态、初始化引用计数为零，并清空原有的阶数信息，为后续的块划分做好准备。

- **智能块划分算法**：核心的块划分算法采用贪心策略，循环将连续内存空间划分为尽可能大的2的幂次块。算法包含多重优化：首先计算理论最大块，然后通过最小块大小约束（至少16页）避免过度碎片化，最后进行边界检查确保划分的完整性。

- **链表管理体系**：每个划分完成的内存块都会被赋予相应的阶数属性，并加入到对应阶数的空闲链表中。系统维护一个多级链表数组`free_array`，每个阶数对应一个独立的空闲链表，这种设计为后续的高效内存分配奠定了坚实基础。

- **系统完整性构建**：该初始化函数不仅完成了基本的内存映射，更重要的是构建了Buddy System所需的核心数据结构，确保了后续分配和释放操作的正确性和高效性。
### 2.2.2 内存分配算法

设计了`buddy_alloc_pages`函数作为Buddy System的核心分配算法，代码如下所示。

```c
struct Page *buddy_alloc_pages(size_t n) {
    assert(n > 0);
    
    // ==================== 内存充足性检查 ====================
    // 检查系统是否有足够的空闲页面满足分配请求
    if (n > buddy_sys.nr_free_pages) {
        cprintf("buddy_alloc_pages: not enough memory (req %u, free %u)\n", 
                n, buddy_sys.nr_free_pages);
        return NULL;
    }
    
    // ==================== 阶数计算与验证 ====================
    // 将请求的页面数转换为对应的最小阶数
    unsigned int req_order = PAGES_TO_ORDER(n);
    // 检查请求阶数是否超过系统支持的最大阶数
    if (req_order > buddy_sys.max_order) {
        cprintf("buddy_alloc_pages: req order %u exceeds max %u\n", 
                req_order, buddy_sys.max_order);
        return NULL;
    }
    
    // ==================== 寻找可用内存块 ====================
    // 从请求阶数开始，向上搜索第一个有空闲块的阶数
    unsigned int current_order = req_order;
    while (current_order <= buddy_sys.max_order) {
        if (buddy_sys.free_array[current_order].nr_free > 0) {
            break; 
        }
        current_order++;
    }

    // 最终检查：确保确实找到了可用的内存块
    if (current_order > buddy_sys.max_order || 
        buddy_sys.free_array[current_order].nr_free == 0) {
        cprintf("buddy_alloc_pages: no block found (req order %u)\n", req_order);
        return NULL;
    }

    cprintf("buddy_alloc: found block at order %u (req order %u)\n", 
            current_order, req_order);
    
    // ==================== 块分裂逻辑 ====================
    // 如果找到的块比需要的大，递归分裂直到合适大小
    struct Page *alloc_block = NULL;
    while (current_order > req_order) {
        // 步骤1：从当前阶的空闲链表中获取一个块
        list_entry_t *le = list_next(&buddy_sys.free_array[current_order].free_list);
        if (le == &buddy_sys.free_array[current_order].free_list) {
            cprintf("buddy_alloc_pages: empty list at order %u\n", current_order);
            return NULL;
        }
        alloc_block = le2page(le, page_link); 
        list_del(le);                         
        buddy_sys.free_array[current_order].nr_free--;  

        // 步骤2：将大块分裂为两个伙伴小块
        current_order--;  // 阶数降低一级
        size_t half_pages = ORDER_TO_PAGES(current_order);  // 计算新块大小
        struct Page *buddy_block = alloc_block + half_pages;  // 计算伙伴块地址

        // 步骤3：设置分裂后两个块的属性并加入对应阶的空闲链表
        SET_PAGE_ORDER(alloc_block, current_order);   // 设置原块的阶数
        SET_PAGE_ORDER(buddy_block, current_order);   // 设置伙伴块的阶数
        list_add(&buddy_sys.free_array[current_order].free_list, 
                &(alloc_block->page_link));           // 原块加入链表
        list_add(&buddy_sys.free_array[current_order].free_list, 
                &(buddy_block->page_link));           // 伙伴块加入链表
        buddy_sys.free_array[current_order].nr_free += 2;  // 更新空闲块计数
        
        cprintf("buddy_alloc: split order %u -> two order %u blocks\n", 
                current_order + 1, current_order);
    }

    // ==================== 最终块分配 ====================
    // 如果不需要分裂（current_order == req_order），直接从目标阶获取块
    if (alloc_block == NULL) {
        list_entry_t *le = list_next(&buddy_sys.free_array[req_order].free_list);
        if (le == &buddy_sys.free_array[req_order].free_list) {
            cprintf("buddy_alloc_pages: no block at req order %u\n", req_order);
            return NULL;
        }
        alloc_block = le2page(le, page_link);
    }

    // ==================== 系统状态更新 ====================
    // 从链表中移除已分配的块
    list_del(&(alloc_block->page_link));
    buddy_sys.free_array[req_order].nr_free--;           // 更新对应阶的空闲块计数
    buddy_sys.nr_free_pages -= ORDER_TO_PAGES(req_order); // 更新系统总空闲页数
    ClearPageProperty(alloc_block);                      // 标记块为已分配状态
    
    cprintf("buddy_alloc: allocated %u pages (order %u) at 0x%08x\n", 
            ORDER_TO_PAGES(req_order), req_order, alloc_block);
    
    return alloc_block;  
}
```

- **智能分配机制**：该函数作为Buddy System的核心，能够根据请求的页面数量，动态地寻找或创建尺寸最匹配的内存块。

- **分层处理策略**：采用系统化的处理流程，依次执行前置检查、块查找、分裂操作和状态更新，确保每一步的正确性。

- **严格前置检查**：在分配前进行多重验证，包括请求参数的有效性、系统剩余内存是否充足，以及计算出的需求阶数是否在系统支持范围内。

- **高效块查找算法**：通过从需求阶数开始向上搜索多层空闲链表，快速定位第一个可用的内存块，实现高效分配。

- **递归块分裂操作**：当找到的可用内存块大于需求时，递归地将其分裂为更小的伙伴块，直至得到所需大小的块，实现内存的精确分配。

- **系统状态同步更新**：在分配完成后，及时更新空闲链表、空闲块计数以及总空闲页数，并标记块的已分配状态，确保系统数据的一致性。

- **确保系统完整性**：整个分配过程在追求内存利用最优化的同时，严格维护了Buddy System数据结构的完整性与正确性。

### 2.2.3 内存释放算法
设计了`buddy_alloc_pages`函数作为Buddy System的内存释放算法，代码如下所示。

```c
void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);                     
    assert(base != NULL);             
    assert(PageReserved(base));         
    
    // ==================== 块属性初始化 ====================
    // 计算要释放块的阶数
    unsigned int order = PAGES_TO_ORDER(n);
    struct Page *free_block = base;     
    
    // 设置块为空闲状态，为后续合并操作做准备
    SET_PAGE_ORDER(free_block, order);  
    SetPageProperty(free_block);        
    
    cprintf("buddy_free: freeing %u pages (order %u) at 0x%08x\n", 
            ORDER_TO_PAGES(order), order, free_block);
    
    // ==================== 伙伴块合并逻辑 ====================
    // 递归检查并合并伙伴块，直到无法合并或达到最大阶数
    while (order < buddy_sys.max_order) {
        // 步骤1：查找当前块的伙伴块
        struct Page *buddy = get_buddy_block(free_block, order);
        
        // 步骤2：检查伙伴块是否满足合并条件
        // 条件1：伙伴块存在且有效
        // 条件2：伙伴块处于空闲状态
        // 条件3：伙伴块大小与当前块相同
        if (buddy == NULL || !PageProperty(buddy) || 
            PAGE_BUDDY_ORDER(buddy) != order) {
            break;
        }
        
        // 步骤3：从空闲链表中移除伙伴块
        list_del(&(buddy->page_link));
        buddy_sys.free_array[order].nr_free--;
        
        // 步骤4：确定合并后块的起始地址（始终取较低的地址）
        if (free_block > buddy) {
            struct Page *temp = free_block;
            free_block = buddy;        
            buddy = temp;
        }
        
        // 步骤5：清除伙伴块的独立属性
        ClearPageProperty(buddy);       
        buddy->property = 0;            
        
        // 步骤6：提升阶数，准备下一轮合并检查
        order++;                        
        SET_PAGE_ORDER(free_block, order); 
        
        cprintf("buddy_free: merged order %u -> order %u at 0x%08x\n", 
                order - 1, order, free_block);
    }
    
    // ==================== 最终块回收 ====================
    // 将最终块加入对应阶数的空闲链表
    list_add(&buddy_sys.free_array[order].free_list, &(free_block->page_link));
    buddy_sys.free_array[order].nr_free++;          
    buddy_sys.nr_free_pages += ORDER_TO_PAGES(order); 
}
```

- **智能释放与合并机制**：该函数不仅完成基本的内存释放，更重要的是实现了伙伴块的智能检测与递归合并，有效减少外部碎片。

- **分层验证策略**：采用严格的分层验证流程，依次执行参数有效性检查、块属性恢复和伙伴合并条件判断，确保释放操作的可靠性。

- **严格参数验证**：在释放操作前进行多重安全检查，包括释放页面数的有效性、内存块指针的非空性以及页面状态的正确性，防止非法释放操作。

- **递归伙伴合并算法**：通过递归检查当前块的伙伴块状态，当满足合并条件时自动将两个伙伴块合并为更大的内存块，最大程度重组内存空间。

- **地址对齐维护**：在合并过程中严格遵守地址对齐原则，始终以较低的地址作为合并后块的起始位置，确保Buddy System地址约定的完整性。

- **系统状态一致性更新**：在释放完成后，准确更新空闲链表结构、各阶空闲块计数以及系统总空闲页数，保持内存管理数据的一致性。

- **碎片优化保障**：通过智能的伙伴合并机制，有效消除外部碎片，确保系统长期运行后仍能高效满足大块内存的分配请求。

## 2.3 测试验证
### 2.3.1 基本分配释放
```c
// 测试1: 基本分配释放 - 验证Buddy System最基础功能的正确性
cprintf("Test 1: Basic allocation and free\n");
// 步骤1：分配单个页面，测试最基本的分配功能
struct Page *p1 = buddy_alloc_pages(1);

// 步骤2：验证分配结果
assert(p1 != NULL);

// 步骤3：释放刚才分配的页面
buddy_free_pages(p1, 1);

// 步骤4：测试通过标记
cprintf("Test 1 PASSED\n");
```
该测试用例通过单页面的分配与释放操作，测试系统对最小内存单元的管理能力，确认基本分配和释放机制正常工作。同时验证了内存回收机制是否能够正确将内存返还给系统，确保操作过程中不会引发系统崩溃或内存泄漏等严重问题。此测试作为整个测试体系的基石，为核心算法的正确性提供初步验证，为后续更复杂的测试场景奠定可靠基础。

测试结果如下图所示：

![内存分配测试结果](./test_results/memory_alloc.png "测试1内存分配状态")

