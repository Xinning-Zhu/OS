#ifndef __KERN_MM_BUDDY_H__
#define __KERN_MM_BUDDY_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>

/* 系统配置参数 */
#define BUDDY_MAX_ORDER       15     
#define PAGE_SHIFT            12      
#define PAGE_SIZE             (1 << PAGE_SHIFT)

/* 实用宏函数 */
// 判断是否为2的幂
#define IS_POWER_OF_2(x)      ((x) != 0 && ((x) & ((x) - 1)) == 0)

// 计算阶数（页数转换为阶）
#define PAGES_TO_ORDER(n)     get_order(n) 
#define ORDER_TO_PAGES(order) (1UL << (order))  

/* 扩展 Page 结构 - 用于伙伴系统 */
#define PAGE_BUDDY_ORDER(page)    ((page)->property)
#define SET_PAGE_ORDER(page, order) do { \
    (page)->property = (order); \
    SetPageProperty(page); \
} while (0)

// 伙伴系统空闲区域结构
typedef struct {
    list_entry_t free_list;         
    unsigned int nr_free;         
} buddy_free_area_t;  

// 伙伴系统管理器
typedef struct {
    unsigned int max_order;          
    buddy_free_area_t free_array[BUDDY_MAX_ORDER + 1]; 
    unsigned int nr_free_pages;      
    struct Page *base_page;          
    size_t total_pages;              
    uint8_t *bitmap;                
    size_t bitmap_size;            
} buddy_system_t;

/* 全局伙伴系统实例 */
extern buddy_system_t buddy_sys;

/* 核心函数声明 */

// 工具函数
unsigned int get_order(size_t size);
unsigned int find_smaller_power_of_2(size_t size);
unsigned int find_larger_power_of_2(size_t size);
bool is_power_of_2(size_t size);

// 伙伴系统初始化
void buddy_system_init(void);
void buddy_system_init_memmap(struct Page *base, size_t n);

// 内存分配释放
struct Page *buddy_alloc_pages(size_t n);
void buddy_free_pages(struct Page *base, size_t n);
size_t buddy_system_nr_free_pages(void);

// 伙伴块操作
struct Page *get_buddy_block(struct Page *page, unsigned int order);
bool is_buddy_blocks(struct Page *block1, struct Page *block2, unsigned int order);

// 调试和验证
void show_buddy_array(unsigned int start_order, unsigned int end_order);
void buddy_system_check(void);
void buddy_pmm_check(void);

// 统计信息
void buddy_get_statistics(unsigned int *orders_nr_free, size_t *total_fragmentation);

/* 与 ucore PMM 框架的接口 */
extern const struct pmm_manager buddy_pmm_manager;

#endif /* !__KERN_MM_BUDDY_H__ */