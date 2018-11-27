# computer





## 调试信息



### IF阶段 000000            

#### 数码管

pc低八位

#### led

指令低16位



### id阶段 000001

#### 数码管

aluop

#### led

高8位：reg1低8位

低8位：reg2低8位

### ex阶段 000010

##### 数码管

写回寄存器地址

#### led

写入寄存器数据低16位



### MEM阶段 000011/100011

#### 000011

##### 数码管

读取内存数据低8位 mem_wdata

#### led

写入内存位置低16位 mem_addr

#### 10011

##### 数码管

读取内存数据高8位 mem_wdata

#### led

写入内存位置高16位 mem_addr



### wb阶段 000100

##### 数码管

写回寄存器地址

#### led

写入寄存器数据低16位



### ctrl 000101

stallreq_from_id

stallreq_from_ex

8位0

stall[5:0]

### bus 阶段 000110

##### 数码管

指令地址低八位

##### led

sram_no,if_addr_i[22],if_ce_i,mem_ce_i,mem_we_i,sram_ce_o,sram_we_o,sram_addr_o[8:0]

要访问的sram地址低十位sram_addr_o[9:0]



### sram_controller (000111 base_ram 001000 ext_ram)

##### 数码管

访问地址低八位sram_addr

##### led

sram_ce_n,sram_oe_n,sram_we_n

低八位：读写数据低八位