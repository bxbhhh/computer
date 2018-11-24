# computer





## 调试信息



### IF阶段 000000            

高8位：pc低8位

低8位：指令低8位

### id阶段 000001

高8位：reg1低8位

低8位：reg2低8位

### ex阶段 000010

高3位：无

高5位：写入寄存器地址

低8位：写入寄存器数据

### MEM阶段 000011

高5位 写回寄存器地址 mem_wd

低8位 写回寄存器数 mem_wdata

### wb阶段 000100

### ctrl 000101

stallreq_from_id

stallreq_from_ex

8位0

stall[5:0]