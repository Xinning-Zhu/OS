#include <slub.h>
#include <list.h>
#include <defs.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
#include <pmm.h>
#include <mmu.h>

// 如果 to_struct 宏不存在，定义它
#ifndef to_struct
#define to_struct(ptr, type, member)                               \
    ((type *)((char *)(ptr) - offsetof(type, member)))
#endif

// 如果 page2kva 不存在，但 page2pa 存在，我们可以自己定义
#ifndef page2kva
static inline void *page2kva(struct Page *page) {
    uintptr_t pa = page2pa(page);
    // 使用正确的偏移量
    uintptr_t offset = 0xFFFFFFFF40200000;
    uintptr_t kva = pa + offset;
    return (void *)kva;
}
#endif

// 修复 le2slab 宏
#ifndef le2slab
#define le2slab(le, member)                    \
    to_struct((le), struct slab_t, member)
#endif

// 全局变量
static list_entry_t cache_chain;
static struct kmem_cache_t cache_cache;
static struct kmem_cache_t *sized_caches[SIZED_CACHE_NUM];
static char *cache_cache_name = "cache";
static char *sized_cache_name = "sized";

// 标记初始化状态
static int initialized = 0;

// kmem_cache_grow - add a free slab
static void * kmem_cache_grow(struct kmem_cache_t *cachep) {
    struct Page *page = alloc_page();
    if (page == NULL) {
        return NULL;
    }
    
    void *kva = page2kva(page);
    
    // 重要：页面布局应该是 [slab_t][bufctl][objects]
    
    // Init slub meta data - 放在页面开头
    struct slab_t *slab = (struct slab_t *)kva;
    
    slab->cachep = cachep;
    slab->inuse = 0;
    slab->free = 0;  // 第一个空闲对象的索引
    
    // bufctl 放在 slab 结构之后
    int16_t *bufctl = (int16_t *)(slab + 1);
    
    // 计算可用的对象数量（考虑 slab_t 占用的空间）
    size_t slab_size = sizeof(struct slab_t);
    size_t bufctl_size = sizeof(int16_t) * cachep->num;
    size_t objects_size = cachep->objsize * cachep->num;
    size_t total_required = slab_size + bufctl_size + objects_size;
    
    if (total_required > PGSIZE) {
        free_page(page);
        return NULL;
    }
    
    // Objects 放在 bufctl 之后
    void *buf = (void *)bufctl + bufctl_size;
    
    // 初始化 bufctl 链表：0->1->2->...->(num-1)->-1
    for (int i = 0; i < cachep->num - 1; i++) {
        bufctl[i] = i + 1;
    }
    bufctl[cachep->num - 1] = -1;  // 链表结束
    
    // 设置第一个空闲对象
    slab->free = 0;
    
    // 调用构造函数（如果有）
    if (cachep->ctor != NULL) {
        for (int i = 0; i < cachep->num; i++) {
            void *obj = buf + i * cachep->objsize;
            cachep->ctor(obj, cachep, cachep->objsize);
        }
    }
    
    // 添加到空闲列表
    list_add(&(cachep->slabs_free), &(slab->slab_link));
    
    return slab;
}

// kmem_slab_destroy - destroy a slab
static void kmem_slab_destroy(struct kmem_cache_t *cachep, struct slab_t *slab) {
    // 直接使用 slab 地址，不需要 page2kva
    int16_t *bufctl = (int16_t *)(slab + 1);
    void *buf = (void *)bufctl + sizeof(int16_t) * cachep->num;
    
    if (cachep->dtor != NULL) {
        for (int i = 0; i < cachep->num; i++) {
            void *obj = buf + i * cachep->objsize;
            cachep->dtor(obj, cachep, cachep->objsize);
        }
    }
    
    // 获取 Page 结构（需要从虚拟地址转换）
    struct Page *page = pa2page(PADDR(slab));
    free_page(page);
}

static int kmem_sized_index(size_t size) {
    // Round up 
    size_t rsize = size;
    if (rsize < SIZED_CACHE_MIN) {
        rsize = SIZED_CACHE_MIN;
    }
    if (rsize > SIZED_CACHE_MAX) {
        rsize = SIZED_CACHE_MAX;
    }
    
    // Find index
    int index = 0;
    size_t temp = rsize;
    while (temp > SIZED_CACHE_MIN) {
        temp >>= 1;
        index++;
    }
    return index;
}

// kmem_cache_create - create a kmem_cache
struct kmem_cache_t * kmem_cache_create(const char *name, size_t size,
                       void (*ctor)(void*, struct kmem_cache_t *, size_t),
                       void (*dtor)(void*, struct kmem_cache_t *, size_t)) {
    // 确保对象大小合理
    if (size > PGSIZE - sizeof(struct slab_t) - sizeof(int16_t)) {
        return NULL;
    }
    
    struct kmem_cache_t *cachep = kmem_cache_alloc(&cache_cache);
    
    if (cachep == NULL) {
        return NULL;
    }
    
    cachep->objsize = size;
    
    // 重新计算对象数量（考虑内存布局）
    size_t slab_size = sizeof(struct slab_t);
    size_t available_space = PGSIZE - slab_size;
    
    // 计算最大对象数量：available_space = bufctl_size + objects_size
    // bufctl_size = num * sizeof(int16_t)
    // objects_size = num * objsize
    // 所以：num * (sizeof(int16_t) + objsize) <= available_space
    cachep->num = available_space / (sizeof(int16_t) + size);
    
    if (cachep->num < 1) {
        cachep->num = 1;
    }
    
    cachep->ctor = ctor;
    cachep->dtor = dtor;
    memcpy(cachep->name, name, CACHE_NAMELEN);
    list_init(&(cachep->slabs_full));
    list_init(&(cachep->slabs_partial));
    list_init(&(cachep->slabs_free));
    list_add(&cache_chain, &(cachep->cache_link));
    
    return cachep;
}

// kmem_cache_destroy - destroy a kmem_cache
void kmem_cache_destroy(struct kmem_cache_t *cachep) {
    if (cachep == NULL) return;
    
    list_entry_t *head, *le;
    
    // Destroy full slabs
    head = &(cachep->slabs_full);
    le = list_next(head);
    while (le != head) {
        list_entry_t *temp = le;
        le = list_next(le);
        kmem_slab_destroy(cachep, le2slab(temp, slab_link));
    }
    
    // Destroy partial slabs 
    head = &(cachep->slabs_partial);
    le = list_next(head);
    while (le != head) {
        list_entry_t *temp = le;
        le = list_next(le);
        kmem_slab_destroy(cachep, le2slab(temp, slab_link));
    }
    
    // Destroy free slabs 
    head = &(cachep->slabs_free);
    le = list_next(head);
    while (le != head) {
        list_entry_t *temp = le;
        le = list_next(le);
        kmem_slab_destroy(cachep, le2slab(temp, slab_link));
    }
    
    // 从全局链表中移除
    list_del(&(cachep->cache_link));
    
    // Free kmem_cache 
    kmem_cache_free(&cache_cache, cachep);
}   

// kmem_cache_alloc - allocate an object
void * kmem_cache_alloc(struct kmem_cache_t *cachep) {
    if (cachep == NULL) return NULL;
    
    list_entry_t *le = NULL;
    
    // 首先检查部分使用的slab
    if (!list_empty(&(cachep->slabs_partial))) {
        le = list_next(&(cachep->slabs_partial));
    }
    // 然后检查空闲slab
    else if (!list_empty(&(cachep->slabs_free))) {
        le = list_next(&(cachep->slabs_free));
    }
    
    // 如果没有可用slab，则增长
    if (le == NULL) {
        if (kmem_cache_grow(cachep) == NULL) {
            return NULL;
        }
        if (!list_empty(&(cachep->slabs_free))) {
            le = list_next(&(cachep->slabs_free));
        } else {
            return NULL;
        }
    }
    
    // 从链表中移除slab
    list_del(le);
    
    struct slab_t *slab = le2slab(le, slab_link);
    
    // 重要修复：直接使用 slab 地址，不需要调用 page2kva
    int16_t *bufctl = (int16_t *)(slab + 1);
    void *buf = (void *)bufctl + sizeof(int16_t) * cachep->num;
    
    // 获取要分配的对象索引
    int obj_index = slab->free;
    
    if (obj_index < 0 || obj_index >= cachep->num) {
        return NULL;
    }
    
    void *objp = buf + obj_index * cachep->objsize;
    
    // 更新slab状态：移动free指针到下一个空闲对象
    slab->free = bufctl[obj_index];
    slab->inuse++;
    
    // 根据使用情况将slab放回相应列表
    if (slab->inuse == cachep->num) {
        list_add(&(cachep->slabs_full), le);
    } else {
        list_add(&(cachep->slabs_partial), le);
    }
    
    return objp;
}

// kmem_cache_zalloc - allocate an object and fill it with zero
void * kmem_cache_zalloc(struct kmem_cache_t *cachep) {
    void *objp = kmem_cache_alloc(cachep);
    if (objp != NULL) {
        memset(objp, 0, cachep->objsize);
    }
    return objp;
}

// kmem_cache_free - free an object
void kmem_cache_free(struct kmem_cache_t *cachep, void *objp) {
    if (cachep == NULL || objp == NULL) return;
    
    // 从对象指针计算slab地址
    uintptr_t page_addr = (uintptr_t)objp & ~(PGSIZE - 1);
    struct slab_t *slab = (struct slab_t *)page_addr;
    
    // 验证cachep指针是否匹配
    if (slab->cachep != cachep) {
        return;
    }
    
    // 计算对象在对象缓冲区中的偏移
    int16_t *bufctl = (int16_t *)(slab + 1);
    void *buf = (void *)bufctl + sizeof(int16_t) * cachep->num;
    
    // 计算对象索引
    int offset = (objp - buf) / cachep->objsize;
    
    if (offset < 0 || offset >= cachep->num) {
        return;
    }
    
    // 从当前列表中移除slab
    list_del(&(slab->slab_link));
    
    // 更新bufctl：将释放的对象添加到空闲链表头部
    bufctl[offset] = slab->free;
    slab->free = offset;
    slab->inuse--;
    
    // 根据使用情况将slab放回相应列表
    if (slab->inuse == 0) {
        list_add(&(cachep->slabs_free), &(slab->slab_link));
    } else {
        list_add(&(cachep->slabs_partial), &(slab->slab_link));
    }
}

// kmem_cache_size - get object size
size_t kmem_cache_size(struct kmem_cache_t *cachep) {
    return cachep->objsize;
}

// kmem_cache_name - get cache name
const char * kmem_cache_name(struct kmem_cache_t *cachep) {
    return cachep->name;
}

// kmem_cache_shrink - destroy all slabs in free list 
int kmem_cache_shrink(struct kmem_cache_t *cachep) {
    if (cachep == NULL) return 0;
    
    int count = 0;
    list_entry_t *le = list_next(&(cachep->slabs_free));
    while (le != &(cachep->slabs_free)) {
        list_entry_t *temp = le;
        le = list_next(le);
        kmem_slab_destroy(cachep, le2slab(temp, slab_link));
        count++;
    }
    return count;
}

// kmem_cache_reap - reap all free slabs 
int kmem_cache_reap() {
    int count = 0;
    list_entry_t *le = list_next(&cache_chain);
    while (le != &cache_chain) {
        struct kmem_cache_t *cachep = to_struct(le, struct kmem_cache_t, cache_link);
        count += kmem_cache_shrink(cachep);
        le = list_next(le);
    }
    return count;
}

void * kmalloc(size_t size) {
    if (!initialized) return NULL;
    if (size > SIZED_CACHE_MAX) {
        return NULL;
    }
    if (size == 0) {
        return NULL;
    }
    int index = kmem_sized_index(size);
    if (index < 0 || index >= SIZED_CACHE_NUM) {
        return NULL;
    }
    return kmem_cache_alloc(sized_caches[index]);
}

void kfree(void *objp) {
    if (objp == NULL || !initialized) return;
    
    // 对象所在的页面开头就是 slab 结构
    uintptr_t page_addr = (uintptr_t)objp & ~(PGSIZE - 1);
    struct slab_t *slab = (struct slab_t *)page_addr;
    
    if (slab->cachep == NULL) {
        return;
    }
    
    kmem_cache_free(slab->cachep, objp);
}

size_t ksize(void *objp) {
    if (objp == NULL || !initialized) return 0;
    
    // 对象所在的页面开头就是 slab 结构
    uintptr_t page_addr = (uintptr_t)objp & ~(PGSIZE - 1);
    struct slab_t *slab = (struct slab_t *)page_addr;
    return kmem_cache_size(slab->cachep);
}

// 清理函数 - 在系统关闭时调用
void kmem_cleanup(void) {
    if (!initialized) return;
    
    // 销毁所有 sized caches
    for (int i = 0; i < SIZED_CACHE_NUM; i++) {
        if (sized_caches[i] != NULL) {
            kmem_cache_destroy(sized_caches[i]);
            sized_caches[i] = NULL;
        }
    }
    
    // 销毁 cache_cache 中的所有 slab
    kmem_cache_shrink(&cache_cache);
    
    initialized = 0;
}

void kmem_int() {
    if (initialized) return;
    
    // 完整初始化 cache_cache
    cache_cache.objsize = sizeof(struct kmem_cache_t);
    
    // 重新计算对象数量，确保考虑内存布局
    size_t slab_size = sizeof(struct slab_t);
    size_t available_space = PGSIZE - slab_size;
    cache_cache.num = available_space / (sizeof(int16_t) + sizeof(struct kmem_cache_t));
    
    if (cache_cache.num < 1) {
        cache_cache.num = 1;
    }
    
    cache_cache.ctor = NULL;
    cache_cache.dtor = NULL;
    memcpy(cache_cache.name, cache_cache_name, CACHE_NAMELEN);
    list_init(&(cache_cache.slabs_full));
    list_init(&(cache_cache.slabs_partial));
    list_init(&(cache_cache.slabs_free));
    
    // 初始化 cache_chain
    list_init(&cache_chain);
    list_add(&cache_chain, &(cache_cache.cache_link));
    
    // 初始化 sized caches
    for (int i = 0; i < SIZED_CACHE_NUM; i++) {
        size_t size = SIZED_CACHE_MIN * (1 << i);
        char name[16];
        snprintf(name, sizeof(name), "size-%d", size);
        
        sized_caches[i] = kmem_cache_create(name, size, NULL, NULL);
    }
    
    initialized = 1;
}