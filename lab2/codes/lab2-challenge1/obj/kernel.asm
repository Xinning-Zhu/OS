
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	6ac50513          	addi	a0,a0,1708 # ffffffffc02016f8 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	6b650513          	addi	a0,a0,1718 # ffffffffc0201718 <etext+0x22>
ffffffffc020006a:	0e2000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	68858593          	addi	a1,a1,1672 # ffffffffc02016f6 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	6c250513          	addi	a0,a0,1730 # ffffffffc0201738 <etext+0x42>
ffffffffc020007e:	0ce000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <buddy_sys>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	6ce50513          	addi	a0,a0,1742 # ffffffffc0201758 <etext+0x62>
ffffffffc0200092:	0ba000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	17a58593          	addi	a1,a1,378 # ffffffffc0206210 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	6da50513          	addi	a0,a0,1754 # ffffffffc0201778 <etext+0x82>
ffffffffc02000a6:	0a6000ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00006597          	auipc	a1,0x6
ffffffffc02000ae:	56558593          	addi	a1,a1,1381 # ffffffffc020660f <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00001517          	auipc	a0,0x1
ffffffffc02000d0:	6cc50513          	addi	a0,a0,1740 # ffffffffc0201798 <etext+0xa2>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a89d                	j	ffffffffc020014c <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00006517          	auipc	a0,0x6
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0206018 <buddy_sys>
ffffffffc02000e0:	00006617          	auipc	a2,0x6
ffffffffc02000e4:	13060613          	addi	a2,a2,304 # ffffffffc0206210 <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	5f4010ef          	jal	ra,ffffffffc02016e4 <memset>
    dtb_init();
ffffffffc02000f4:	12c000ef          	jal	ra,ffffffffc0200220 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	11e000ef          	jal	ra,ffffffffc0200216 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00001517          	auipc	a0,0x1
ffffffffc0200100:	6cc50513          	addi	a0,a0,1740 # ffffffffc02017c8 <etext+0xd2>
ffffffffc0200104:	07e000ef          	jal	ra,ffffffffc0200182 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	77f000ef          	jal	ra,ffffffffc020108a <pmm_init>

    /* do nothing */
    while (1)
ffffffffc0200110:	a001                	j	ffffffffc0200110 <kern_init+0x38>

ffffffffc0200112 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200112:	1141                	addi	sp,sp,-16
ffffffffc0200114:	e022                	sd	s0,0(sp)
ffffffffc0200116:	e406                	sd	ra,8(sp)
ffffffffc0200118:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011a:	0fe000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    (*cnt) ++;
ffffffffc020011e:	401c                	lw	a5,0(s0)
}
ffffffffc0200120:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200122:	2785                	addiw	a5,a5,1
ffffffffc0200124:	c01c                	sw	a5,0(s0)
}
ffffffffc0200126:	6402                	ld	s0,0(sp)
ffffffffc0200128:	0141                	addi	sp,sp,16
ffffffffc020012a:	8082                	ret

ffffffffc020012c <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020012c:	1101                	addi	sp,sp,-32
ffffffffc020012e:	862a                	mv	a2,a0
ffffffffc0200130:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	00000517          	auipc	a0,0x0
ffffffffc0200136:	fe050513          	addi	a0,a0,-32 # ffffffffc0200112 <cputch>
ffffffffc020013a:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc020013c:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013e:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200140:	18e010ef          	jal	ra,ffffffffc02012ce <vprintfmt>
    return cnt;
}
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	4532                	lw	a0,12(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret

ffffffffc020014c <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020014c:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014e:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200152:	8e2a                	mv	t3,a0
ffffffffc0200154:	f42e                	sd	a1,40(sp)
ffffffffc0200156:	f832                	sd	a2,48(sp)
ffffffffc0200158:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	00000517          	auipc	a0,0x0
ffffffffc020015e:	fb850513          	addi	a0,a0,-72 # ffffffffc0200112 <cputch>
ffffffffc0200162:	004c                	addi	a1,sp,4
ffffffffc0200164:	869a                	mv	a3,t1
ffffffffc0200166:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc0200168:	ec06                	sd	ra,24(sp)
ffffffffc020016a:	e0ba                	sd	a4,64(sp)
ffffffffc020016c:	e4be                	sd	a5,72(sp)
ffffffffc020016e:	e8c2                	sd	a6,80(sp)
ffffffffc0200170:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200172:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200174:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200176:	158010ef          	jal	ra,ffffffffc02012ce <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017a:	60e2                	ld	ra,24(sp)
ffffffffc020017c:	4512                	lw	a0,4(sp)
ffffffffc020017e:	6125                	addi	sp,sp,96
ffffffffc0200180:	8082                	ret

ffffffffc0200182 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200182:	1101                	addi	sp,sp,-32
ffffffffc0200184:	e822                	sd	s0,16(sp)
ffffffffc0200186:	ec06                	sd	ra,24(sp)
ffffffffc0200188:	e426                	sd	s1,8(sp)
ffffffffc020018a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018c:	00054503          	lbu	a0,0(a0)
ffffffffc0200190:	c51d                	beqz	a0,ffffffffc02001be <cputs+0x3c>
ffffffffc0200192:	0405                	addi	s0,s0,1
ffffffffc0200194:	4485                	li	s1,1
ffffffffc0200196:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200198:	080000ef          	jal	ra,ffffffffc0200218 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020019c:	00044503          	lbu	a0,0(s0)
ffffffffc02001a0:	008487bb          	addw	a5,s1,s0
ffffffffc02001a4:	0405                	addi	s0,s0,1
ffffffffc02001a6:	f96d                	bnez	a0,ffffffffc0200198 <cputs+0x16>
    (*cnt) ++;
ffffffffc02001a8:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ac:	4529                	li	a0,10
ffffffffc02001ae:	06a000ef          	jal	ra,ffffffffc0200218 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b2:	60e2                	ld	ra,24(sp)
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	6442                	ld	s0,16(sp)
ffffffffc02001b8:	64a2                	ld	s1,8(sp)
ffffffffc02001ba:	6105                	addi	sp,sp,32
ffffffffc02001bc:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001be:	4405                	li	s0,1
ffffffffc02001c0:	b7f5                	j	ffffffffc02001ac <cputs+0x2a>

ffffffffc02001c2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c2:	00006317          	auipc	t1,0x6
ffffffffc02001c6:	00630313          	addi	t1,t1,6 # ffffffffc02061c8 <is_panic>
ffffffffc02001ca:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001ce:	715d                	addi	sp,sp,-80
ffffffffc02001d0:	ec06                	sd	ra,24(sp)
ffffffffc02001d2:	e822                	sd	s0,16(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	000e0363          	beqz	t3,ffffffffc02001e4 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e4:	4785                	li	a5,1
ffffffffc02001e6:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ee:	862e                	mv	a2,a1
ffffffffc02001f0:	85aa                	mv	a1,a0
ffffffffc02001f2:	00001517          	auipc	a0,0x1
ffffffffc02001f6:	5f650513          	addi	a0,a0,1526 # ffffffffc02017e8 <etext+0xf2>
    va_start(ap, fmt);
ffffffffc02001fa:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001fc:	f51ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200200:	65a2                	ld	a1,8(sp)
ffffffffc0200202:	8522                	mv	a0,s0
ffffffffc0200204:	f29ff0ef          	jal	ra,ffffffffc020012c <vcprintf>
    cprintf("\n");
ffffffffc0200208:	00002517          	auipc	a0,0x2
ffffffffc020020c:	a1850513          	addi	a0,a0,-1512 # ffffffffc0201c20 <etext+0x52a>
ffffffffc0200210:	f3dff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200214:	b7f9                	j	ffffffffc02001e2 <__panic+0x20>

ffffffffc0200216 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200216:	8082                	ret

ffffffffc0200218 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200218:	0ff57513          	zext.b	a0,a0
ffffffffc020021c:	4340106f          	j	ffffffffc0201650 <sbi_console_putchar>

ffffffffc0200220 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200220:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200222:	00001517          	auipc	a0,0x1
ffffffffc0200226:	5e650513          	addi	a0,a0,1510 # ffffffffc0201808 <etext+0x112>
void dtb_init(void) {
ffffffffc020022a:	fc86                	sd	ra,120(sp)
ffffffffc020022c:	f8a2                	sd	s0,112(sp)
ffffffffc020022e:	e8d2                	sd	s4,80(sp)
ffffffffc0200230:	f4a6                	sd	s1,104(sp)
ffffffffc0200232:	f0ca                	sd	s2,96(sp)
ffffffffc0200234:	ecce                	sd	s3,88(sp)
ffffffffc0200236:	e4d6                	sd	s5,72(sp)
ffffffffc0200238:	e0da                	sd	s6,64(sp)
ffffffffc020023a:	fc5e                	sd	s7,56(sp)
ffffffffc020023c:	f862                	sd	s8,48(sp)
ffffffffc020023e:	f466                	sd	s9,40(sp)
ffffffffc0200240:	f06a                	sd	s10,32(sp)
ffffffffc0200242:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200244:	f09ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200248:	00006597          	auipc	a1,0x6
ffffffffc020024c:	db85b583          	ld	a1,-584(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200250:	00001517          	auipc	a0,0x1
ffffffffc0200254:	5c850513          	addi	a0,a0,1480 # ffffffffc0201818 <etext+0x122>
ffffffffc0200258:	ef5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020025c:	00006417          	auipc	s0,0x6
ffffffffc0200260:	dac40413          	addi	s0,s0,-596 # ffffffffc0206008 <boot_dtb>
ffffffffc0200264:	600c                	ld	a1,0(s0)
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	5c250513          	addi	a0,a0,1474 # ffffffffc0201828 <etext+0x132>
ffffffffc020026e:	edfff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200272:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200276:	00001517          	auipc	a0,0x1
ffffffffc020027a:	5ca50513          	addi	a0,a0,1482 # ffffffffc0201840 <etext+0x14a>
    if (boot_dtb == 0) {
ffffffffc020027e:	120a0463          	beqz	s4,ffffffffc02003a6 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200282:	57f5                	li	a5,-3
ffffffffc0200284:	07fa                	slli	a5,a5,0x1e
ffffffffc0200286:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028a:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028c:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200290:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200292:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200296:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020029e:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a2:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a6:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a8:	8ec9                	or	a3,a3,a0
ffffffffc02002aa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002ae:	1b7d                	addi	s6,s6,-1
ffffffffc02002b0:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b4:	8dd5                	or	a1,a1,a3
ffffffffc02002b6:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002b8:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002bc:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002be:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9cdd>
ffffffffc02002c2:	10f59163          	bne	a1,a5,ffffffffc02003c4 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002c6:	471c                	lw	a5,8(a4)
ffffffffc02002c8:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ca:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002cc:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d0:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d4:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d8:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002dc:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e0:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e4:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e8:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ec:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f0:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f4:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f6:	01146433          	or	s0,s0,a7
ffffffffc02002fa:	0086969b          	slliw	a3,a3,0x8
ffffffffc02002fe:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200304:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200308:	8c49                	or	s0,s0,a0
ffffffffc020030a:	0166f6b3          	and	a3,a3,s6
ffffffffc020030e:	00ca6a33          	or	s4,s4,a2
ffffffffc0200312:	0167f7b3          	and	a5,a5,s6
ffffffffc0200316:	8c55                	or	s0,s0,a3
ffffffffc0200318:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020031c:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020031e:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200326:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200328:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020032e:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200330:	00001917          	auipc	s2,0x1
ffffffffc0200334:	56090913          	addi	s2,s2,1376 # ffffffffc0201890 <etext+0x19a>
ffffffffc0200338:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033a:	4d91                	li	s11,4
ffffffffc020033c:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020033e:	00001497          	auipc	s1,0x1
ffffffffc0200342:	54a48493          	addi	s1,s1,1354 # ffffffffc0201888 <etext+0x192>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200346:	000a2703          	lw	a4,0(s4)
ffffffffc020034a:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034e:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200352:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200362:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200364:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200368:	0087171b          	slliw	a4,a4,0x8
ffffffffc020036c:	8fd5                	or	a5,a5,a3
ffffffffc020036e:	00eb7733          	and	a4,s6,a4
ffffffffc0200372:	8fd9                	or	a5,a5,a4
ffffffffc0200374:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200376:	09778c63          	beq	a5,s7,ffffffffc020040e <dtb_init+0x1ee>
ffffffffc020037a:	00fbea63          	bltu	s7,a5,ffffffffc020038e <dtb_init+0x16e>
ffffffffc020037e:	07a78663          	beq	a5,s10,ffffffffc02003ea <dtb_init+0x1ca>
ffffffffc0200382:	4709                	li	a4,2
ffffffffc0200384:	00e79763          	bne	a5,a4,ffffffffc0200392 <dtb_init+0x172>
ffffffffc0200388:	4c81                	li	s9,0
ffffffffc020038a:	8a56                	mv	s4,s5
ffffffffc020038c:	bf6d                	j	ffffffffc0200346 <dtb_init+0x126>
ffffffffc020038e:	ffb78ee3          	beq	a5,s11,ffffffffc020038a <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200392:	00001517          	auipc	a0,0x1
ffffffffc0200396:	57650513          	addi	a0,a0,1398 # ffffffffc0201908 <etext+0x212>
ffffffffc020039a:	db3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	5a250513          	addi	a0,a0,1442 # ffffffffc0201940 <etext+0x24a>
}
ffffffffc02003a6:	7446                	ld	s0,112(sp)
ffffffffc02003a8:	70e6                	ld	ra,120(sp)
ffffffffc02003aa:	74a6                	ld	s1,104(sp)
ffffffffc02003ac:	7906                	ld	s2,96(sp)
ffffffffc02003ae:	69e6                	ld	s3,88(sp)
ffffffffc02003b0:	6a46                	ld	s4,80(sp)
ffffffffc02003b2:	6aa6                	ld	s5,72(sp)
ffffffffc02003b4:	6b06                	ld	s6,64(sp)
ffffffffc02003b6:	7be2                	ld	s7,56(sp)
ffffffffc02003b8:	7c42                	ld	s8,48(sp)
ffffffffc02003ba:	7ca2                	ld	s9,40(sp)
ffffffffc02003bc:	7d02                	ld	s10,32(sp)
ffffffffc02003be:	6de2                	ld	s11,24(sp)
ffffffffc02003c0:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c2:	b369                	j	ffffffffc020014c <cprintf>
}
ffffffffc02003c4:	7446                	ld	s0,112(sp)
ffffffffc02003c6:	70e6                	ld	ra,120(sp)
ffffffffc02003c8:	74a6                	ld	s1,104(sp)
ffffffffc02003ca:	7906                	ld	s2,96(sp)
ffffffffc02003cc:	69e6                	ld	s3,88(sp)
ffffffffc02003ce:	6a46                	ld	s4,80(sp)
ffffffffc02003d0:	6aa6                	ld	s5,72(sp)
ffffffffc02003d2:	6b06                	ld	s6,64(sp)
ffffffffc02003d4:	7be2                	ld	s7,56(sp)
ffffffffc02003d6:	7c42                	ld	s8,48(sp)
ffffffffc02003d8:	7ca2                	ld	s9,40(sp)
ffffffffc02003da:	7d02                	ld	s10,32(sp)
ffffffffc02003dc:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003de:	00001517          	auipc	a0,0x1
ffffffffc02003e2:	48250513          	addi	a0,a0,1154 # ffffffffc0201860 <etext+0x16a>
}
ffffffffc02003e6:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e8:	b395                	j	ffffffffc020014c <cprintf>
                int name_len = strlen(name);
ffffffffc02003ea:	8556                	mv	a0,s5
ffffffffc02003ec:	27e010ef          	jal	ra,ffffffffc020166a <strlen>
ffffffffc02003f0:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f2:	4619                	li	a2,6
ffffffffc02003f4:	85a6                	mv	a1,s1
ffffffffc02003f6:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003f8:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fa:	2c4010ef          	jal	ra,ffffffffc02016be <strncmp>
ffffffffc02003fe:	e111                	bnez	a0,ffffffffc0200402 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200400:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200402:	0a91                	addi	s5,s5,4
ffffffffc0200404:	9ad2                	add	s5,s5,s4
ffffffffc0200406:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040a:	8a56                	mv	s4,s5
ffffffffc020040c:	bf2d                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020040e:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041a:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200422:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200426:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042a:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020042e:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200432:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200436:	00eaeab3          	or	s5,s5,a4
ffffffffc020043a:	00fb77b3          	and	a5,s6,a5
ffffffffc020043e:	00faeab3          	or	s5,s5,a5
ffffffffc0200442:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200444:	000c9c63          	bnez	s9,ffffffffc020045c <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200448:	1a82                	slli	s5,s5,0x20
ffffffffc020044a:	00368793          	addi	a5,a3,3
ffffffffc020044e:	020ada93          	srli	s5,s5,0x20
ffffffffc0200452:	9abe                	add	s5,s5,a5
ffffffffc0200454:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200458:	8a56                	mv	s4,s5
ffffffffc020045a:	b5f5                	j	ffffffffc0200346 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020045c:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200460:	85ca                	mv	a1,s2
ffffffffc0200462:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200464:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200468:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046c:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200470:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200474:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200478:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047a:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200482:	8d59                	or	a0,a0,a4
ffffffffc0200484:	00fb77b3          	and	a5,s6,a5
ffffffffc0200488:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048a:	1502                	slli	a0,a0,0x20
ffffffffc020048c:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020048e:	9522                	add	a0,a0,s0
ffffffffc0200490:	210010ef          	jal	ra,ffffffffc02016a0 <strcmp>
ffffffffc0200494:	66a2                	ld	a3,8(sp)
ffffffffc0200496:	f94d                	bnez	a0,ffffffffc0200448 <dtb_init+0x228>
ffffffffc0200498:	fb59f8e3          	bgeu	s3,s5,ffffffffc0200448 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020049c:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a0:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a4:	00001517          	auipc	a0,0x1
ffffffffc02004a8:	3f450513          	addi	a0,a0,1012 # ffffffffc0201898 <etext+0x1a2>
           fdt32_to_cpu(x >> 32);
ffffffffc02004ac:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b0:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b4:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004bc:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c8:	0187d693          	srli	a3,a5,0x18
ffffffffc02004cc:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d0:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d4:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d8:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004dc:	010f6f33          	or	t5,t5,a6
ffffffffc02004e0:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e4:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ec:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f4:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004f8:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fc:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200500:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8361                	srli	a4,a4,0x18
ffffffffc0200506:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050a:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020050e:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200512:	00cb7633          	and	a2,s6,a2
ffffffffc0200516:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051a:	0085959b          	slliw	a1,a1,0x8
ffffffffc020051e:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200522:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200526:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200532:	011b78b3          	and	a7,s6,a7
ffffffffc0200536:	005eeeb3          	or	t4,t4,t0
ffffffffc020053a:	00c6e733          	or	a4,a3,a2
ffffffffc020053e:	006c6c33          	or	s8,s8,t1
ffffffffc0200542:	010b76b3          	and	a3,s6,a6
ffffffffc0200546:	00bb7b33          	and	s6,s6,a1
ffffffffc020054a:	01d7e7b3          	or	a5,a5,t4
ffffffffc020054e:	016c6b33          	or	s6,s8,s6
ffffffffc0200552:	01146433          	or	s0,s0,a7
ffffffffc0200556:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200558:	1702                	slli	a4,a4,0x20
ffffffffc020055a:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020055c:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc020055e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200566:	0167eb33          	or	s6,a5,s6
ffffffffc020056a:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc020056c:	be1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200570:	85a2                	mv	a1,s0
ffffffffc0200572:	00001517          	auipc	a0,0x1
ffffffffc0200576:	34650513          	addi	a0,a0,838 # ffffffffc02018b8 <etext+0x1c2>
ffffffffc020057a:	bd3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020057e:	014b5613          	srli	a2,s6,0x14
ffffffffc0200582:	85da                	mv	a1,s6
ffffffffc0200584:	00001517          	auipc	a0,0x1
ffffffffc0200588:	34c50513          	addi	a0,a0,844 # ffffffffc02018d0 <etext+0x1da>
ffffffffc020058c:	bc1ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200590:	008b05b3          	add	a1,s6,s0
ffffffffc0200594:	15fd                	addi	a1,a1,-1
ffffffffc0200596:	00001517          	auipc	a0,0x1
ffffffffc020059a:	35a50513          	addi	a0,a0,858 # ffffffffc02018f0 <etext+0x1fa>
ffffffffc020059e:	bafff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a2:	00001517          	auipc	a0,0x1
ffffffffc02005a6:	39e50513          	addi	a0,a0,926 # ffffffffc0201940 <etext+0x24a>
        memory_base = mem_base;
ffffffffc02005aa:	00006797          	auipc	a5,0x6
ffffffffc02005ae:	c287b323          	sd	s0,-986(a5) # ffffffffc02061d0 <memory_base>
        memory_size = mem_size;
ffffffffc02005b2:	00006797          	auipc	a5,0x6
ffffffffc02005b6:	c367b323          	sd	s6,-986(a5) # ffffffffc02061d8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005ba:	b3f5                	j	ffffffffc02003a6 <dtb_init+0x186>

ffffffffc02005bc <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005bc:	00006517          	auipc	a0,0x6
ffffffffc02005c0:	c1453503          	ld	a0,-1004(a0) # ffffffffc02061d0 <memory_base>
ffffffffc02005c4:	8082                	ret

ffffffffc02005c6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005c6:	00006517          	auipc	a0,0x6
ffffffffc02005ca:	c1253503          	ld	a0,-1006(a0) # ffffffffc02061d8 <memory_size>
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <show_buddy_array.part.0>:
size_t buddy_system_nr_free_pages(void) {
    return buddy_sys.nr_free_pages;
}

/* 调试函数 */
void show_buddy_array(unsigned int start_order, unsigned int end_order) {
ffffffffc02005d0:	715d                	addi	sp,sp,-80
ffffffffc02005d2:	f84a                	sd	s2,48(sp)
ffffffffc02005d4:	892a                	mv	s2,a0
    if (start_order > end_order || end_order > BUDDY_MAX_ORDER) {
        cprintf("show_buddy_array: invalid order range\n");
        return;
    }
    
    cprintf("=== Buddy System Free Lists ===\n");
ffffffffc02005d6:	00001517          	auipc	a0,0x1
ffffffffc02005da:	38250513          	addi	a0,a0,898 # ffffffffc0201958 <etext+0x262>
void show_buddy_array(unsigned int start_order, unsigned int end_order) {
ffffffffc02005de:	e486                	sd	ra,72(sp)
ffffffffc02005e0:	f44e                	sd	s3,40(sp)
ffffffffc02005e2:	f052                	sd	s4,32(sp)
ffffffffc02005e4:	ec56                	sd	s5,24(sp)
ffffffffc02005e6:	e85a                	sd	s6,16(sp)
ffffffffc02005e8:	8aae                	mv	s5,a1
ffffffffc02005ea:	e45e                	sd	s7,8(sp)
ffffffffc02005ec:	e0a2                	sd	s0,64(sp)
ffffffffc02005ee:	fc26                	sd	s1,56(sp)
ffffffffc02005f0:	e062                	sd	s8,0(sp)
    cprintf("=== Buddy System Free Lists ===\n");
ffffffffc02005f2:	b5bff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Order | BlockSize(Pages) | FreeBlocks | TotalFreePages\n");
ffffffffc02005f6:	00001517          	auipc	a0,0x1
ffffffffc02005fa:	38a50513          	addi	a0,a0,906 # ffffffffc0201980 <etext+0x28a>
ffffffffc02005fe:	b4fff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("------|------------------|------------|----------------\n");
ffffffffc0200602:	00001517          	auipc	a0,0x1
ffffffffc0200606:	3b650513          	addi	a0,a0,950 # ffffffffc02019b8 <etext+0x2c2>
ffffffffc020060a:	b43ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    
    for (unsigned int i = start_order; i <= end_order; i++) {
ffffffffc020060e:	00006a17          	auipc	s4,0x6
ffffffffc0200612:	a0aa0a13          	addi	s4,s4,-1526 # ffffffffc0206018 <buddy_sys>
        unsigned int free_blocks = buddy_sys.free_array[i].nr_free;
        size_t block_size = ORDER_TO_PAGES(i);
ffffffffc0200616:	4b85                	li	s7,1
        size_t total_pages = free_blocks * block_size;
        
        cprintf(" %2u   | %8u        | %6u     | %8u\n", 
ffffffffc0200618:	00001b17          	auipc	s6,0x1
ffffffffc020061c:	3e0b0b13          	addi	s6,s6,992 # ffffffffc02019f8 <etext+0x302>
        
        if (free_blocks > 0) {
            list_entry_t *le = &buddy_sys.free_array[i].free_list;
            while ((le = list_next(le)) != &buddy_sys.free_array[i].free_list) {
                struct Page *page = le2page(le, page_link);
                cprintf("        -> Page: 0x%08x, Order: %u\n", page, PAGE_BUDDY_ORDER(page));
ffffffffc0200620:	00001997          	auipc	s3,0x1
ffffffffc0200624:	40098993          	addi	s3,s3,1024 # ffffffffc0201a20 <etext+0x32a>
    for (unsigned int i = start_order; i <= end_order; i++) {
ffffffffc0200628:	012af663          	bgeu	s5,s2,ffffffffc0200634 <show_buddy_array.part.0+0x64>
ffffffffc020062c:	a8b9                	j	ffffffffc020068a <show_buddy_array.part.0+0xba>
ffffffffc020062e:	2905                	addiw	s2,s2,1
ffffffffc0200630:	052aed63          	bltu	s5,s2,ffffffffc020068a <show_buddy_array.part.0+0xba>
        unsigned int free_blocks = buddy_sys.free_array[i].nr_free;
ffffffffc0200634:	02091793          	slli	a5,s2,0x20
ffffffffc0200638:	9381                	srli	a5,a5,0x20
ffffffffc020063a:	00179493          	slli	s1,a5,0x1
ffffffffc020063e:	94be                	add	s1,s1,a5
ffffffffc0200640:	048e                	slli	s1,s1,0x3
ffffffffc0200642:	009a0c33          	add	s8,s4,s1
ffffffffc0200646:	018c2403          	lw	s0,24(s8) # ff0018 <kern_entry-0xffffffffbf20ffe8>
        cprintf(" %2u   | %8u        | %6u     | %8u\n", 
ffffffffc020064a:	012b9633          	sll	a2,s7,s2
ffffffffc020064e:	85ca                	mv	a1,s2
        size_t total_pages = free_blocks * block_size;
ffffffffc0200650:	02041713          	slli	a4,s0,0x20
ffffffffc0200654:	9301                	srli	a4,a4,0x20
        cprintf(" %2u   | %8u        | %6u     | %8u\n", 
ffffffffc0200656:	01271733          	sll	a4,a4,s2
ffffffffc020065a:	86a2                	mv	a3,s0
ffffffffc020065c:	855a                	mv	a0,s6
ffffffffc020065e:	aefff0ef          	jal	ra,ffffffffc020014c <cprintf>
        if (free_blocks > 0) {
ffffffffc0200662:	d471                	beqz	s0,ffffffffc020062e <show_buddy_array.part.0+0x5e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200664:	010c3403          	ld	s0,16(s8)
            list_entry_t *le = &buddy_sys.free_array[i].free_list;
ffffffffc0200668:	04a1                	addi	s1,s1,8
ffffffffc020066a:	94d2                	add	s1,s1,s4
            while ((le = list_next(le)) != &buddy_sys.free_array[i].free_list) {
ffffffffc020066c:	fc8481e3          	beq	s1,s0,ffffffffc020062e <show_buddy_array.part.0+0x5e>
                cprintf("        -> Page: 0x%08x, Order: %u\n", page, PAGE_BUDDY_ORDER(page));
ffffffffc0200670:	ff842603          	lw	a2,-8(s0)
ffffffffc0200674:	fe840593          	addi	a1,s0,-24
ffffffffc0200678:	854e                	mv	a0,s3
ffffffffc020067a:	ad3ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc020067e:	6400                	ld	s0,8(s0)
            while ((le = list_next(le)) != &buddy_sys.free_array[i].free_list) {
ffffffffc0200680:	fe8498e3          	bne	s1,s0,ffffffffc0200670 <show_buddy_array.part.0+0xa0>
    for (unsigned int i = start_order; i <= end_order; i++) {
ffffffffc0200684:	2905                	addiw	s2,s2,1
ffffffffc0200686:	fb2af7e3          	bgeu	s5,s2,ffffffffc0200634 <show_buddy_array.part.0+0x64>
            }
        }
    }
    
    cprintf("Total free pages: %u\n", buddy_sys.nr_free_pages);
}
ffffffffc020068a:	6406                	ld	s0,64(sp)
    cprintf("Total free pages: %u\n", buddy_sys.nr_free_pages);
ffffffffc020068c:	188a2583          	lw	a1,392(s4)
}
ffffffffc0200690:	60a6                	ld	ra,72(sp)
ffffffffc0200692:	74e2                	ld	s1,56(sp)
ffffffffc0200694:	7942                	ld	s2,48(sp)
ffffffffc0200696:	79a2                	ld	s3,40(sp)
ffffffffc0200698:	7a02                	ld	s4,32(sp)
ffffffffc020069a:	6ae2                	ld	s5,24(sp)
ffffffffc020069c:	6b42                	ld	s6,16(sp)
ffffffffc020069e:	6ba2                	ld	s7,8(sp)
ffffffffc02006a0:	6c02                	ld	s8,0(sp)
    cprintf("Total free pages: %u\n", buddy_sys.nr_free_pages);
ffffffffc02006a2:	00001517          	auipc	a0,0x1
ffffffffc02006a6:	3a650513          	addi	a0,a0,934 # ffffffffc0201a48 <etext+0x352>
}
ffffffffc02006aa:	6161                	addi	sp,sp,80
    cprintf("Total free pages: %u\n", buddy_sys.nr_free_pages);
ffffffffc02006ac:	b445                	j	ffffffffc020014c <cprintf>

ffffffffc02006ae <buddy_nr_free_pages>:
ffffffffc02006ae:	00006517          	auipc	a0,0x6
ffffffffc02006b2:	af256503          	lwu	a0,-1294(a0) # ffffffffc02061a0 <buddy_sys+0x188>
ffffffffc02006b6:	8082                	ret

ffffffffc02006b8 <buddy_system_init>:
    for (int i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc02006b8:	00006797          	auipc	a5,0x6
ffffffffc02006bc:	96878793          	addi	a5,a5,-1688 # ffffffffc0206020 <buddy_sys+0x8>
ffffffffc02006c0:	00006717          	auipc	a4,0x6
ffffffffc02006c4:	ae070713          	addi	a4,a4,-1312 # ffffffffc02061a0 <buddy_sys+0x188>
    elm->prev = elm->next = elm;
ffffffffc02006c8:	e79c                	sd	a5,8(a5)
ffffffffc02006ca:	e39c                	sd	a5,0(a5)
        buddy_sys.free_array[i].nr_free = 0;
ffffffffc02006cc:	0007a823          	sw	zero,16(a5)
    for (int i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc02006d0:	07e1                	addi	a5,a5,24
ffffffffc02006d2:	fee79be3          	bne	a5,a4,ffffffffc02006c8 <buddy_system_init+0x10>
    cprintf("buddy_system: initialized with max_order=%d\n", BUDDY_MAX_ORDER);
ffffffffc02006d6:	45bd                	li	a1,15
ffffffffc02006d8:	00001517          	auipc	a0,0x1
ffffffffc02006dc:	38850513          	addi	a0,a0,904 # ffffffffc0201a60 <etext+0x36a>
    buddy_sys.nr_free_pages = 0;
ffffffffc02006e0:	00006797          	auipc	a5,0x6
ffffffffc02006e4:	ac07a023          	sw	zero,-1344(a5) # ffffffffc02061a0 <buddy_sys+0x188>
    buddy_sys.total_pages = 0;
ffffffffc02006e8:	00006797          	auipc	a5,0x6
ffffffffc02006ec:	ac07b423          	sd	zero,-1336(a5) # ffffffffc02061b0 <buddy_sys+0x198>
    buddy_sys.base_page = NULL;
ffffffffc02006f0:	00006797          	auipc	a5,0x6
ffffffffc02006f4:	aa07bc23          	sd	zero,-1352(a5) # ffffffffc02061a8 <buddy_sys+0x190>
    buddy_sys.max_order = 0;
ffffffffc02006f8:	00006797          	auipc	a5,0x6
ffffffffc02006fc:	9207a023          	sw	zero,-1760(a5) # ffffffffc0206018 <buddy_sys>
    buddy_sys.bitmap = NULL;
ffffffffc0200700:	00006797          	auipc	a5,0x6
ffffffffc0200704:	aa07bc23          	sd	zero,-1352(a5) # ffffffffc02061b8 <buddy_sys+0x1a0>
    buddy_sys.bitmap_size = 0;
ffffffffc0200708:	00006797          	auipc	a5,0x6
ffffffffc020070c:	aa07bc23          	sd	zero,-1352(a5) # ffffffffc02061c0 <buddy_sys+0x1a8>
    cprintf("buddy_system: initialized with max_order=%d\n", BUDDY_MAX_ORDER);
ffffffffc0200710:	bc35                	j	ffffffffc020014c <cprintf>

ffffffffc0200712 <buddy_init>:
}

/* Buddy System 与 ucore 框架的接口层 */
// 接口函数包装器
static void buddy_init(void) {
    buddy_system_init();
ffffffffc0200712:	b75d                	j	ffffffffc02006b8 <buddy_system_init>

ffffffffc0200714 <buddy_system_init_memmap>:
void buddy_system_init_memmap(struct Page *base, size_t n) {
ffffffffc0200714:	715d                	addi	sp,sp,-80
ffffffffc0200716:	e486                	sd	ra,72(sp)
ffffffffc0200718:	e0a2                	sd	s0,64(sp)
ffffffffc020071a:	fc26                	sd	s1,56(sp)
ffffffffc020071c:	f84a                	sd	s2,48(sp)
ffffffffc020071e:	f44e                	sd	s3,40(sp)
ffffffffc0200720:	f052                	sd	s4,32(sp)
ffffffffc0200722:	ec56                	sd	s5,24(sp)
ffffffffc0200724:	e85a                	sd	s6,16(sp)
ffffffffc0200726:	e45e                	sd	s7,8(sp)
ffffffffc0200728:	e062                	sd	s8,0(sp)
    assert(n > 0);
ffffffffc020072a:	1c058263          	beqz	a1,ffffffffc02008ee <buddy_system_init_memmap+0x1da>
ffffffffc020072e:	8aaa                	mv	s5,a0
    assert(base != NULL);
ffffffffc0200730:	18050f63          	beqz	a0,ffffffffc02008ce <buddy_system_init_memmap+0x1ba>
    if (buddy_sys.base_page == NULL) {
ffffffffc0200734:	00006b97          	auipc	s7,0x6
ffffffffc0200738:	8e4b8b93          	addi	s7,s7,-1820 # ffffffffc0206018 <buddy_sys>
ffffffffc020073c:	190bb703          	ld	a4,400(s7)
ffffffffc0200740:	842e                	mv	s0,a1
        buddy_sys.nr_free_pages = n;
ffffffffc0200742:	0005869b          	sext.w	a3,a1
    if (buddy_sys.base_page == NULL) {
ffffffffc0200746:	10070f63          	beqz	a4,ffffffffc0200864 <buddy_system_init_memmap+0x150>
        buddy_sys.nr_free_pages += n;
ffffffffc020074a:	188ba783          	lw	a5,392(s7)
ffffffffc020074e:	9fb5                	addw	a5,a5,a3
ffffffffc0200750:	18fba423          	sw	a5,392(s7)
    for (struct Page *p = base; p < base + n; p++) {
ffffffffc0200754:	00241613          	slli	a2,s0,0x2
ffffffffc0200758:	9622                	add	a2,a2,s0
ffffffffc020075a:	060e                	slli	a2,a2,0x3
ffffffffc020075c:	9656                	add	a2,a2,s5
ffffffffc020075e:	87d6                	mv	a5,s5
ffffffffc0200760:	02caf263          	bgeu	s5,a2,ffffffffc0200784 <buddy_system_init_memmap+0x70>
        assert(PageReserved(p));
ffffffffc0200764:	6798                	ld	a4,8(a5)
ffffffffc0200766:	00177693          	andi	a3,a4,1
ffffffffc020076a:	14068263          	beqz	a3,ffffffffc02008ae <buddy_system_init_memmap+0x19a>
        SetPageProperty(p);
ffffffffc020076e:	00276713          	ori	a4,a4,2
ffffffffc0200772:	e798                	sd	a4,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200774:	0007a023          	sw	zero,0(a5)
        p->property = 0;
ffffffffc0200778:	0007a823          	sw	zero,16(a5)
    for (struct Page *p = base; p < base + n; p++) {
ffffffffc020077c:	02878793          	addi	a5,a5,40
ffffffffc0200780:	fec7e2e3          	bltu	a5,a2,ffffffffc0200764 <buddy_system_init_memmap+0x50>
    cprintf("buddy_system: init memmap: base=0x%08x, %u pages\n", base, n);
ffffffffc0200784:	8622                	mv	a2,s0
ffffffffc0200786:	85d6                	mv	a1,s5
ffffffffc0200788:	00001517          	auipc	a0,0x1
ffffffffc020078c:	38850513          	addi	a0,a0,904 # ffffffffc0201b10 <etext+0x41a>
ffffffffc0200790:	9bdff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while ((current_size << 1) <= size) {
ffffffffc0200794:	4c05                	li	s8,1
        if (block_order < 4) { 
ffffffffc0200796:	490d                	li	s2,3
            block_order = (remaining >= 16) ? 4 : find_smaller_power_of_2(remaining);
ffffffffc0200798:	49bd                	li	s3,15
ffffffffc020079a:	4a11                	li	s4,4
        cprintf("  -> added order %u block (%u pages) at 0x%08x\n", 
ffffffffc020079c:	00001497          	auipc	s1,0x1
ffffffffc02007a0:	3bc48493          	addi	s1,s1,956 # ffffffffc0201b58 <etext+0x462>
        if (block_order > buddy_sys.max_order) {
ffffffffc02007a4:	000ba703          	lw	a4,0(s7)
    while ((current_size << 1) <= size) {
ffffffffc02007a8:	0b840a63          	beq	s0,s8,ffffffffc020085c <buddy_system_init_memmap+0x148>
ffffffffc02007ac:	4789                	li	a5,2
    unsigned int order = 0;
ffffffffc02007ae:	4581                	li	a1,0
    while ((current_size << 1) <= size) {
ffffffffc02007b0:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc02007b2:	2585                	addiw	a1,a1,1
    while ((current_size << 1) <= size) {
ffffffffc02007b4:	fef47ee3          	bgeu	s0,a5,ffffffffc02007b0 <buddy_system_init_memmap+0x9c>
        if (block_order < 4) { 
ffffffffc02007b8:	08b97763          	bgeu	s2,a1,ffffffffc0200846 <buddy_system_init_memmap+0x132>
ffffffffc02007bc:	8b2e                	mv	s6,a1
ffffffffc02007be:	00b77363          	bgeu	a4,a1,ffffffffc02007c4 <buddy_system_init_memmap+0xb0>
ffffffffc02007c2:	8b3a                	mv	s6,a4
ffffffffc02007c4:	000b079b          	sext.w	a5,s6
        size_t block_pages = ORDER_TO_PAGES(block_order);
ffffffffc02007c8:	016c1b33          	sll	s6,s8,s6
        if (block_pages > remaining) {
ffffffffc02007cc:	09647a63          	bgeu	s0,s6,ffffffffc0200860 <buddy_system_init_memmap+0x14c>
            block_pages = ORDER_TO_PAGES(block_order);
ffffffffc02007d0:	00bc1b33          	sll	s6,s8,a1
    __list_add(elm, listelm, listelm->next);
ffffffffc02007d4:	02059713          	slli	a4,a1,0x20
ffffffffc02007d8:	9301                	srli	a4,a4,0x20
ffffffffc02007da:	00171793          	slli	a5,a4,0x1
ffffffffc02007de:	97ba                	add	a5,a5,a4
        SET_PAGE_ORDER(current_block, block_order);
ffffffffc02007e0:	008ab683          	ld	a3,8(s5)
ffffffffc02007e4:	078e                	slli	a5,a5,0x3
ffffffffc02007e6:	00fb8733          	add	a4,s7,a5
ffffffffc02007ea:	6b10                	ld	a2,16(a4)
ffffffffc02007ec:	0026e693          	ori	a3,a3,2
ffffffffc02007f0:	00dab423          	sd	a3,8(s5)
ffffffffc02007f4:	00baa823          	sw	a1,16(s5)
        buddy_sys.free_array[block_order].nr_free++;
ffffffffc02007f8:	4f14                	lw	a3,24(a4)
        list_add(&buddy_sys.free_array[block_order].free_list, &(current_block->page_link));
ffffffffc02007fa:	018a8513          	addi	a0,s5,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02007fe:	e208                	sd	a0,0(a2)
ffffffffc0200800:	07a1                	addi	a5,a5,8
ffffffffc0200802:	eb08                	sd	a0,16(a4)
ffffffffc0200804:	97de                	add	a5,a5,s7
    elm->next = next;
ffffffffc0200806:	02cab023          	sd	a2,32(s5)
    elm->prev = prev;
ffffffffc020080a:	00fabc23          	sd	a5,24(s5)
        buddy_sys.free_array[block_order].nr_free++;
ffffffffc020080e:	0016879b          	addiw	a5,a3,1
ffffffffc0200812:	cf1c                	sw	a5,24(a4)
        cprintf("  -> added order %u block (%u pages) at 0x%08x\n", 
ffffffffc0200814:	86d6                	mv	a3,s5
ffffffffc0200816:	865a                	mv	a2,s6
ffffffffc0200818:	8526                	mv	a0,s1
ffffffffc020081a:	933ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        current_block += block_pages;
ffffffffc020081e:	002b1793          	slli	a5,s6,0x2
ffffffffc0200822:	97da                	add	a5,a5,s6
ffffffffc0200824:	078e                	slli	a5,a5,0x3
        remaining -= block_pages;
ffffffffc0200826:	41640433          	sub	s0,s0,s6
        current_block += block_pages;
ffffffffc020082a:	9abe                	add	s5,s5,a5
    while (remaining > 0) {
ffffffffc020082c:	fc25                	bnez	s0,ffffffffc02007a4 <buddy_system_init_memmap+0x90>
}
ffffffffc020082e:	60a6                	ld	ra,72(sp)
ffffffffc0200830:	6406                	ld	s0,64(sp)
ffffffffc0200832:	74e2                	ld	s1,56(sp)
ffffffffc0200834:	7942                	ld	s2,48(sp)
ffffffffc0200836:	79a2                	ld	s3,40(sp)
ffffffffc0200838:	7a02                	ld	s4,32(sp)
ffffffffc020083a:	6ae2                	ld	s5,24(sp)
ffffffffc020083c:	6b42                	ld	s6,16(sp)
ffffffffc020083e:	6ba2                	ld	s7,8(sp)
ffffffffc0200840:	6c02                	ld	s8,0(sp)
ffffffffc0200842:	6161                	addi	sp,sp,80
ffffffffc0200844:	8082                	ret
            block_order = (remaining >= 16) ? 4 : find_smaller_power_of_2(remaining);
ffffffffc0200846:	f689fbe3          	bgeu	s3,s0,ffffffffc02007bc <buddy_system_init_memmap+0xa8>
        if (block_order > buddy_sys.max_order) {
ffffffffc020084a:	8b3a                	mv	s6,a4
ffffffffc020084c:	00ea7363          	bgeu	s4,a4,ffffffffc0200852 <buddy_system_init_memmap+0x13e>
ffffffffc0200850:	4b11                	li	s6,4
ffffffffc0200852:	000b059b          	sext.w	a1,s6
        size_t block_pages = ORDER_TO_PAGES(block_order);
ffffffffc0200856:	016c1b33          	sll	s6,s8,s6
        if (block_pages > remaining) {
ffffffffc020085a:	bfad                	j	ffffffffc02007d4 <buddy_system_init_memmap+0xc0>
    while ((current_size << 1) <= size) {
ffffffffc020085c:	4b05                	li	s6,1
ffffffffc020085e:	4781                	li	a5,0
ffffffffc0200860:	85be                	mv	a1,a5
ffffffffc0200862:	bf8d                	j	ffffffffc02007d4 <buddy_system_init_memmap+0xc0>
        buddy_sys.total_pages = n;
ffffffffc0200864:	18bbbc23          	sd	a1,408(s7)
        buddy_sys.base_page = base;
ffffffffc0200868:	18abb823          	sd	a0,400(s7)
        buddy_sys.nr_free_pages = n;
ffffffffc020086c:	18dba423          	sw	a3,392(s7)
    if (size == 1) return 0;  
ffffffffc0200870:	4705                	li	a4,1
    while ((current_size << 1) <= size) {
ffffffffc0200872:	4789                	li	a5,2
    unsigned int order = 0;
ffffffffc0200874:	4581                	li	a1,0
    if (size == 1) return 0;  
ffffffffc0200876:	02e40463          	beq	s0,a4,ffffffffc020089e <buddy_system_init_memmap+0x18a>
    while ((current_size << 1) <= size) {
ffffffffc020087a:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc020087c:	2585                	addiw	a1,a1,1
    while ((current_size << 1) <= size) {
ffffffffc020087e:	fef47ee3          	bgeu	s0,a5,ffffffffc020087a <buddy_system_init_memmap+0x166>
        if (buddy_sys.max_order > BUDDY_MAX_ORDER) {
ffffffffc0200882:	47bd                	li	a5,15
ffffffffc0200884:	02b7f263          	bgeu	a5,a1,ffffffffc02008a8 <buddy_system_init_memmap+0x194>
            buddy_sys.max_order = BUDDY_MAX_ORDER;
ffffffffc0200888:	00fba023          	sw	a5,0(s7)
ffffffffc020088c:	45bd                	li	a1,15
        cprintf("buddy_system: global max_order set to %u (total pages %u)\n", 
ffffffffc020088e:	8622                	mv	a2,s0
ffffffffc0200890:	00001517          	auipc	a0,0x1
ffffffffc0200894:	24050513          	addi	a0,a0,576 # ffffffffc0201ad0 <etext+0x3da>
ffffffffc0200898:	8b5ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc020089c:	bd65                	j	ffffffffc0200754 <buddy_system_init_memmap+0x40>
        buddy_sys.max_order = find_smaller_power_of_2(n);
ffffffffc020089e:	00005797          	auipc	a5,0x5
ffffffffc02008a2:	7607ad23          	sw	zero,1914(a5) # ffffffffc0206018 <buddy_sys>
        if (buddy_sys.max_order > BUDDY_MAX_ORDER) {
ffffffffc02008a6:	b7e5                	j	ffffffffc020088e <buddy_system_init_memmap+0x17a>
        buddy_sys.max_order = find_smaller_power_of_2(n);
ffffffffc02008a8:	00bba023          	sw	a1,0(s7)
ffffffffc02008ac:	b7cd                	j	ffffffffc020088e <buddy_system_init_memmap+0x17a>
        assert(PageReserved(p));
ffffffffc02008ae:	00001697          	auipc	a3,0x1
ffffffffc02008b2:	29a68693          	addi	a3,a3,666 # ffffffffc0201b48 <etext+0x452>
ffffffffc02008b6:	00001617          	auipc	a2,0x1
ffffffffc02008ba:	1e260613          	addi	a2,a2,482 # ffffffffc0201a98 <etext+0x3a2>
ffffffffc02008be:	06600593          	li	a1,102
ffffffffc02008c2:	00001517          	auipc	a0,0x1
ffffffffc02008c6:	1ee50513          	addi	a0,a0,494 # ffffffffc0201ab0 <etext+0x3ba>
ffffffffc02008ca:	8f9ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(base != NULL);
ffffffffc02008ce:	00001697          	auipc	a3,0x1
ffffffffc02008d2:	1f268693          	addi	a3,a3,498 # ffffffffc0201ac0 <etext+0x3ca>
ffffffffc02008d6:	00001617          	auipc	a2,0x1
ffffffffc02008da:	1c260613          	addi	a2,a2,450 # ffffffffc0201a98 <etext+0x3a2>
ffffffffc02008de:	05400593          	li	a1,84
ffffffffc02008e2:	00001517          	auipc	a0,0x1
ffffffffc02008e6:	1ce50513          	addi	a0,a0,462 # ffffffffc0201ab0 <etext+0x3ba>
ffffffffc02008ea:	8d9ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(n > 0);
ffffffffc02008ee:	00001697          	auipc	a3,0x1
ffffffffc02008f2:	1a268693          	addi	a3,a3,418 # ffffffffc0201a90 <etext+0x39a>
ffffffffc02008f6:	00001617          	auipc	a2,0x1
ffffffffc02008fa:	1a260613          	addi	a2,a2,418 # ffffffffc0201a98 <etext+0x3a2>
ffffffffc02008fe:	05300593          	li	a1,83
ffffffffc0200902:	00001517          	auipc	a0,0x1
ffffffffc0200906:	1ae50513          	addi	a0,a0,430 # ffffffffc0201ab0 <etext+0x3ba>
ffffffffc020090a:	8b9ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc020090e <buddy_init_memmap>:
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    buddy_system_init_memmap(base, n);
ffffffffc020090e:	b519                	j	ffffffffc0200714 <buddy_system_init_memmap>

ffffffffc0200910 <buddy_alloc_pages>:
struct Page *buddy_alloc_pages(size_t n) {
ffffffffc0200910:	711d                	addi	sp,sp,-96
ffffffffc0200912:	ec86                	sd	ra,88(sp)
ffffffffc0200914:	e8a2                	sd	s0,80(sp)
ffffffffc0200916:	e4a6                	sd	s1,72(sp)
ffffffffc0200918:	e0ca                	sd	s2,64(sp)
ffffffffc020091a:	fc4e                	sd	s3,56(sp)
ffffffffc020091c:	f852                	sd	s4,48(sp)
ffffffffc020091e:	f456                	sd	s5,40(sp)
ffffffffc0200920:	f05a                	sd	s6,32(sp)
ffffffffc0200922:	ec5e                	sd	s7,24(sp)
    assert(n > 0);
ffffffffc0200924:	20050163          	beqz	a0,ffffffffc0200b26 <buddy_alloc_pages+0x216>
    if (n > buddy_sys.nr_free_pages) {
ffffffffc0200928:	00005a97          	auipc	s5,0x5
ffffffffc020092c:	6f0a8a93          	addi	s5,s5,1776 # ffffffffc0206018 <buddy_sys>
ffffffffc0200930:	188aa603          	lw	a2,392(s5)
ffffffffc0200934:	02061793          	slli	a5,a2,0x20
ffffffffc0200938:	9381                	srli	a5,a5,0x20
ffffffffc020093a:	1aa7e463          	bltu	a5,a0,ffffffffc0200ae2 <buddy_alloc_pages+0x1d2>
    while (current_size < size) {
ffffffffc020093e:	4685                	li	a3,1
    if (req_order > buddy_sys.max_order) {
ffffffffc0200940:	000aa603          	lw	a2,0(s5)
    unsigned int order = 0;
ffffffffc0200944:	4701                	li	a4,0
    size_t current_size = 1;
ffffffffc0200946:	4785                	li	a5,1
    return (order > BUDDY_MAX_ORDER) ? BUDDY_MAX_ORDER : order;
ffffffffc0200948:	4b01                	li	s6,0
    while (current_size < size) {
ffffffffc020094a:	00d50d63          	beq	a0,a3,ffffffffc0200964 <buddy_alloc_pages+0x54>
        current_size <<= 1;
ffffffffc020094e:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc0200950:	2705                	addiw	a4,a4,1
    while (current_size < size) {
ffffffffc0200952:	fea7eee3          	bltu	a5,a0,ffffffffc020094e <buddy_alloc_pages+0x3e>
    return (order > BUDDY_MAX_ORDER) ? BUDDY_MAX_ORDER : order;
ffffffffc0200956:	47bd                	li	a5,15
ffffffffc0200958:	00070b1b          	sext.w	s6,a4
ffffffffc020095c:	04e7e763          	bltu	a5,a4,ffffffffc02009aa <buddy_alloc_pages+0x9a>
    if (req_order > buddy_sys.max_order) {
ffffffffc0200960:	17666863          	bltu	a2,s6,ffffffffc0200ad0 <buddy_alloc_pages+0x1c0>
    return (order > BUDDY_MAX_ORDER) ? BUDDY_MAX_ORDER : order;
ffffffffc0200964:	85da                	mv	a1,s6
        if (buddy_sys.free_array[current_order].nr_free > 0) {
ffffffffc0200966:	02059793          	slli	a5,a1,0x20
ffffffffc020096a:	9381                	srli	a5,a5,0x20
ffffffffc020096c:	00179413          	slli	s0,a5,0x1
ffffffffc0200970:	943e                	add	s0,s0,a5
ffffffffc0200972:	040e                	slli	s0,s0,0x3
ffffffffc0200974:	008a87b3          	add	a5,s5,s0
ffffffffc0200978:	4f9c                	lw	a5,24(a5)
ffffffffc020097a:	ef85                	bnez	a5,ffffffffc02009b2 <buddy_alloc_pages+0xa2>
        current_order++;
ffffffffc020097c:	2585                	addiw	a1,a1,1
    while (current_order <= buddy_sys.max_order) {
ffffffffc020097e:	feb674e3          	bgeu	a2,a1,ffffffffc0200966 <buddy_alloc_pages+0x56>
        cprintf("buddy_alloc_pages: no block found (req order %u)\n", req_order);
ffffffffc0200982:	85da                	mv	a1,s6
ffffffffc0200984:	00001517          	auipc	a0,0x1
ffffffffc0200988:	26c50513          	addi	a0,a0,620 # ffffffffc0201bf0 <etext+0x4fa>
ffffffffc020098c:	fc0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc0200990:	4b81                	li	s7,0
}
ffffffffc0200992:	60e6                	ld	ra,88(sp)
ffffffffc0200994:	6446                	ld	s0,80(sp)
ffffffffc0200996:	64a6                	ld	s1,72(sp)
ffffffffc0200998:	6906                	ld	s2,64(sp)
ffffffffc020099a:	79e2                	ld	s3,56(sp)
ffffffffc020099c:	7a42                	ld	s4,48(sp)
ffffffffc020099e:	7aa2                	ld	s5,40(sp)
ffffffffc02009a0:	7b02                	ld	s6,32(sp)
ffffffffc02009a2:	855e                	mv	a0,s7
ffffffffc02009a4:	6be2                	ld	s7,24(sp)
ffffffffc02009a6:	6125                	addi	sp,sp,96
ffffffffc02009a8:	8082                	ret
    return (order > BUDDY_MAX_ORDER) ? BUDDY_MAX_ORDER : order;
ffffffffc02009aa:	4b3d                	li	s6,15
    if (req_order > buddy_sys.max_order) {
ffffffffc02009ac:	fb667ce3          	bgeu	a2,s6,ffffffffc0200964 <buddy_alloc_pages+0x54>
ffffffffc02009b0:	a205                	j	ffffffffc0200ad0 <buddy_alloc_pages+0x1c0>
    if (current_order > buddy_sys.max_order || buddy_sys.free_array[current_order].nr_free == 0) {
ffffffffc02009b2:	fcb668e3          	bltu	a2,a1,ffffffffc0200982 <buddy_alloc_pages+0x72>
    cprintf("buddy_alloc: found block at order %u (req order %u)\n", current_order, req_order);
ffffffffc02009b6:	865a                	mv	a2,s6
ffffffffc02009b8:	00001517          	auipc	a0,0x1
ffffffffc02009bc:	34050513          	addi	a0,a0,832 # ffffffffc0201cf8 <etext+0x602>
ffffffffc02009c0:	e42e                	sd	a1,8(sp)
ffffffffc02009c2:	f8aff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (current_order > req_order) {
ffffffffc02009c6:	65a2                	ld	a1,8(sp)
ffffffffc02009c8:	12bb7663          	bgeu	s6,a1,ffffffffc0200af4 <buddy_alloc_pages+0x1e4>
ffffffffc02009cc:	fff5849b          	addiw	s1,a1,-1
ffffffffc02009d0:	02049793          	slli	a5,s1,0x20
ffffffffc02009d4:	9381                	srli	a5,a5,0x20
ffffffffc02009d6:	00179493          	slli	s1,a5,0x1
ffffffffc02009da:	94be                	add	s1,s1,a5
ffffffffc02009dc:	048e                	slli	s1,s1,0x3
ffffffffc02009de:	0421                	addi	s0,s0,8
ffffffffc02009e0:	04a1                	addi	s1,s1,8
ffffffffc02009e2:	9456                	add	s0,s0,s5
ffffffffc02009e4:	94d6                	add	s1,s1,s5
        struct Page *buddy_block = alloc_block + half_pages;
ffffffffc02009e6:	02800a13          	li	s4,40
        cprintf("buddy_alloc: split order %u -> two order %u blocks\n", 
ffffffffc02009ea:	00001997          	auipc	s3,0x1
ffffffffc02009ee:	26e98993          	addi	s3,s3,622 # ffffffffc0201c58 <etext+0x562>
ffffffffc02009f2:	a895                	j	ffffffffc0200a66 <buddy_alloc_pages+0x156>
    __list_del(listelm->prev, listelm->next);
ffffffffc02009f4:	6390                	ld	a2,0(a5)
ffffffffc02009f6:	6794                	ld	a3,8(a5)
        buddy_sys.free_array[current_order].nr_free--;
ffffffffc02009f8:	4818                	lw	a4,16(s0)
        SET_PAGE_ORDER(alloc_block, current_order);
ffffffffc02009fa:	ff07b503          	ld	a0,-16(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02009fe:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0200a00:	e290                	sd	a2,0(a3)
        current_order--;
ffffffffc0200a02:	fff5891b          	addiw	s2,a1,-1
        buddy_sys.free_array[current_order].nr_free--;
ffffffffc0200a06:	377d                	addiw	a4,a4,-1
ffffffffc0200a08:	c818                	sw	a4,16(s0)
        alloc_block = le2page(le, page_link);
ffffffffc0200a0a:	fe878b93          	addi	s7,a5,-24
        SET_PAGE_ORDER(alloc_block, current_order);
ffffffffc0200a0e:	00256513          	ori	a0,a0,2
        struct Page *buddy_block = alloc_block + half_pages;
ffffffffc0200a12:	012a1733          	sll	a4,s4,s2
        SET_PAGE_ORDER(alloc_block, current_order);
ffffffffc0200a16:	fea7b823          	sd	a0,-16(a5)
        struct Page *buddy_block = alloc_block + half_pages;
ffffffffc0200a1a:	975e                	add	a4,a4,s7
        SET_PAGE_ORDER(buddy_block, current_order);
ffffffffc0200a1c:	6708                	ld	a0,8(a4)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a1e:	0084b803          	ld	a6,8(s1)
        SET_PAGE_ORDER(alloc_block, current_order);
ffffffffc0200a22:	ff27ac23          	sw	s2,-8(a5)
        SET_PAGE_ORDER(buddy_block, current_order);
ffffffffc0200a26:	00256513          	ori	a0,a0,2
ffffffffc0200a2a:	01272823          	sw	s2,16(a4)
ffffffffc0200a2e:	e708                	sd	a0,8(a4)
    prev->next = next->prev = elm;
ffffffffc0200a30:	00f83023          	sd	a5,0(a6)
ffffffffc0200a34:	e49c                	sd	a5,8(s1)
    elm->prev = prev;
ffffffffc0200a36:	e384                	sd	s1,0(a5)
    elm->next = next;
ffffffffc0200a38:	0107b423          	sd	a6,8(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200a3c:	6488                	ld	a0,8(s1)
        buddy_sys.free_array[current_order].nr_free += 2;
ffffffffc0200a3e:	489c                	lw	a5,16(s1)
        list_add(&buddy_sys.free_array[current_order].free_list, &(buddy_block->page_link));
ffffffffc0200a40:	01870813          	addi	a6,a4,24
    prev->next = next->prev = elm;
ffffffffc0200a44:	01053023          	sd	a6,0(a0)
ffffffffc0200a48:	0104b423          	sd	a6,8(s1)
    elm->prev = prev;
ffffffffc0200a4c:	ef04                	sd	s1,24(a4)
    elm->next = next;
ffffffffc0200a4e:	f308                	sd	a0,32(a4)
        buddy_sys.free_array[current_order].nr_free += 2;
ffffffffc0200a50:	2789                	addiw	a5,a5,2
ffffffffc0200a52:	c89c                	sw	a5,16(s1)
        current_order--;
ffffffffc0200a54:	864a                	mv	a2,s2
        cprintf("buddy_alloc: split order %u -> two order %u blocks\n", 
ffffffffc0200a56:	854e                	mv	a0,s3
    while (current_order > req_order) {
ffffffffc0200a58:	1421                	addi	s0,s0,-24
        cprintf("buddy_alloc: split order %u -> two order %u blocks\n", 
ffffffffc0200a5a:	ef2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (current_order > req_order) {
ffffffffc0200a5e:	14a1                	addi	s1,s1,-24
ffffffffc0200a60:	01690e63          	beq	s2,s6,ffffffffc0200a7c <buddy_alloc_pages+0x16c>
ffffffffc0200a64:	85ca                	mv	a1,s2
    return listelm->next;
ffffffffc0200a66:	641c                	ld	a5,8(s0)
        if (le == &buddy_sys.free_array[current_order].free_list) {
ffffffffc0200a68:	f88796e3          	bne	a5,s0,ffffffffc02009f4 <buddy_alloc_pages+0xe4>
            cprintf("buddy_alloc_pages: empty list at order %u\n", current_order);
ffffffffc0200a6c:	00001517          	auipc	a0,0x1
ffffffffc0200a70:	1bc50513          	addi	a0,a0,444 # ffffffffc0201c28 <etext+0x532>
ffffffffc0200a74:	ed8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            return NULL;
ffffffffc0200a78:	4b81                	li	s7,0
ffffffffc0200a7a:	bf21                	j	ffffffffc0200992 <buddy_alloc_pages+0x82>
ffffffffc0200a7c:	020b1693          	slli	a3,s6,0x20
ffffffffc0200a80:	9281                	srli	a3,a3,0x20
    buddy_sys.free_array[req_order].nr_free--;
ffffffffc0200a82:	00169793          	slli	a5,a3,0x1
ffffffffc0200a86:	97b6                	add	a5,a5,a3
ffffffffc0200a88:	078e                	slli	a5,a5,0x3
    __list_del(listelm->prev, listelm->next);
ffffffffc0200a8a:	020bb503          	ld	a0,32(s7)
ffffffffc0200a8e:	018bb803          	ld	a6,24(s7)
ffffffffc0200a92:	97d6                	add	a5,a5,s5
ffffffffc0200a94:	4f90                	lw	a2,24(a5)
    buddy_sys.nr_free_pages -= ORDER_TO_PAGES(req_order);
ffffffffc0200a96:	188aa683          	lw	a3,392(s5)
    ClearPageProperty(alloc_block);
ffffffffc0200a9a:	008bb703          	ld	a4,8(s7)
    buddy_sys.nr_free_pages -= ORDER_TO_PAGES(req_order);
ffffffffc0200a9e:	4585                	li	a1,1
    prev->next = next;
ffffffffc0200aa0:	00a83423          	sd	a0,8(a6)
ffffffffc0200aa4:	016595b3          	sll	a1,a1,s6
    next->prev = prev;
ffffffffc0200aa8:	01053023          	sd	a6,0(a0)
ffffffffc0200aac:	9e8d                	subw	a3,a3,a1
    buddy_sys.free_array[req_order].nr_free--;
ffffffffc0200aae:	367d                	addiw	a2,a2,-1
ffffffffc0200ab0:	cf90                	sw	a2,24(a5)
    buddy_sys.nr_free_pages -= ORDER_TO_PAGES(req_order);
ffffffffc0200ab2:	18daa423          	sw	a3,392(s5)
    ClearPageProperty(alloc_block);
ffffffffc0200ab6:	ffd77793          	andi	a5,a4,-3
ffffffffc0200aba:	00fbb423          	sd	a5,8(s7)
    cprintf("buddy_alloc: allocated %u pages (order %u) at 0x%08x\n", 
ffffffffc0200abe:	86de                	mv	a3,s7
ffffffffc0200ac0:	865a                	mv	a2,s6
ffffffffc0200ac2:	00001517          	auipc	a0,0x1
ffffffffc0200ac6:	1fe50513          	addi	a0,a0,510 # ffffffffc0201cc0 <etext+0x5ca>
ffffffffc0200aca:	e82ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    return alloc_block;
ffffffffc0200ace:	b5d1                	j	ffffffffc0200992 <buddy_alloc_pages+0x82>
        cprintf("buddy_alloc_pages: req order %u exceeds max %u\n", req_order, buddy_sys.max_order);
ffffffffc0200ad0:	85da                	mv	a1,s6
ffffffffc0200ad2:	00001517          	auipc	a0,0x1
ffffffffc0200ad6:	0ee50513          	addi	a0,a0,238 # ffffffffc0201bc0 <etext+0x4ca>
ffffffffc0200ada:	e72ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc0200ade:	4b81                	li	s7,0
ffffffffc0200ae0:	bd4d                	j	ffffffffc0200992 <buddy_alloc_pages+0x82>
        cprintf("buddy_alloc_pages: not enough memory (req %u, free %u)\n", n, buddy_sys.nr_free_pages);
ffffffffc0200ae2:	85aa                	mv	a1,a0
ffffffffc0200ae4:	00001517          	auipc	a0,0x1
ffffffffc0200ae8:	0a450513          	addi	a0,a0,164 # ffffffffc0201b88 <etext+0x492>
ffffffffc0200aec:	e60ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return NULL;
ffffffffc0200af0:	4b81                	li	s7,0
ffffffffc0200af2:	b545                	j	ffffffffc0200992 <buddy_alloc_pages+0x82>
    return listelm->next;
ffffffffc0200af4:	020b1693          	slli	a3,s6,0x20
ffffffffc0200af8:	9281                	srli	a3,a3,0x20
ffffffffc0200afa:	00169713          	slli	a4,a3,0x1
ffffffffc0200afe:	9736                	add	a4,a4,a3
ffffffffc0200b00:	070e                	slli	a4,a4,0x3
ffffffffc0200b02:	00ea87b3          	add	a5,s5,a4
ffffffffc0200b06:	6b9c                	ld	a5,16(a5)
        if (le == &buddy_sys.free_array[req_order].free_list) {
ffffffffc0200b08:	0721                	addi	a4,a4,8
ffffffffc0200b0a:	9756                	add	a4,a4,s5
        alloc_block = le2page(le, page_link);
ffffffffc0200b0c:	fe878b93          	addi	s7,a5,-24
        if (le == &buddy_sys.free_array[req_order].free_list) {
ffffffffc0200b10:	f6e799e3          	bne	a5,a4,ffffffffc0200a82 <buddy_alloc_pages+0x172>
            cprintf("buddy_alloc_pages: no block at req order %u\n", req_order);
ffffffffc0200b14:	85da                	mv	a1,s6
ffffffffc0200b16:	00001517          	auipc	a0,0x1
ffffffffc0200b1a:	17a50513          	addi	a0,a0,378 # ffffffffc0201c90 <etext+0x59a>
ffffffffc0200b1e:	e2eff0ef          	jal	ra,ffffffffc020014c <cprintf>
            return NULL;
ffffffffc0200b22:	4b81                	li	s7,0
ffffffffc0200b24:	b5bd                	j	ffffffffc0200992 <buddy_alloc_pages+0x82>
    assert(n > 0);
ffffffffc0200b26:	00001697          	auipc	a3,0x1
ffffffffc0200b2a:	f6a68693          	addi	a3,a3,-150 # ffffffffc0201a90 <etext+0x39a>
ffffffffc0200b2e:	00001617          	auipc	a2,0x1
ffffffffc0200b32:	f6a60613          	addi	a2,a2,-150 # ffffffffc0201a98 <etext+0x3a2>
ffffffffc0200b36:	09300593          	li	a1,147
ffffffffc0200b3a:	00001517          	auipc	a0,0x1
ffffffffc0200b3e:	f7650513          	addi	a0,a0,-138 # ffffffffc0201ab0 <etext+0x3ba>
ffffffffc0200b42:	e80ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200b46 <buddy_pmm_alloc_pages>:
}

static struct Page *buddy_pmm_alloc_pages(size_t n) {
    return buddy_alloc_pages(n);
ffffffffc0200b46:	b3e9                	j	ffffffffc0200910 <buddy_alloc_pages>

ffffffffc0200b48 <buddy_free_pages>:
void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200b48:	715d                	addi	sp,sp,-80
ffffffffc0200b4a:	e486                	sd	ra,72(sp)
ffffffffc0200b4c:	e0a2                	sd	s0,64(sp)
ffffffffc0200b4e:	fc26                	sd	s1,56(sp)
ffffffffc0200b50:	f84a                	sd	s2,48(sp)
ffffffffc0200b52:	f44e                	sd	s3,40(sp)
ffffffffc0200b54:	f052                	sd	s4,32(sp)
ffffffffc0200b56:	ec56                	sd	s5,24(sp)
ffffffffc0200b58:	e85a                	sd	s6,16(sp)
ffffffffc0200b5a:	e45e                	sd	s7,8(sp)
    assert(n > 0);
ffffffffc0200b5c:	16058363          	beqz	a1,ffffffffc0200cc2 <buddy_free_pages+0x17a>
ffffffffc0200b60:	842a                	mv	s0,a0
    assert(base != NULL);
ffffffffc0200b62:	1a050063          	beqz	a0,ffffffffc0200d02 <buddy_free_pages+0x1ba>
    assert(PageReserved(base));
ffffffffc0200b66:	6514                	ld	a3,8(a0)
ffffffffc0200b68:	0016f793          	andi	a5,a3,1
ffffffffc0200b6c:	16078b63          	beqz	a5,ffffffffc0200ce2 <buddy_free_pages+0x19a>
    while (current_size < size) {
ffffffffc0200b70:	4605                	li	a2,1
ffffffffc0200b72:	8bae                	mv	s7,a1
    unsigned int order = 0;
ffffffffc0200b74:	4701                	li	a4,0
    while (current_size < size) {
ffffffffc0200b76:	4a01                	li	s4,0
ffffffffc0200b78:	00c58f63          	beq	a1,a2,ffffffffc0200b96 <buddy_free_pages+0x4e>
        current_size <<= 1;
ffffffffc0200b7c:	0786                	slli	a5,a5,0x1
        order++;
ffffffffc0200b7e:	2705                	addiw	a4,a4,1
    while (current_size < size) {
ffffffffc0200b80:	ff77eee3          	bltu	a5,s7,ffffffffc0200b7c <buddy_free_pages+0x34>
    return (order > BUDDY_MAX_ORDER) ? BUDDY_MAX_ORDER : order;
ffffffffc0200b84:	47bd                	li	a5,15
ffffffffc0200b86:	85ba                	mv	a1,a4
ffffffffc0200b88:	12e7e663          	bltu	a5,a4,ffffffffc0200cb4 <buddy_free_pages+0x16c>
    cprintf("buddy_free: freeing %u pages (order %u) at 0x%08x\n", 
ffffffffc0200b8c:	4b85                	li	s7,1
    return (order > BUDDY_MAX_ORDER) ? BUDDY_MAX_ORDER : order;
ffffffffc0200b8e:	00058a1b          	sext.w	s4,a1
    cprintf("buddy_free: freeing %u pages (order %u) at 0x%08x\n", 
ffffffffc0200b92:	00bb9bb3          	sll	s7,s7,a1
    SET_PAGE_ORDER(free_block, order);
ffffffffc0200b96:	0026e693          	ori	a3,a3,2
ffffffffc0200b9a:	e414                	sd	a3,8(s0)
ffffffffc0200b9c:	01442823          	sw	s4,16(s0)
    cprintf("buddy_free: freeing %u pages (order %u) at 0x%08x\n", 
ffffffffc0200ba0:	86a2                	mv	a3,s0
ffffffffc0200ba2:	8652                	mv	a2,s4
ffffffffc0200ba4:	85de                	mv	a1,s7
ffffffffc0200ba6:	00001517          	auipc	a0,0x1
ffffffffc0200baa:	1a250513          	addi	a0,a0,418 # ffffffffc0201d48 <etext+0x652>
    while (order < buddy_sys.max_order) {
ffffffffc0200bae:	00005a97          	auipc	s5,0x5
ffffffffc0200bb2:	46aa8a93          	addi	s5,s5,1130 # ffffffffc0206018 <buddy_sys>
    cprintf("buddy_free: freeing %u pages (order %u) at 0x%08x\n", 
ffffffffc0200bb6:	d96ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (order < buddy_sys.max_order) {
ffffffffc0200bba:	000aa783          	lw	a5,0(s5)
ffffffffc0200bbe:	0afa7463          	bgeu	s4,a5,ffffffffc0200c66 <buddy_free_pages+0x11e>
ffffffffc0200bc2:	00002997          	auipc	s3,0x2
ffffffffc0200bc6:	97e9b983          	ld	s3,-1666(s3) # ffffffffc0202540 <error_string+0x38>
    size_t block_size = ORDER_TO_PAGES(order);
ffffffffc0200bca:	4905                	li	s2,1
        cprintf("buddy_free: merged order %u -> order %u at 0x%08x\n", 
ffffffffc0200bcc:	00001497          	auipc	s1,0x1
ffffffffc0200bd0:	1b448493          	addi	s1,s1,436 # ffffffffc0201d80 <etext+0x68a>
ffffffffc0200bd4:	a895                	j	ffffffffc0200c48 <buddy_free_pages+0x100>
    struct Page *buddy = buddy_sys.base_page + buddy_index;
ffffffffc0200bd6:	00271693          	slli	a3,a4,0x2
ffffffffc0200bda:	9736                	add	a4,a4,a3
ffffffffc0200bdc:	070e                	slli	a4,a4,0x3
ffffffffc0200bde:	97ba                	add	a5,a5,a4
        if (buddy == NULL || !PageProperty(buddy) || 
ffffffffc0200be0:	c3d9                	beqz	a5,ffffffffc0200c66 <buddy_free_pages+0x11e>
ffffffffc0200be2:	6794                	ld	a3,8(a5)
ffffffffc0200be4:	0026f713          	andi	a4,a3,2
ffffffffc0200be8:	cf3d                	beqz	a4,ffffffffc0200c66 <buddy_free_pages+0x11e>
ffffffffc0200bea:	4b98                	lw	a4,16(a5)
ffffffffc0200bec:	07471d63          	bne	a4,s4,ffffffffc0200c66 <buddy_free_pages+0x11e>
        buddy_sys.free_array[order].nr_free--;
ffffffffc0200bf0:	020a1613          	slli	a2,s4,0x20
ffffffffc0200bf4:	9201                	srli	a2,a2,0x20
ffffffffc0200bf6:	00161713          	slli	a4,a2,0x1
ffffffffc0200bfa:	9732                	add	a4,a4,a2
ffffffffc0200bfc:	070e                	slli	a4,a4,0x3
    __list_del(listelm->prev, listelm->next);
ffffffffc0200bfe:	6f88                	ld	a0,24(a5)
ffffffffc0200c00:	738c                	ld	a1,32(a5)
ffffffffc0200c02:	9756                	add	a4,a4,s5
ffffffffc0200c04:	4f10                	lw	a2,24(a4)
    prev->next = next;
ffffffffc0200c06:	e50c                	sd	a1,8(a0)
    next->prev = prev;
ffffffffc0200c08:	e188                	sd	a0,0(a1)
ffffffffc0200c0a:	367d                	addiw	a2,a2,-1
ffffffffc0200c0c:	cf10                	sw	a2,24(a4)
        if (free_block > buddy) {
ffffffffc0200c0e:	0087f663          	bgeu	a5,s0,ffffffffc0200c1a <buddy_free_pages+0xd2>
        ClearPageProperty(buddy);
ffffffffc0200c12:	8722                	mv	a4,s0
ffffffffc0200c14:	6414                	ld	a3,8(s0)
ffffffffc0200c16:	843e                	mv	s0,a5
ffffffffc0200c18:	87ba                	mv	a5,a4
ffffffffc0200c1a:	9af5                	andi	a3,a3,-3
ffffffffc0200c1c:	e794                	sd	a3,8(a5)
        SET_PAGE_ORDER(free_block, order);
ffffffffc0200c1e:	6418                	ld	a4,8(s0)
        order++;
ffffffffc0200c20:	001a0b1b          	addiw	s6,s4,1
        buddy->property = 0;
ffffffffc0200c24:	0007a823          	sw	zero,16(a5)
        SET_PAGE_ORDER(free_block, order);
ffffffffc0200c28:	00276793          	ori	a5,a4,2
ffffffffc0200c2c:	e41c                	sd	a5,8(s0)
ffffffffc0200c2e:	01642823          	sw	s6,16(s0)
        cprintf("buddy_free: merged order %u -> order %u at 0x%08x\n", 
ffffffffc0200c32:	86a2                	mv	a3,s0
ffffffffc0200c34:	865a                	mv	a2,s6
ffffffffc0200c36:	85d2                	mv	a1,s4
ffffffffc0200c38:	8526                	mv	a0,s1
ffffffffc0200c3a:	d12ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    while (order < buddy_sys.max_order) {
ffffffffc0200c3e:	000aa783          	lw	a5,0(s5)
ffffffffc0200c42:	06fb7b63          	bgeu	s6,a5,ffffffffc0200cb8 <buddy_free_pages+0x170>
ffffffffc0200c46:	8a5a                	mv	s4,s6
    size_t page_index = page - buddy_sys.base_page;
ffffffffc0200c48:	190ab783          	ld	a5,400(s5)
    if (buddy_index >= buddy_sys.total_pages) {
ffffffffc0200c4c:	198ab683          	ld	a3,408(s5)
    size_t block_size = ORDER_TO_PAGES(order);
ffffffffc0200c50:	01491bb3          	sll	s7,s2,s4
    size_t page_index = page - buddy_sys.base_page;
ffffffffc0200c54:	40f40733          	sub	a4,s0,a5
ffffffffc0200c58:	870d                	srai	a4,a4,0x3
ffffffffc0200c5a:	03370733          	mul	a4,a4,s3
    size_t buddy_index = page_index ^ block_size;  
ffffffffc0200c5e:	01774733          	xor	a4,a4,s7
    if (buddy_index >= buddy_sys.total_pages) {
ffffffffc0200c62:	f6d76ae3          	bltu	a4,a3,ffffffffc0200bd6 <buddy_free_pages+0x8e>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200c66:	1a02                	slli	s4,s4,0x20
ffffffffc0200c68:	020a5a13          	srli	s4,s4,0x20
ffffffffc0200c6c:	001a1793          	slli	a5,s4,0x1
ffffffffc0200c70:	9a3e                	add	s4,s4,a5
ffffffffc0200c72:	0a0e                	slli	s4,s4,0x3
ffffffffc0200c74:	014a87b3          	add	a5,s5,s4
ffffffffc0200c78:	6b90                	ld	a2,16(a5)
    list_add(&buddy_sys.free_array[order].free_list, &(free_block->page_link));
ffffffffc0200c7a:	01840593          	addi	a1,s0,24
    buddy_sys.nr_free_pages += ORDER_TO_PAGES(order);
ffffffffc0200c7e:	188aa703          	lw	a4,392(s5)
    buddy_sys.free_array[order].nr_free++;
ffffffffc0200c82:	4f94                	lw	a3,24(a5)
    list_add(&buddy_sys.free_array[order].free_list, &(free_block->page_link));
ffffffffc0200c84:	0a21                	addi	s4,s4,8
    prev->next = next->prev = elm;
ffffffffc0200c86:	e20c                	sd	a1,0(a2)
ffffffffc0200c88:	eb8c                	sd	a1,16(a5)
ffffffffc0200c8a:	9a56                	add	s4,s4,s5
    elm->prev = prev;
ffffffffc0200c8c:	01443c23          	sd	s4,24(s0)
    elm->next = next;
ffffffffc0200c90:	f010                	sd	a2,32(s0)
}
ffffffffc0200c92:	60a6                	ld	ra,72(sp)
ffffffffc0200c94:	6406                	ld	s0,64(sp)
    buddy_sys.nr_free_pages += ORDER_TO_PAGES(order);
ffffffffc0200c96:	0177073b          	addw	a4,a4,s7
    buddy_sys.free_array[order].nr_free++;
ffffffffc0200c9a:	2685                	addiw	a3,a3,1
    buddy_sys.nr_free_pages += ORDER_TO_PAGES(order);
ffffffffc0200c9c:	18eaa423          	sw	a4,392(s5)
    buddy_sys.free_array[order].nr_free++;
ffffffffc0200ca0:	cf94                	sw	a3,24(a5)
}
ffffffffc0200ca2:	74e2                	ld	s1,56(sp)
ffffffffc0200ca4:	7942                	ld	s2,48(sp)
ffffffffc0200ca6:	79a2                	ld	s3,40(sp)
ffffffffc0200ca8:	7a02                	ld	s4,32(sp)
ffffffffc0200caa:	6ae2                	ld	s5,24(sp)
ffffffffc0200cac:	6b42                	ld	s6,16(sp)
ffffffffc0200cae:	6ba2                	ld	s7,8(sp)
ffffffffc0200cb0:	6161                	addi	sp,sp,80
ffffffffc0200cb2:	8082                	ret
    return (order > BUDDY_MAX_ORDER) ? BUDDY_MAX_ORDER : order;
ffffffffc0200cb4:	45bd                	li	a1,15
ffffffffc0200cb6:	bdd9                	j	ffffffffc0200b8c <buddy_free_pages+0x44>
    buddy_sys.nr_free_pages += ORDER_TO_PAGES(order);
ffffffffc0200cb8:	4b85                	li	s7,1
ffffffffc0200cba:	016b9bb3          	sll	s7,s7,s6
        order++;
ffffffffc0200cbe:	8a5a                	mv	s4,s6
ffffffffc0200cc0:	b75d                	j	ffffffffc0200c66 <buddy_free_pages+0x11e>
    assert(n > 0);
ffffffffc0200cc2:	00001697          	auipc	a3,0x1
ffffffffc0200cc6:	dce68693          	addi	a3,a3,-562 # ffffffffc0201a90 <etext+0x39a>
ffffffffc0200cca:	00001617          	auipc	a2,0x1
ffffffffc0200cce:	dce60613          	addi	a2,a2,-562 # ffffffffc0201a98 <etext+0x3a2>
ffffffffc0200cd2:	0e400593          	li	a1,228
ffffffffc0200cd6:	00001517          	auipc	a0,0x1
ffffffffc0200cda:	dda50513          	addi	a0,a0,-550 # ffffffffc0201ab0 <etext+0x3ba>
ffffffffc0200cde:	ce4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(PageReserved(base));
ffffffffc0200ce2:	00001697          	auipc	a3,0x1
ffffffffc0200ce6:	04e68693          	addi	a3,a3,78 # ffffffffc0201d30 <etext+0x63a>
ffffffffc0200cea:	00001617          	auipc	a2,0x1
ffffffffc0200cee:	dae60613          	addi	a2,a2,-594 # ffffffffc0201a98 <etext+0x3a2>
ffffffffc0200cf2:	0e600593          	li	a1,230
ffffffffc0200cf6:	00001517          	auipc	a0,0x1
ffffffffc0200cfa:	dba50513          	addi	a0,a0,-582 # ffffffffc0201ab0 <etext+0x3ba>
ffffffffc0200cfe:	cc4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
    assert(base != NULL);
ffffffffc0200d02:	00001697          	auipc	a3,0x1
ffffffffc0200d06:	dbe68693          	addi	a3,a3,-578 # ffffffffc0201ac0 <etext+0x3ca>
ffffffffc0200d0a:	00001617          	auipc	a2,0x1
ffffffffc0200d0e:	d8e60613          	addi	a2,a2,-626 # ffffffffc0201a98 <etext+0x3a2>
ffffffffc0200d12:	0e500593          	li	a1,229
ffffffffc0200d16:	00001517          	auipc	a0,0x1
ffffffffc0200d1a:	d9a50513          	addi	a0,a0,-614 # ffffffffc0201ab0 <etext+0x3ba>
ffffffffc0200d1e:	ca4ff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0200d22 <buddy_pmm_free_pages>:
}

static void buddy_pmm_free_pages(struct Page *base, size_t n) {
    buddy_free_pages(base, n);
ffffffffc0200d22:	b51d                	j	ffffffffc0200b48 <buddy_free_pages>

ffffffffc0200d24 <buddy_system_check>:
void buddy_system_check(void) {
ffffffffc0200d24:	7171                	addi	sp,sp,-176
    cprintf("\n=== Buddy System Comprehensive Test ===\n");
ffffffffc0200d26:	00001517          	auipc	a0,0x1
ffffffffc0200d2a:	0ba50513          	addi	a0,a0,186 # ffffffffc0201de0 <etext+0x6ea>
void buddy_system_check(void) {
ffffffffc0200d2e:	e94a                	sd	s2,144(sp)
ffffffffc0200d30:	f506                	sd	ra,168(sp)
ffffffffc0200d32:	f122                	sd	s0,160(sp)
ffffffffc0200d34:	ed26                	sd	s1,152(sp)
ffffffffc0200d36:	e54e                	sd	s3,136(sp)
ffffffffc0200d38:	e152                	sd	s4,128(sp)
ffffffffc0200d3a:	fcd6                	sd	s5,120(sp)
ffffffffc0200d3c:	f8da                	sd	s6,112(sp)
ffffffffc0200d3e:	f4de                	sd	s7,104(sp)
ffffffffc0200d40:	f0e2                	sd	s8,96(sp)
    show_buddy_array(0, buddy_sys.max_order);
ffffffffc0200d42:	00005917          	auipc	s2,0x5
ffffffffc0200d46:	2d690913          	addi	s2,s2,726 # ffffffffc0206018 <buddy_sys>
    cprintf("\n=== Buddy System Comprehensive Test ===\n");
ffffffffc0200d4a:	c02ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    show_buddy_array(0, buddy_sys.max_order);
ffffffffc0200d4e:	00092583          	lw	a1,0(s2)
    if (start_order > end_order || end_order > BUDDY_MAX_ORDER) {
ffffffffc0200d52:	47bd                	li	a5,15
ffffffffc0200d54:	0eb7f563          	bgeu	a5,a1,ffffffffc0200e3e <buddy_system_check+0x11a>
        cprintf("show_buddy_array: invalid order range\n");
ffffffffc0200d58:	00001517          	auipc	a0,0x1
ffffffffc0200d5c:	06050513          	addi	a0,a0,96 # ffffffffc0201db8 <etext+0x6c2>
ffffffffc0200d60:	becff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("Test 1: Basic allocation and free\n");
ffffffffc0200d64:	00001517          	auipc	a0,0x1
ffffffffc0200d68:	0ac50513          	addi	a0,a0,172 # ffffffffc0201e10 <etext+0x71a>
ffffffffc0200d6c:	be0ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *p1 = buddy_alloc_pages(1);
ffffffffc0200d70:	4505                	li	a0,1
ffffffffc0200d72:	b9fff0ef          	jal	ra,ffffffffc0200910 <buddy_alloc_pages>
    assert(p1 != NULL);
ffffffffc0200d76:	2c050963          	beqz	a0,ffffffffc0201048 <buddy_system_check+0x324>
    buddy_free_pages(p1, 1);
ffffffffc0200d7a:	4585                	li	a1,1
ffffffffc0200d7c:	dcdff0ef          	jal	ra,ffffffffc0200b48 <buddy_free_pages>
    cprintf("Test 1 PASSED\n");
ffffffffc0200d80:	00001517          	auipc	a0,0x1
ffffffffc0200d84:	0c850513          	addi	a0,a0,200 # ffffffffc0201e48 <etext+0x752>
ffffffffc0200d88:	bc4ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("\nTest 2: Block split test\n");
ffffffffc0200d8c:	00001517          	auipc	a0,0x1
ffffffffc0200d90:	0cc50513          	addi	a0,a0,204 # ffffffffc0201e58 <etext+0x762>
ffffffffc0200d94:	bb8ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *large = buddy_alloc_pages(4);  
ffffffffc0200d98:	4511                	li	a0,4
ffffffffc0200d9a:	b77ff0ef          	jal	ra,ffffffffc0200910 <buddy_alloc_pages>
    if (large == NULL) {
ffffffffc0200d9e:	24050963          	beqz	a0,ffffffffc0200ff0 <buddy_system_check+0x2cc>
        buddy_free_pages(large, 4);
ffffffffc0200da2:	4591                	li	a1,4
ffffffffc0200da4:	da5ff0ef          	jal	ra,ffffffffc0200b48 <buddy_free_pages>
        cprintf("Test 2 PASSED\n");
ffffffffc0200da8:	00001517          	auipc	a0,0x1
ffffffffc0200dac:	11850513          	addi	a0,a0,280 # ffffffffc0201ec0 <etext+0x7ca>
ffffffffc0200db0:	b9cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("\nTest 3: Buddy merge test\n");
ffffffffc0200db4:	00001517          	auipc	a0,0x1
ffffffffc0200db8:	11c50513          	addi	a0,a0,284 # ffffffffc0201ed0 <etext+0x7da>
ffffffffc0200dbc:	b90ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    struct Page *a1 = buddy_alloc_pages(2);
ffffffffc0200dc0:	4509                	li	a0,2
ffffffffc0200dc2:	b4fff0ef          	jal	ra,ffffffffc0200910 <buddy_alloc_pages>
ffffffffc0200dc6:	842a                	mv	s0,a0
    struct Page *a2 = buddy_alloc_pages(2);
ffffffffc0200dc8:	4509                	li	a0,2
ffffffffc0200dca:	b47ff0ef          	jal	ra,ffffffffc0200910 <buddy_alloc_pages>
ffffffffc0200dce:	84aa                	mv	s1,a0
    if (a1 != NULL && a2 != NULL) {
ffffffffc0200dd0:	c83d                	beqz	s0,ffffffffc0200e46 <buddy_system_check+0x122>
ffffffffc0200dd2:	c935                	beqz	a0,ffffffffc0200e46 <buddy_system_check+0x122>
    if (page == NULL || order > buddy_sys.max_order) {
ffffffffc0200dd4:	00092783          	lw	a5,0(s2)
ffffffffc0200dd8:	c3b9                	beqz	a5,ffffffffc0200e1e <buddy_system_check+0xfa>
    size_t page_index = page - buddy_sys.base_page;
ffffffffc0200dda:	19093603          	ld	a2,400(s2)
ffffffffc0200dde:	00001697          	auipc	a3,0x1
ffffffffc0200de2:	7626b683          	ld	a3,1890(a3) # ffffffffc0202540 <error_string+0x38>
    if (buddy_index >= buddy_sys.total_pages) {
ffffffffc0200de6:	19893583          	ld	a1,408(s2)
    size_t page_index = page - buddy_sys.base_page;
ffffffffc0200dea:	40c407b3          	sub	a5,s0,a2
ffffffffc0200dee:	878d                	srai	a5,a5,0x3
ffffffffc0200df0:	02d787b3          	mul	a5,a5,a3
    size_t buddy_index = page_index ^ block_size;  
ffffffffc0200df4:	0027c793          	xori	a5,a5,2
    if (buddy_index >= buddy_sys.total_pages) {
ffffffffc0200df8:	02b7f363          	bgeu	a5,a1,ffffffffc0200e1e <buddy_system_check+0xfa>
    size_t page_index = page - buddy_sys.base_page;
ffffffffc0200dfc:	40c50733          	sub	a4,a0,a2
ffffffffc0200e00:	870d                	srai	a4,a4,0x3
ffffffffc0200e02:	02d70733          	mul	a4,a4,a3
    struct Page *buddy = buddy_sys.base_page + buddy_index;
ffffffffc0200e06:	00279693          	slli	a3,a5,0x2
ffffffffc0200e0a:	97b6                	add	a5,a5,a3
ffffffffc0200e0c:	078e                	slli	a5,a5,0x3
ffffffffc0200e0e:	00f606b3          	add	a3,a2,a5
    size_t buddy_index = page_index ^ block_size;  
ffffffffc0200e12:	00274793          	xori	a5,a4,2
    if (buddy_index >= buddy_sys.total_pages) {
ffffffffc0200e16:	00b7f463          	bgeu	a5,a1,ffffffffc0200e1e <buddy_system_check+0xfa>
    return (buddy1 == block2) && (buddy2 == block1);
ffffffffc0200e1a:	20d50163          	beq	a0,a3,ffffffffc020101c <buddy_system_check+0x2f8>
        assert(is_buddy_blocks(a1, a2, 1));  
ffffffffc0200e1e:	00001697          	auipc	a3,0x1
ffffffffc0200e22:	0e268693          	addi	a3,a3,226 # ffffffffc0201f00 <etext+0x80a>
ffffffffc0200e26:	00001617          	auipc	a2,0x1
ffffffffc0200e2a:	c7260613          	addi	a2,a2,-910 # ffffffffc0201a98 <etext+0x3a2>
ffffffffc0200e2e:	17800593          	li	a1,376
ffffffffc0200e32:	00001517          	auipc	a0,0x1
ffffffffc0200e36:	c7e50513          	addi	a0,a0,-898 # ffffffffc0201ab0 <etext+0x3ba>
ffffffffc0200e3a:	b88ff0ef          	jal	ra,ffffffffc02001c2 <__panic>
ffffffffc0200e3e:	4501                	li	a0,0
ffffffffc0200e40:	f90ff0ef          	jal	ra,ffffffffc02005d0 <show_buddy_array.part.0>
ffffffffc0200e44:	b705                	j	ffffffffc0200d64 <buddy_system_check+0x40>
        cprintf("Test 3 SKIPPED: Cannot allocate buddy blocks\n");
ffffffffc0200e46:	00001517          	auipc	a0,0x1
ffffffffc0200e4a:	0da50513          	addi	a0,a0,218 # ffffffffc0201f20 <etext+0x82a>
ffffffffc0200e4e:	afeff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("\nTest 4: Partial exhaustion test\n");
ffffffffc0200e52:	00001517          	auipc	a0,0x1
ffffffffc0200e56:	0fe50513          	addi	a0,a0,254 # ffffffffc0201f50 <etext+0x85a>
ffffffffc0200e5a:	af2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t free_pages = buddy_sys.nr_free_pages;
ffffffffc0200e5e:	18896583          	lwu	a1,392(s2)
    if (free_pages > 100) {
ffffffffc0200e62:	06400793          	li	a5,100
ffffffffc0200e66:	16b7fe63          	bgeu	a5,a1,ffffffffc0200fe2 <buddy_system_check+0x2be>
        struct Page *exhaust = buddy_alloc_pages(free_pages / 2);  
ffffffffc0200e6a:	0015d413          	srli	s0,a1,0x1
ffffffffc0200e6e:	8522                	mv	a0,s0
ffffffffc0200e70:	aa1ff0ef          	jal	ra,ffffffffc0200910 <buddy_alloc_pages>
        assert(exhaust != NULL);
ffffffffc0200e74:	1e050a63          	beqz	a0,ffffffffc0201068 <buddy_system_check+0x344>
        buddy_free_pages(exhaust, free_pages / 2);
ffffffffc0200e78:	85a2                	mv	a1,s0
ffffffffc0200e7a:	ccfff0ef          	jal	ra,ffffffffc0200b48 <buddy_free_pages>
        cprintf("Test 4 PASSED\n");
ffffffffc0200e7e:	00001517          	auipc	a0,0x1
ffffffffc0200e82:	10a50513          	addi	a0,a0,266 # ffffffffc0201f88 <etext+0x892>
ffffffffc0200e86:	ac6ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    cprintf("\nTest 5: Interleaved Allocation/Free Test\n");
ffffffffc0200e8a:	00001517          	auipc	a0,0x1
ffffffffc0200e8e:	13650513          	addi	a0,a0,310 # ffffffffc0201fc0 <etext+0x8ca>
ffffffffc0200e92:	abaff0ef          	jal	ra,ffffffffc020014c <cprintf>
    size_t sizes[] = {1, 2, 4, 8, 2, 1};
ffffffffc0200e96:	00001797          	auipc	a5,0x1
ffffffffc0200e9a:	2b278793          	addi	a5,a5,690 # ffffffffc0202148 <etext+0xa52>
ffffffffc0200e9e:	0007b803          	ld	a6,0(a5)
ffffffffc0200ea2:	678c                	ld	a1,8(a5)
ffffffffc0200ea4:	6b90                	ld	a2,16(a5)
ffffffffc0200ea6:	6f94                	ld	a3,24(a5)
ffffffffc0200ea8:	7398                	ld	a4,32(a5)
ffffffffc0200eaa:	779c                	ld	a5,40(a5)
    cprintf("Phase 1: Allocating mixed sizes...\n");
ffffffffc0200eac:	00001517          	auipc	a0,0x1
ffffffffc0200eb0:	14450513          	addi	a0,a0,324 # ffffffffc0201ff0 <etext+0x8fa>
ffffffffc0200eb4:	03010913          	addi	s2,sp,48
ffffffffc0200eb8:	840a                	mv	s0,sp
    size_t sizes[] = {1, 2, 4, 8, 2, 1};
ffffffffc0200eba:	f842                	sd	a6,48(sp)
ffffffffc0200ebc:	fc2e                	sd	a1,56(sp)
ffffffffc0200ebe:	e0b2                	sd	a2,64(sp)
ffffffffc0200ec0:	e4b6                	sd	a3,72(sp)
ffffffffc0200ec2:	e8ba                	sd	a4,80(sp)
ffffffffc0200ec4:	ecbe                	sd	a5,88(sp)
    cprintf("Phase 1: Allocating mixed sizes...\n");
ffffffffc0200ec6:	8a22                	mv	s4,s0
ffffffffc0200ec8:	a84ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200ecc:	89ca                	mv	s3,s2
    for (int i = 0; i < 6; i++) {
ffffffffc0200ece:	4481                	li	s1,0
        cprintf("  Allocated %2u pages at 0x%08x\n", sizes[i], blocks[i]);
ffffffffc0200ed0:	00001b97          	auipc	s7,0x1
ffffffffc0200ed4:	178b8b93          	addi	s7,s7,376 # ffffffffc0202048 <etext+0x952>
            cprintf("  Failed to allocate %u pages at step %d\n", sizes[i], i);
ffffffffc0200ed8:	00001c17          	auipc	s8,0x1
ffffffffc0200edc:	140c0c13          	addi	s8,s8,320 # ffffffffc0202018 <etext+0x922>
    for (int i = 0; i < 6; i++) {
ffffffffc0200ee0:	4b19                	li	s6,6
ffffffffc0200ee2:	a811                	j	ffffffffc0200ef6 <buddy_system_check+0x1d2>
        cprintf("  Allocated %2u pages at 0x%08x\n", sizes[i], blocks[i]);
ffffffffc0200ee4:	85d6                	mv	a1,s5
ffffffffc0200ee6:	855e                	mv	a0,s7
    for (int i = 0; i < 6; i++) {
ffffffffc0200ee8:	2485                	addiw	s1,s1,1
        cprintf("  Allocated %2u pages at 0x%08x\n", sizes[i], blocks[i]);
ffffffffc0200eea:	a62ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 6; i++) {
ffffffffc0200eee:	09a1                	addi	s3,s3,8
ffffffffc0200ef0:	0a21                	addi	s4,s4,8
ffffffffc0200ef2:	03648563          	beq	s1,s6,ffffffffc0200f1c <buddy_system_check+0x1f8>
        blocks[i] = buddy_alloc_pages(sizes[i]);
ffffffffc0200ef6:	0009ba83          	ld	s5,0(s3)
ffffffffc0200efa:	8556                	mv	a0,s5
ffffffffc0200efc:	a15ff0ef          	jal	ra,ffffffffc0200910 <buddy_alloc_pages>
ffffffffc0200f00:	00aa3023          	sd	a0,0(s4)
ffffffffc0200f04:	862a                	mv	a2,a0
        if (blocks[i] == NULL) {
ffffffffc0200f06:	fd79                	bnez	a0,ffffffffc0200ee4 <buddy_system_check+0x1c0>
            cprintf("  Failed to allocate %u pages at step %d\n", sizes[i], i);
ffffffffc0200f08:	8626                	mv	a2,s1
ffffffffc0200f0a:	85d6                	mv	a1,s5
ffffffffc0200f0c:	8562                	mv	a0,s8
    for (int i = 0; i < 6; i++) {
ffffffffc0200f0e:	2485                	addiw	s1,s1,1
            cprintf("  Failed to allocate %u pages at step %d\n", sizes[i], i);
ffffffffc0200f10:	a3cff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 0; i < 6; i++) {
ffffffffc0200f14:	09a1                	addi	s3,s3,8
ffffffffc0200f16:	0a21                	addi	s4,s4,8
ffffffffc0200f18:	fd649fe3          	bne	s1,s6,ffffffffc0200ef6 <buddy_system_check+0x1d2>
    cprintf("Phase 2: Interleaved freeing...\n");
ffffffffc0200f1c:	00001517          	auipc	a0,0x1
ffffffffc0200f20:	15450513          	addi	a0,a0,340 # ffffffffc0202070 <etext+0x97a>
ffffffffc0200f24:	a28ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    for (int i = 1; i < 6; i += 2) {
ffffffffc0200f28:	03040993          	addi	s3,s0,48
    cprintf("Phase 2: Interleaved freeing...\n");
ffffffffc0200f2c:	8aca                	mv	s5,s2
ffffffffc0200f2e:	84a2                	mv	s1,s0
            cprintf("  Freeing %2u pages at 0x%08x\n", sizes[i], blocks[i]);
ffffffffc0200f30:	00001b97          	auipc	s7,0x1
ffffffffc0200f34:	168b8b93          	addi	s7,s7,360 # ffffffffc0202098 <etext+0x9a2>
        if (blocks[i] != NULL) {
ffffffffc0200f38:	0084ba03          	ld	s4,8(s1)
ffffffffc0200f3c:	000a0f63          	beqz	s4,ffffffffc0200f5a <buddy_system_check+0x236>
            cprintf("  Freeing %2u pages at 0x%08x\n", sizes[i], blocks[i]);
ffffffffc0200f40:	008abb03          	ld	s6,8(s5)
ffffffffc0200f44:	8652                	mv	a2,s4
ffffffffc0200f46:	855e                	mv	a0,s7
ffffffffc0200f48:	85da                	mv	a1,s6
ffffffffc0200f4a:	a02ff0ef          	jal	ra,ffffffffc020014c <cprintf>
            buddy_free_pages(blocks[i], sizes[i]);
ffffffffc0200f4e:	85da                	mv	a1,s6
ffffffffc0200f50:	8552                	mv	a0,s4
ffffffffc0200f52:	bf7ff0ef          	jal	ra,ffffffffc0200b48 <buddy_free_pages>
            blocks[i] = NULL;
ffffffffc0200f56:	0004b423          	sd	zero,8(s1)
    for (int i = 1; i < 6; i += 2) {
ffffffffc0200f5a:	04c1                	addi	s1,s1,16
ffffffffc0200f5c:	0ac1                	addi	s5,s5,16
ffffffffc0200f5e:	fc999de3          	bne	s3,s1,ffffffffc0200f38 <buddy_system_check+0x214>
    cprintf("Phase 3: Re-allocating...\n");
ffffffffc0200f62:	00001517          	auipc	a0,0x1
ffffffffc0200f66:	15650513          	addi	a0,a0,342 # ffffffffc02020b8 <etext+0x9c2>
ffffffffc0200f6a:	9e2ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200f6e:	8a4a                	mv	s4,s2
ffffffffc0200f70:	84a2                	mv	s1,s0
                cprintf("  Re-allocated %2u pages at 0x%08x\n", sizes[i], blocks[i]);
ffffffffc0200f72:	00001b17          	auipc	s6,0x1
ffffffffc0200f76:	166b0b13          	addi	s6,s6,358 # ffffffffc02020d8 <etext+0x9e2>
        if (blocks[i] == NULL) { 
ffffffffc0200f7a:	649c                	ld	a5,8(s1)
ffffffffc0200f7c:	c7b1                	beqz	a5,ffffffffc0200fc8 <buddy_system_check+0x2a4>
    for (int i = 1; i < 6; i += 2) {
ffffffffc0200f7e:	04c1                	addi	s1,s1,16
ffffffffc0200f80:	0a41                	addi	s4,s4,16
ffffffffc0200f82:	fe999ce3          	bne	s3,s1,ffffffffc0200f7a <buddy_system_check+0x256>
    cprintf("Phase 4: Freeing all blocks...\n");
ffffffffc0200f86:	00001517          	auipc	a0,0x1
ffffffffc0200f8a:	17a50513          	addi	a0,a0,378 # ffffffffc0202100 <etext+0xa0a>
ffffffffc0200f8e:	9beff0ef          	jal	ra,ffffffffc020014c <cprintf>
        if (blocks[i] != NULL) {
ffffffffc0200f92:	6008                	ld	a0,0(s0)
ffffffffc0200f94:	c509                	beqz	a0,ffffffffc0200f9e <buddy_system_check+0x27a>
            buddy_free_pages(blocks[i], sizes[i]);
ffffffffc0200f96:	00093583          	ld	a1,0(s2)
ffffffffc0200f9a:	bafff0ef          	jal	ra,ffffffffc0200b48 <buddy_free_pages>
    for (int i = 0; i < 6; i++) {
ffffffffc0200f9e:	0421                	addi	s0,s0,8
ffffffffc0200fa0:	0921                	addi	s2,s2,8
ffffffffc0200fa2:	fe8998e3          	bne	s3,s0,ffffffffc0200f92 <buddy_system_check+0x26e>
}
ffffffffc0200fa6:	740a                	ld	s0,160(sp)
ffffffffc0200fa8:	70aa                	ld	ra,168(sp)
ffffffffc0200faa:	64ea                	ld	s1,152(sp)
ffffffffc0200fac:	694a                	ld	s2,144(sp)
ffffffffc0200fae:	69aa                	ld	s3,136(sp)
ffffffffc0200fb0:	6a0a                	ld	s4,128(sp)
ffffffffc0200fb2:	7ae6                	ld	s5,120(sp)
ffffffffc0200fb4:	7b46                	ld	s6,112(sp)
ffffffffc0200fb6:	7ba6                	ld	s7,104(sp)
ffffffffc0200fb8:	7c06                	ld	s8,96(sp)
    cprintf("Test 5 PASSED\n");
ffffffffc0200fba:	00001517          	auipc	a0,0x1
ffffffffc0200fbe:	16650513          	addi	a0,a0,358 # ffffffffc0202120 <etext+0xa2a>
}
ffffffffc0200fc2:	614d                	addi	sp,sp,176
    cprintf("Test 5 PASSED\n");
ffffffffc0200fc4:	988ff06f          	j	ffffffffc020014c <cprintf>
            blocks[i] = buddy_alloc_pages(sizes[i]);
ffffffffc0200fc8:	008a3a83          	ld	s5,8(s4)
ffffffffc0200fcc:	8556                	mv	a0,s5
ffffffffc0200fce:	943ff0ef          	jal	ra,ffffffffc0200910 <buddy_alloc_pages>
ffffffffc0200fd2:	e488                	sd	a0,8(s1)
ffffffffc0200fd4:	862a                	mv	a2,a0
            if (blocks[i] != NULL) {
ffffffffc0200fd6:	d545                	beqz	a0,ffffffffc0200f7e <buddy_system_check+0x25a>
                cprintf("  Re-allocated %2u pages at 0x%08x\n", sizes[i], blocks[i]);
ffffffffc0200fd8:	85d6                	mv	a1,s5
ffffffffc0200fda:	855a                	mv	a0,s6
ffffffffc0200fdc:	970ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200fe0:	bf79                	j	ffffffffc0200f7e <buddy_system_check+0x25a>
        cprintf("Test 4 SKIPPED: Not enough free pages\n");
ffffffffc0200fe2:	00001517          	auipc	a0,0x1
ffffffffc0200fe6:	fb650513          	addi	a0,a0,-74 # ffffffffc0201f98 <etext+0x8a2>
ffffffffc0200fea:	962ff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0200fee:	bd71                	j	ffffffffc0200e8a <buddy_system_check+0x166>
        cprintf("Test 2 SKIPPED: Cannot allocate 4 pages, showing current state:\n");
ffffffffc0200ff0:	00001517          	auipc	a0,0x1
ffffffffc0200ff4:	e8850513          	addi	a0,a0,-376 # ffffffffc0201e78 <etext+0x782>
ffffffffc0200ff8:	954ff0ef          	jal	ra,ffffffffc020014c <cprintf>
        show_buddy_array(0, buddy_sys.max_order);
ffffffffc0200ffc:	00092583          	lw	a1,0(s2)
    if (start_order > end_order || end_order > BUDDY_MAX_ORDER) {
ffffffffc0201000:	47bd                	li	a5,15
ffffffffc0201002:	00b7f963          	bgeu	a5,a1,ffffffffc0201014 <buddy_system_check+0x2f0>
        cprintf("show_buddy_array: invalid order range\n");
ffffffffc0201006:	00001517          	auipc	a0,0x1
ffffffffc020100a:	db250513          	addi	a0,a0,-590 # ffffffffc0201db8 <etext+0x6c2>
ffffffffc020100e:	93eff0ef          	jal	ra,ffffffffc020014c <cprintf>
        return;
ffffffffc0201012:	b34d                	j	ffffffffc0200db4 <buddy_system_check+0x90>
ffffffffc0201014:	4501                	li	a0,0
ffffffffc0201016:	dbaff0ef          	jal	ra,ffffffffc02005d0 <show_buddy_array.part.0>
ffffffffc020101a:	bb69                	j	ffffffffc0200db4 <buddy_system_check+0x90>
    struct Page *buddy = buddy_sys.base_page + buddy_index;
ffffffffc020101c:	00279713          	slli	a4,a5,0x2
ffffffffc0201020:	97ba                	add	a5,a5,a4
ffffffffc0201022:	078e                	slli	a5,a5,0x3
ffffffffc0201024:	963e                	add	a2,a2,a5
    return (buddy1 == block2) && (buddy2 == block1);
ffffffffc0201026:	dec41ce3          	bne	s0,a2,ffffffffc0200e1e <buddy_system_check+0xfa>
        buddy_free_pages(a1, 2);
ffffffffc020102a:	8522                	mv	a0,s0
ffffffffc020102c:	4589                	li	a1,2
ffffffffc020102e:	b1bff0ef          	jal	ra,ffffffffc0200b48 <buddy_free_pages>
        buddy_free_pages(a2, 2);
ffffffffc0201032:	8526                	mv	a0,s1
ffffffffc0201034:	4589                	li	a1,2
ffffffffc0201036:	b13ff0ef          	jal	ra,ffffffffc0200b48 <buddy_free_pages>
        cprintf("Test 3 PASSED\n");
ffffffffc020103a:	00001517          	auipc	a0,0x1
ffffffffc020103e:	eb650513          	addi	a0,a0,-330 # ffffffffc0201ef0 <etext+0x7fa>
ffffffffc0201042:	90aff0ef          	jal	ra,ffffffffc020014c <cprintf>
ffffffffc0201046:	b531                	j	ffffffffc0200e52 <buddy_system_check+0x12e>
    assert(p1 != NULL);
ffffffffc0201048:	00001697          	auipc	a3,0x1
ffffffffc020104c:	df068693          	addi	a3,a3,-528 # ffffffffc0201e38 <etext+0x742>
ffffffffc0201050:	00001617          	auipc	a2,0x1
ffffffffc0201054:	a4860613          	addi	a2,a2,-1464 # ffffffffc0201a98 <etext+0x3a2>
ffffffffc0201058:	16300593          	li	a1,355
ffffffffc020105c:	00001517          	auipc	a0,0x1
ffffffffc0201060:	a5450513          	addi	a0,a0,-1452 # ffffffffc0201ab0 <etext+0x3ba>
ffffffffc0201064:	95eff0ef          	jal	ra,ffffffffc02001c2 <__panic>
        assert(exhaust != NULL);
ffffffffc0201068:	00001697          	auipc	a3,0x1
ffffffffc020106c:	f1068693          	addi	a3,a3,-240 # ffffffffc0201f78 <etext+0x882>
ffffffffc0201070:	00001617          	auipc	a2,0x1
ffffffffc0201074:	a2860613          	addi	a2,a2,-1496 # ffffffffc0201a98 <etext+0x3a2>
ffffffffc0201078:	18500593          	li	a1,389
ffffffffc020107c:	00001517          	auipc	a0,0x1
ffffffffc0201080:	a3450513          	addi	a0,a0,-1484 # ffffffffc0201ab0 <etext+0x3ba>
ffffffffc0201084:	93eff0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201088 <buddy_pmm_check>:
static size_t buddy_nr_free_pages(void) {
    return buddy_system_nr_free_pages();
}

void buddy_pmm_check(void) {
    buddy_system_check();
ffffffffc0201088:	b971                	j	ffffffffc0200d24 <buddy_system_check>

ffffffffc020108a <pmm_init>:
static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    // 选择使用 buddy system
    pmm_manager = &buddy_pmm_manager;
ffffffffc020108a:	00001797          	auipc	a5,0x1
ffffffffc020108e:	0ee78793          	addi	a5,a5,238 # ffffffffc0202178 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201092:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201094:	7179                	addi	sp,sp,-48
ffffffffc0201096:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201098:	00001517          	auipc	a0,0x1
ffffffffc020109c:	11850513          	addi	a0,a0,280 # ffffffffc02021b0 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager;
ffffffffc02010a0:	00005417          	auipc	s0,0x5
ffffffffc02010a4:	15040413          	addi	s0,s0,336 # ffffffffc02061f0 <pmm_manager>
void pmm_init(void) {
ffffffffc02010a8:	f406                	sd	ra,40(sp)
ffffffffc02010aa:	ec26                	sd	s1,24(sp)
ffffffffc02010ac:	e44e                	sd	s3,8(sp)
ffffffffc02010ae:	e84a                	sd	s2,16(sp)
ffffffffc02010b0:	e052                	sd	s4,0(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc02010b2:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02010b4:	898ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    pmm_manager->init();
ffffffffc02010b8:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02010ba:	00005497          	auipc	s1,0x5
ffffffffc02010be:	14e48493          	addi	s1,s1,334 # ffffffffc0206208 <va_pa_offset>
    pmm_manager->init();
ffffffffc02010c2:	679c                	ld	a5,8(a5)
ffffffffc02010c4:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02010c6:	57f5                	li	a5,-3
ffffffffc02010c8:	07fa                	slli	a5,a5,0x1e
ffffffffc02010ca:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02010cc:	cf0ff0ef          	jal	ra,ffffffffc02005bc <get_memory_base>
ffffffffc02010d0:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02010d2:	cf4ff0ef          	jal	ra,ffffffffc02005c6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02010d6:	14050d63          	beqz	a0,ffffffffc0201230 <pmm_init+0x1a6>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02010da:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc02010dc:	00001517          	auipc	a0,0x1
ffffffffc02010e0:	11c50513          	addi	a0,a0,284 # ffffffffc02021f8 <buddy_pmm_manager+0x80>
ffffffffc02010e4:	868ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02010e8:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02010ec:	864e                	mv	a2,s3
ffffffffc02010ee:	fffa0693          	addi	a3,s4,-1
ffffffffc02010f2:	85ca                	mv	a1,s2
ffffffffc02010f4:	00001517          	auipc	a0,0x1
ffffffffc02010f8:	11c50513          	addi	a0,a0,284 # ffffffffc0202210 <buddy_pmm_manager+0x98>
ffffffffc02010fc:	850ff0ef          	jal	ra,ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201100:	c80007b7          	lui	a5,0xc8000
ffffffffc0201104:	8652                	mv	a2,s4
ffffffffc0201106:	0d47e463          	bltu	a5,s4,ffffffffc02011ce <pmm_init+0x144>
ffffffffc020110a:	00006797          	auipc	a5,0x6
ffffffffc020110e:	10578793          	addi	a5,a5,261 # ffffffffc020720f <end+0xfff>
ffffffffc0201112:	757d                	lui	a0,0xfffff
ffffffffc0201114:	8d7d                	and	a0,a0,a5
ffffffffc0201116:	8231                	srli	a2,a2,0xc
ffffffffc0201118:	00005797          	auipc	a5,0x5
ffffffffc020111c:	0cc7b423          	sd	a2,200(a5) # ffffffffc02061e0 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201120:	00005797          	auipc	a5,0x5
ffffffffc0201124:	0ca7b423          	sd	a0,200(a5) # ffffffffc02061e8 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201128:	000807b7          	lui	a5,0x80
ffffffffc020112c:	002005b7          	lui	a1,0x200
ffffffffc0201130:	02f60563          	beq	a2,a5,ffffffffc020115a <pmm_init+0xd0>
ffffffffc0201134:	00261593          	slli	a1,a2,0x2
ffffffffc0201138:	00c586b3          	add	a3,a1,a2
ffffffffc020113c:	fec007b7          	lui	a5,0xfec00
ffffffffc0201140:	97aa                	add	a5,a5,a0
ffffffffc0201142:	068e                	slli	a3,a3,0x3
ffffffffc0201144:	96be                	add	a3,a3,a5
ffffffffc0201146:	87aa                	mv	a5,a0
        SetPageReserved(pages + i);
ffffffffc0201148:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020114a:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9e18>
        SetPageReserved(pages + i);
ffffffffc020114e:	00176713          	ori	a4,a4,1
ffffffffc0201152:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201156:	fef699e3          	bne	a3,a5,ffffffffc0201148 <pmm_init+0xbe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020115a:	95b2                	add	a1,a1,a2
ffffffffc020115c:	fec006b7          	lui	a3,0xfec00
ffffffffc0201160:	96aa                	add	a3,a3,a0
ffffffffc0201162:	058e                	slli	a1,a1,0x3
ffffffffc0201164:	96ae                	add	a3,a3,a1
ffffffffc0201166:	c02007b7          	lui	a5,0xc0200
ffffffffc020116a:	0af6e763          	bltu	a3,a5,ffffffffc0201218 <pmm_init+0x18e>
ffffffffc020116e:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201170:	77fd                	lui	a5,0xfffff
ffffffffc0201172:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201176:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201178:	04b6ee63          	bltu	a3,a1,ffffffffc02011d4 <pmm_init+0x14a>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc020117c:	601c                	ld	a5,0(s0)
ffffffffc020117e:	7b9c                	ld	a5,48(a5)
ffffffffc0201180:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201182:	00001517          	auipc	a0,0x1
ffffffffc0201186:	11650513          	addi	a0,a0,278 # ffffffffc0202298 <buddy_pmm_manager+0x120>
ffffffffc020118a:	fc3fe0ef          	jal	ra,ffffffffc020014c <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020118e:	00004597          	auipc	a1,0x4
ffffffffc0201192:	e7258593          	addi	a1,a1,-398 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201196:	00005797          	auipc	a5,0x5
ffffffffc020119a:	06b7b523          	sd	a1,106(a5) # ffffffffc0206200 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020119e:	c02007b7          	lui	a5,0xc0200
ffffffffc02011a2:	0af5e363          	bltu	a1,a5,ffffffffc0201248 <pmm_init+0x1be>
ffffffffc02011a6:	6090                	ld	a2,0(s1)
}
ffffffffc02011a8:	7402                	ld	s0,32(sp)
ffffffffc02011aa:	70a2                	ld	ra,40(sp)
ffffffffc02011ac:	64e2                	ld	s1,24(sp)
ffffffffc02011ae:	6942                	ld	s2,16(sp)
ffffffffc02011b0:	69a2                	ld	s3,8(sp)
ffffffffc02011b2:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02011b4:	40c58633          	sub	a2,a1,a2
ffffffffc02011b8:	00005797          	auipc	a5,0x5
ffffffffc02011bc:	04c7b023          	sd	a2,64(a5) # ffffffffc02061f8 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011c0:	00001517          	auipc	a0,0x1
ffffffffc02011c4:	0f850513          	addi	a0,a0,248 # ffffffffc02022b8 <buddy_pmm_manager+0x140>
}
ffffffffc02011c8:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02011ca:	f83fe06f          	j	ffffffffc020014c <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02011ce:	c8000637          	lui	a2,0xc8000
ffffffffc02011d2:	bf25                	j	ffffffffc020110a <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02011d4:	6705                	lui	a4,0x1
ffffffffc02011d6:	177d                	addi	a4,a4,-1
ffffffffc02011d8:	96ba                	add	a3,a3,a4
ffffffffc02011da:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02011dc:	00c6d793          	srli	a5,a3,0xc
ffffffffc02011e0:	02c7f063          	bgeu	a5,a2,ffffffffc0201200 <pmm_init+0x176>
    pmm_manager->init_memmap(base, n);
ffffffffc02011e4:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02011e6:	fff80737          	lui	a4,0xfff80
ffffffffc02011ea:	973e                	add	a4,a4,a5
ffffffffc02011ec:	00271793          	slli	a5,a4,0x2
ffffffffc02011f0:	97ba                	add	a5,a5,a4
ffffffffc02011f2:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02011f4:	8d95                	sub	a1,a1,a3
ffffffffc02011f6:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02011f8:	81b1                	srli	a1,a1,0xc
ffffffffc02011fa:	953e                	add	a0,a0,a5
ffffffffc02011fc:	9702                	jalr	a4
}
ffffffffc02011fe:	bfbd                	j	ffffffffc020117c <pmm_init+0xf2>
        panic("pa2page called with invalid pa");
ffffffffc0201200:	00001617          	auipc	a2,0x1
ffffffffc0201204:	06860613          	addi	a2,a2,104 # ffffffffc0202268 <buddy_pmm_manager+0xf0>
ffffffffc0201208:	06a00593          	li	a1,106
ffffffffc020120c:	00001517          	auipc	a0,0x1
ffffffffc0201210:	07c50513          	addi	a0,a0,124 # ffffffffc0202288 <buddy_pmm_manager+0x110>
ffffffffc0201214:	faffe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201218:	00001617          	auipc	a2,0x1
ffffffffc020121c:	02860613          	addi	a2,a2,40 # ffffffffc0202240 <buddy_pmm_manager+0xc8>
ffffffffc0201220:	06000593          	li	a1,96
ffffffffc0201224:	00001517          	auipc	a0,0x1
ffffffffc0201228:	fc450513          	addi	a0,a0,-60 # ffffffffc02021e8 <buddy_pmm_manager+0x70>
ffffffffc020122c:	f97fe0ef          	jal	ra,ffffffffc02001c2 <__panic>
        panic("DTB memory info not available");
ffffffffc0201230:	00001617          	auipc	a2,0x1
ffffffffc0201234:	f9860613          	addi	a2,a2,-104 # ffffffffc02021c8 <buddy_pmm_manager+0x50>
ffffffffc0201238:	04800593          	li	a1,72
ffffffffc020123c:	00001517          	auipc	a0,0x1
ffffffffc0201240:	fac50513          	addi	a0,a0,-84 # ffffffffc02021e8 <buddy_pmm_manager+0x70>
ffffffffc0201244:	f7ffe0ef          	jal	ra,ffffffffc02001c2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201248:	86ae                	mv	a3,a1
ffffffffc020124a:	00001617          	auipc	a2,0x1
ffffffffc020124e:	ff660613          	addi	a2,a2,-10 # ffffffffc0202240 <buddy_pmm_manager+0xc8>
ffffffffc0201252:	07b00593          	li	a1,123
ffffffffc0201256:	00001517          	auipc	a0,0x1
ffffffffc020125a:	f9250513          	addi	a0,a0,-110 # ffffffffc02021e8 <buddy_pmm_manager+0x70>
ffffffffc020125e:	f65fe0ef          	jal	ra,ffffffffc02001c2 <__panic>

ffffffffc0201262 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201262:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201266:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201268:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020126c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020126e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201272:	f022                	sd	s0,32(sp)
ffffffffc0201274:	ec26                	sd	s1,24(sp)
ffffffffc0201276:	e84a                	sd	s2,16(sp)
ffffffffc0201278:	f406                	sd	ra,40(sp)
ffffffffc020127a:	e44e                	sd	s3,8(sp)
ffffffffc020127c:	84aa                	mv	s1,a0
ffffffffc020127e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201280:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201284:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201286:	03067e63          	bgeu	a2,a6,ffffffffc02012c2 <printnum+0x60>
ffffffffc020128a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020128c:	00805763          	blez	s0,ffffffffc020129a <printnum+0x38>
ffffffffc0201290:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201292:	85ca                	mv	a1,s2
ffffffffc0201294:	854e                	mv	a0,s3
ffffffffc0201296:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201298:	fc65                	bnez	s0,ffffffffc0201290 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020129a:	1a02                	slli	s4,s4,0x20
ffffffffc020129c:	00001797          	auipc	a5,0x1
ffffffffc02012a0:	05c78793          	addi	a5,a5,92 # ffffffffc02022f8 <buddy_pmm_manager+0x180>
ffffffffc02012a4:	020a5a13          	srli	s4,s4,0x20
ffffffffc02012a8:	9a3e                	add	s4,s4,a5
}
ffffffffc02012aa:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012ac:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02012b0:	70a2                	ld	ra,40(sp)
ffffffffc02012b2:	69a2                	ld	s3,8(sp)
ffffffffc02012b4:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012b6:	85ca                	mv	a1,s2
ffffffffc02012b8:	87a6                	mv	a5,s1
}
ffffffffc02012ba:	6942                	ld	s2,16(sp)
ffffffffc02012bc:	64e2                	ld	s1,24(sp)
ffffffffc02012be:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02012c0:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02012c2:	03065633          	divu	a2,a2,a6
ffffffffc02012c6:	8722                	mv	a4,s0
ffffffffc02012c8:	f9bff0ef          	jal	ra,ffffffffc0201262 <printnum>
ffffffffc02012cc:	b7f9                	j	ffffffffc020129a <printnum+0x38>

ffffffffc02012ce <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02012ce:	7119                	addi	sp,sp,-128
ffffffffc02012d0:	f4a6                	sd	s1,104(sp)
ffffffffc02012d2:	f0ca                	sd	s2,96(sp)
ffffffffc02012d4:	ecce                	sd	s3,88(sp)
ffffffffc02012d6:	e8d2                	sd	s4,80(sp)
ffffffffc02012d8:	e4d6                	sd	s5,72(sp)
ffffffffc02012da:	e0da                	sd	s6,64(sp)
ffffffffc02012dc:	fc5e                	sd	s7,56(sp)
ffffffffc02012de:	f06a                	sd	s10,32(sp)
ffffffffc02012e0:	fc86                	sd	ra,120(sp)
ffffffffc02012e2:	f8a2                	sd	s0,112(sp)
ffffffffc02012e4:	f862                	sd	s8,48(sp)
ffffffffc02012e6:	f466                	sd	s9,40(sp)
ffffffffc02012e8:	ec6e                	sd	s11,24(sp)
ffffffffc02012ea:	892a                	mv	s2,a0
ffffffffc02012ec:	84ae                	mv	s1,a1
ffffffffc02012ee:	8d32                	mv	s10,a2
ffffffffc02012f0:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012f2:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02012f6:	5b7d                	li	s6,-1
ffffffffc02012f8:	00001a97          	auipc	s5,0x1
ffffffffc02012fc:	034a8a93          	addi	s5,s5,52 # ffffffffc020232c <buddy_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201300:	00001b97          	auipc	s7,0x1
ffffffffc0201304:	208b8b93          	addi	s7,s7,520 # ffffffffc0202508 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201308:	000d4503          	lbu	a0,0(s10)
ffffffffc020130c:	001d0413          	addi	s0,s10,1
ffffffffc0201310:	01350a63          	beq	a0,s3,ffffffffc0201324 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201314:	c121                	beqz	a0,ffffffffc0201354 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201316:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201318:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020131a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020131c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201320:	ff351ae3          	bne	a0,s3,ffffffffc0201314 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201324:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201328:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020132c:	4c81                	li	s9,0
ffffffffc020132e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201330:	5c7d                	li	s8,-1
ffffffffc0201332:	5dfd                	li	s11,-1
ffffffffc0201334:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201338:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020133a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020133e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201342:	00140d13          	addi	s10,s0,1
ffffffffc0201346:	04b56263          	bltu	a0,a1,ffffffffc020138a <vprintfmt+0xbc>
ffffffffc020134a:	058a                	slli	a1,a1,0x2
ffffffffc020134c:	95d6                	add	a1,a1,s5
ffffffffc020134e:	4194                	lw	a3,0(a1)
ffffffffc0201350:	96d6                	add	a3,a3,s5
ffffffffc0201352:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201354:	70e6                	ld	ra,120(sp)
ffffffffc0201356:	7446                	ld	s0,112(sp)
ffffffffc0201358:	74a6                	ld	s1,104(sp)
ffffffffc020135a:	7906                	ld	s2,96(sp)
ffffffffc020135c:	69e6                	ld	s3,88(sp)
ffffffffc020135e:	6a46                	ld	s4,80(sp)
ffffffffc0201360:	6aa6                	ld	s5,72(sp)
ffffffffc0201362:	6b06                	ld	s6,64(sp)
ffffffffc0201364:	7be2                	ld	s7,56(sp)
ffffffffc0201366:	7c42                	ld	s8,48(sp)
ffffffffc0201368:	7ca2                	ld	s9,40(sp)
ffffffffc020136a:	7d02                	ld	s10,32(sp)
ffffffffc020136c:	6de2                	ld	s11,24(sp)
ffffffffc020136e:	6109                	addi	sp,sp,128
ffffffffc0201370:	8082                	ret
            padc = '0';
ffffffffc0201372:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201374:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201378:	846a                	mv	s0,s10
ffffffffc020137a:	00140d13          	addi	s10,s0,1
ffffffffc020137e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201382:	0ff5f593          	zext.b	a1,a1
ffffffffc0201386:	fcb572e3          	bgeu	a0,a1,ffffffffc020134a <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020138a:	85a6                	mv	a1,s1
ffffffffc020138c:	02500513          	li	a0,37
ffffffffc0201390:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201392:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201396:	8d22                	mv	s10,s0
ffffffffc0201398:	f73788e3          	beq	a5,s3,ffffffffc0201308 <vprintfmt+0x3a>
ffffffffc020139c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc02013a0:	1d7d                	addi	s10,s10,-1
ffffffffc02013a2:	ff379de3          	bne	a5,s3,ffffffffc020139c <vprintfmt+0xce>
ffffffffc02013a6:	b78d                	j	ffffffffc0201308 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc02013a8:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc02013ac:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013b0:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc02013b2:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02013b6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02013ba:	02d86463          	bltu	a6,a3,ffffffffc02013e2 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc02013be:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02013c2:	002c169b          	slliw	a3,s8,0x2
ffffffffc02013c6:	0186873b          	addw	a4,a3,s8
ffffffffc02013ca:	0017171b          	slliw	a4,a4,0x1
ffffffffc02013ce:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02013d0:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02013d4:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02013d6:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02013da:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02013de:	fed870e3          	bgeu	a6,a3,ffffffffc02013be <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02013e2:	f40ddce3          	bgez	s11,ffffffffc020133a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02013e6:	8de2                	mv	s11,s8
ffffffffc02013e8:	5c7d                	li	s8,-1
ffffffffc02013ea:	bf81                	j	ffffffffc020133a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02013ec:	fffdc693          	not	a3,s11
ffffffffc02013f0:	96fd                	srai	a3,a3,0x3f
ffffffffc02013f2:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013f6:	00144603          	lbu	a2,1(s0)
ffffffffc02013fa:	2d81                	sext.w	s11,s11
ffffffffc02013fc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02013fe:	bf35                	j	ffffffffc020133a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201400:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201404:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201408:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020140a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020140c:	bfd9                	j	ffffffffc02013e2 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020140e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201410:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201414:	01174463          	blt	a4,a7,ffffffffc020141c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201418:	1a088e63          	beqz	a7,ffffffffc02015d4 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020141c:	000a3603          	ld	a2,0(s4)
ffffffffc0201420:	46c1                	li	a3,16
ffffffffc0201422:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201424:	2781                	sext.w	a5,a5
ffffffffc0201426:	876e                	mv	a4,s11
ffffffffc0201428:	85a6                	mv	a1,s1
ffffffffc020142a:	854a                	mv	a0,s2
ffffffffc020142c:	e37ff0ef          	jal	ra,ffffffffc0201262 <printnum>
            break;
ffffffffc0201430:	bde1                	j	ffffffffc0201308 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201432:	000a2503          	lw	a0,0(s4)
ffffffffc0201436:	85a6                	mv	a1,s1
ffffffffc0201438:	0a21                	addi	s4,s4,8
ffffffffc020143a:	9902                	jalr	s2
            break;
ffffffffc020143c:	b5f1                	j	ffffffffc0201308 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020143e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201440:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201444:	01174463          	blt	a4,a7,ffffffffc020144c <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201448:	18088163          	beqz	a7,ffffffffc02015ca <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc020144c:	000a3603          	ld	a2,0(s4)
ffffffffc0201450:	46a9                	li	a3,10
ffffffffc0201452:	8a2e                	mv	s4,a1
ffffffffc0201454:	bfc1                	j	ffffffffc0201424 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201456:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020145a:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020145c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020145e:	bdf1                	j	ffffffffc020133a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201460:	85a6                	mv	a1,s1
ffffffffc0201462:	02500513          	li	a0,37
ffffffffc0201466:	9902                	jalr	s2
            break;
ffffffffc0201468:	b545                	j	ffffffffc0201308 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020146a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020146e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201470:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201472:	b5e1                	j	ffffffffc020133a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201474:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201476:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020147a:	01174463          	blt	a4,a7,ffffffffc0201482 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020147e:	14088163          	beqz	a7,ffffffffc02015c0 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201482:	000a3603          	ld	a2,0(s4)
ffffffffc0201486:	46a1                	li	a3,8
ffffffffc0201488:	8a2e                	mv	s4,a1
ffffffffc020148a:	bf69                	j	ffffffffc0201424 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020148c:	03000513          	li	a0,48
ffffffffc0201490:	85a6                	mv	a1,s1
ffffffffc0201492:	e03e                	sd	a5,0(sp)
ffffffffc0201494:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201496:	85a6                	mv	a1,s1
ffffffffc0201498:	07800513          	li	a0,120
ffffffffc020149c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020149e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02014a0:	6782                	ld	a5,0(sp)
ffffffffc02014a2:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02014a4:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc02014a8:	bfb5                	j	ffffffffc0201424 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02014aa:	000a3403          	ld	s0,0(s4)
ffffffffc02014ae:	008a0713          	addi	a4,s4,8
ffffffffc02014b2:	e03a                	sd	a4,0(sp)
ffffffffc02014b4:	14040263          	beqz	s0,ffffffffc02015f8 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc02014b8:	0fb05763          	blez	s11,ffffffffc02015a6 <vprintfmt+0x2d8>
ffffffffc02014bc:	02d00693          	li	a3,45
ffffffffc02014c0:	0cd79163          	bne	a5,a3,ffffffffc0201582 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014c4:	00044783          	lbu	a5,0(s0)
ffffffffc02014c8:	0007851b          	sext.w	a0,a5
ffffffffc02014cc:	cf85                	beqz	a5,ffffffffc0201504 <vprintfmt+0x236>
ffffffffc02014ce:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014d2:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014d6:	000c4563          	bltz	s8,ffffffffc02014e0 <vprintfmt+0x212>
ffffffffc02014da:	3c7d                	addiw	s8,s8,-1
ffffffffc02014dc:	036c0263          	beq	s8,s6,ffffffffc0201500 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02014e0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014e2:	0e0c8e63          	beqz	s9,ffffffffc02015de <vprintfmt+0x310>
ffffffffc02014e6:	3781                	addiw	a5,a5,-32
ffffffffc02014e8:	0ef47b63          	bgeu	s0,a5,ffffffffc02015de <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02014ec:	03f00513          	li	a0,63
ffffffffc02014f0:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014f2:	000a4783          	lbu	a5,0(s4)
ffffffffc02014f6:	3dfd                	addiw	s11,s11,-1
ffffffffc02014f8:	0a05                	addi	s4,s4,1
ffffffffc02014fa:	0007851b          	sext.w	a0,a5
ffffffffc02014fe:	ffe1                	bnez	a5,ffffffffc02014d6 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201500:	01b05963          	blez	s11,ffffffffc0201512 <vprintfmt+0x244>
ffffffffc0201504:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201506:	85a6                	mv	a1,s1
ffffffffc0201508:	02000513          	li	a0,32
ffffffffc020150c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020150e:	fe0d9be3          	bnez	s11,ffffffffc0201504 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201512:	6a02                	ld	s4,0(sp)
ffffffffc0201514:	bbd5                	j	ffffffffc0201308 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201516:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201518:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020151c:	01174463          	blt	a4,a7,ffffffffc0201524 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201520:	08088d63          	beqz	a7,ffffffffc02015ba <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201524:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201528:	0a044d63          	bltz	s0,ffffffffc02015e2 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020152c:	8622                	mv	a2,s0
ffffffffc020152e:	8a66                	mv	s4,s9
ffffffffc0201530:	46a9                	li	a3,10
ffffffffc0201532:	bdcd                	j	ffffffffc0201424 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201534:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201538:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc020153a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020153c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201540:	8fb5                	xor	a5,a5,a3
ffffffffc0201542:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201546:	02d74163          	blt	a4,a3,ffffffffc0201568 <vprintfmt+0x29a>
ffffffffc020154a:	00369793          	slli	a5,a3,0x3
ffffffffc020154e:	97de                	add	a5,a5,s7
ffffffffc0201550:	639c                	ld	a5,0(a5)
ffffffffc0201552:	cb99                	beqz	a5,ffffffffc0201568 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201554:	86be                	mv	a3,a5
ffffffffc0201556:	00001617          	auipc	a2,0x1
ffffffffc020155a:	dd260613          	addi	a2,a2,-558 # ffffffffc0202328 <buddy_pmm_manager+0x1b0>
ffffffffc020155e:	85a6                	mv	a1,s1
ffffffffc0201560:	854a                	mv	a0,s2
ffffffffc0201562:	0ce000ef          	jal	ra,ffffffffc0201630 <printfmt>
ffffffffc0201566:	b34d                	j	ffffffffc0201308 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201568:	00001617          	auipc	a2,0x1
ffffffffc020156c:	db060613          	addi	a2,a2,-592 # ffffffffc0202318 <buddy_pmm_manager+0x1a0>
ffffffffc0201570:	85a6                	mv	a1,s1
ffffffffc0201572:	854a                	mv	a0,s2
ffffffffc0201574:	0bc000ef          	jal	ra,ffffffffc0201630 <printfmt>
ffffffffc0201578:	bb41                	j	ffffffffc0201308 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020157a:	00001417          	auipc	s0,0x1
ffffffffc020157e:	d9640413          	addi	s0,s0,-618 # ffffffffc0202310 <buddy_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201582:	85e2                	mv	a1,s8
ffffffffc0201584:	8522                	mv	a0,s0
ffffffffc0201586:	e43e                	sd	a5,8(sp)
ffffffffc0201588:	0fc000ef          	jal	ra,ffffffffc0201684 <strnlen>
ffffffffc020158c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201590:	01b05b63          	blez	s11,ffffffffc02015a6 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201594:	67a2                	ld	a5,8(sp)
ffffffffc0201596:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020159a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020159c:	85a6                	mv	a1,s1
ffffffffc020159e:	8552                	mv	a0,s4
ffffffffc02015a0:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015a2:	fe0d9ce3          	bnez	s11,ffffffffc020159a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015a6:	00044783          	lbu	a5,0(s0)
ffffffffc02015aa:	00140a13          	addi	s4,s0,1
ffffffffc02015ae:	0007851b          	sext.w	a0,a5
ffffffffc02015b2:	d3a5                	beqz	a5,ffffffffc0201512 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02015b4:	05e00413          	li	s0,94
ffffffffc02015b8:	bf39                	j	ffffffffc02014d6 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc02015ba:	000a2403          	lw	s0,0(s4)
ffffffffc02015be:	b7ad                	j	ffffffffc0201528 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc02015c0:	000a6603          	lwu	a2,0(s4)
ffffffffc02015c4:	46a1                	li	a3,8
ffffffffc02015c6:	8a2e                	mv	s4,a1
ffffffffc02015c8:	bdb1                	j	ffffffffc0201424 <vprintfmt+0x156>
ffffffffc02015ca:	000a6603          	lwu	a2,0(s4)
ffffffffc02015ce:	46a9                	li	a3,10
ffffffffc02015d0:	8a2e                	mv	s4,a1
ffffffffc02015d2:	bd89                	j	ffffffffc0201424 <vprintfmt+0x156>
ffffffffc02015d4:	000a6603          	lwu	a2,0(s4)
ffffffffc02015d8:	46c1                	li	a3,16
ffffffffc02015da:	8a2e                	mv	s4,a1
ffffffffc02015dc:	b5a1                	j	ffffffffc0201424 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02015de:	9902                	jalr	s2
ffffffffc02015e0:	bf09                	j	ffffffffc02014f2 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02015e2:	85a6                	mv	a1,s1
ffffffffc02015e4:	02d00513          	li	a0,45
ffffffffc02015e8:	e03e                	sd	a5,0(sp)
ffffffffc02015ea:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02015ec:	6782                	ld	a5,0(sp)
ffffffffc02015ee:	8a66                	mv	s4,s9
ffffffffc02015f0:	40800633          	neg	a2,s0
ffffffffc02015f4:	46a9                	li	a3,10
ffffffffc02015f6:	b53d                	j	ffffffffc0201424 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02015f8:	03b05163          	blez	s11,ffffffffc020161a <vprintfmt+0x34c>
ffffffffc02015fc:	02d00693          	li	a3,45
ffffffffc0201600:	f6d79de3          	bne	a5,a3,ffffffffc020157a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201604:	00001417          	auipc	s0,0x1
ffffffffc0201608:	d0c40413          	addi	s0,s0,-756 # ffffffffc0202310 <buddy_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020160c:	02800793          	li	a5,40
ffffffffc0201610:	02800513          	li	a0,40
ffffffffc0201614:	00140a13          	addi	s4,s0,1
ffffffffc0201618:	bd6d                	j	ffffffffc02014d2 <vprintfmt+0x204>
ffffffffc020161a:	00001a17          	auipc	s4,0x1
ffffffffc020161e:	cf7a0a13          	addi	s4,s4,-777 # ffffffffc0202311 <buddy_pmm_manager+0x199>
ffffffffc0201622:	02800513          	li	a0,40
ffffffffc0201626:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020162a:	05e00413          	li	s0,94
ffffffffc020162e:	b565                	j	ffffffffc02014d6 <vprintfmt+0x208>

ffffffffc0201630 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201630:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201632:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201636:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201638:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020163a:	ec06                	sd	ra,24(sp)
ffffffffc020163c:	f83a                	sd	a4,48(sp)
ffffffffc020163e:	fc3e                	sd	a5,56(sp)
ffffffffc0201640:	e0c2                	sd	a6,64(sp)
ffffffffc0201642:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201644:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201646:	c89ff0ef          	jal	ra,ffffffffc02012ce <vprintfmt>
}
ffffffffc020164a:	60e2                	ld	ra,24(sp)
ffffffffc020164c:	6161                	addi	sp,sp,80
ffffffffc020164e:	8082                	ret

ffffffffc0201650 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201650:	4781                	li	a5,0
ffffffffc0201652:	00005717          	auipc	a4,0x5
ffffffffc0201656:	9be73703          	ld	a4,-1602(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc020165a:	88ba                	mv	a7,a4
ffffffffc020165c:	852a                	mv	a0,a0
ffffffffc020165e:	85be                	mv	a1,a5
ffffffffc0201660:	863e                	mv	a2,a5
ffffffffc0201662:	00000073          	ecall
ffffffffc0201666:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201668:	8082                	ret

ffffffffc020166a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020166a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc020166e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201670:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201672:	cb81                	beqz	a5,ffffffffc0201682 <strlen+0x18>
        cnt ++;
ffffffffc0201674:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201676:	00a707b3          	add	a5,a4,a0
ffffffffc020167a:	0007c783          	lbu	a5,0(a5)
ffffffffc020167e:	fbfd                	bnez	a5,ffffffffc0201674 <strlen+0xa>
ffffffffc0201680:	8082                	ret
    }
    return cnt;
}
ffffffffc0201682:	8082                	ret

ffffffffc0201684 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201684:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201686:	e589                	bnez	a1,ffffffffc0201690 <strnlen+0xc>
ffffffffc0201688:	a811                	j	ffffffffc020169c <strnlen+0x18>
        cnt ++;
ffffffffc020168a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020168c:	00f58863          	beq	a1,a5,ffffffffc020169c <strnlen+0x18>
ffffffffc0201690:	00f50733          	add	a4,a0,a5
ffffffffc0201694:	00074703          	lbu	a4,0(a4)
ffffffffc0201698:	fb6d                	bnez	a4,ffffffffc020168a <strnlen+0x6>
ffffffffc020169a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020169c:	852e                	mv	a0,a1
ffffffffc020169e:	8082                	ret

ffffffffc02016a0 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016a0:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016a4:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016a8:	cb89                	beqz	a5,ffffffffc02016ba <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02016aa:	0505                	addi	a0,a0,1
ffffffffc02016ac:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02016ae:	fee789e3          	beq	a5,a4,ffffffffc02016a0 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016b2:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02016b6:	9d19                	subw	a0,a0,a4
ffffffffc02016b8:	8082                	ret
ffffffffc02016ba:	4501                	li	a0,0
ffffffffc02016bc:	bfed                	j	ffffffffc02016b6 <strcmp+0x16>

ffffffffc02016be <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02016be:	c20d                	beqz	a2,ffffffffc02016e0 <strncmp+0x22>
ffffffffc02016c0:	962e                	add	a2,a2,a1
ffffffffc02016c2:	a031                	j	ffffffffc02016ce <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc02016c4:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02016c6:	00e79a63          	bne	a5,a4,ffffffffc02016da <strncmp+0x1c>
ffffffffc02016ca:	00b60b63          	beq	a2,a1,ffffffffc02016e0 <strncmp+0x22>
ffffffffc02016ce:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02016d2:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02016d4:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02016d8:	f7f5                	bnez	a5,ffffffffc02016c4 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016da:	40e7853b          	subw	a0,a5,a4
}
ffffffffc02016de:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016e0:	4501                	li	a0,0
ffffffffc02016e2:	8082                	ret

ffffffffc02016e4 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02016e4:	ca01                	beqz	a2,ffffffffc02016f4 <memset+0x10>
ffffffffc02016e6:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02016e8:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02016ea:	0785                	addi	a5,a5,1
ffffffffc02016ec:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02016f0:	fec79de3          	bne	a5,a2,ffffffffc02016ea <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02016f4:	8082                	ret
