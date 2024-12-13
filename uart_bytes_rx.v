
// *****************************************************************************************************************************
// ** 作者 ： 孤独的单刀                                                   			
// ** 邮箱 ： zachary_wu93@163.com
// ** 博客 ： https://blog.csdn.net/wuzhikaidetb 
// ** 日期 ： 2022/08/05	
// ** 功能 ： 1、基于FPGA的串口多字节接收模块；
//			  2、可设置一次接收的字节数、波特率BPS、主时钟CLK_FRE；
//			  3、UART协议设置为起始位1bit，数据位8bit，停止位1bit，无奇偶校验（不可在端口更改，只能更改发送驱动源码）；                                           									                                                                          			
//			  4、每接收到1次多字节后拉高指示信号一个周期，指示一次多字节接收结束；
//			  5、数据接收顺序，先接收低字节、再接收高字节。如：第1次接收到8’h34，第2次接收到8’h12，则最终接收到的数据为16'h12_34。                                          									                                                                          			
// *****************************************************************************************************************************	

module uart_bytes_rx
#(
	parameter	integer	BYTES 	 = 4			,				//一次接收字节数，单字节8bit
	parameter	integer	BPS		 = 9600			,				//发送波特率
	parameter 	integer	CLK_FRE	 = 25_000_000					//输入时钟频率
)
(
//系统接口
	input 	  wire					    clk			,			//系统时钟
	input 	  wire					    rstn		,			//系统复位，低电平有效
//用户接口	
	output	  reg [(BYTES * 8 - 1):0] 	uart_bytes_data	,			//接收到的多字节数据，在uart_bytes_vld为高电平时有效
	output	  reg					    uart_bytes_vld	,			//成功发送所有字节数据后拉高1个时钟周期，代表此时接收的数据有效	
//UART接收	
	input 	  wire  					uart_rxd					//UART发送数据线rx
);

//reg define
reg	[(BYTES*8-1):0]		uart_bytes_data_reg;					//寄存接收到的多字节数据，先接收低字节，后接收高字节
reg						uart_bytes_vld_reg;						//高电平表示此时接收到的数据有效
reg	[9:0]				byte_cnt;								//发送的字节个数计数(因为懒直接用10bit计数，最大可以表示1024BYTE，大概率不会溢出)			

//wire define
wire	[7:0]			uart_sing_data;							//接收的单个字节数据
wire					uart_sing_done;							//单个字节数据接收完毕信号
	
//对端口赋值
//assign uart_bytes_data = uart_bytes_data_reg;
//assign uart_bytes_vld  = uart_bytes_vld_reg;

//分别接收各个字节的数据
always @(posedge clk or negedge rstn)begin		
	if(!rstn)		
		uart_bytes_data_reg <= 0;												
	else if(uart_sing_done)begin									//接收到一个单字节则将数据右移8bit，实现最先接收的数据在低字节
		if(BYTES == 1)												//单字节就直接接收
			uart_bytes_data_reg <= uart_sing_data;											
		else														//多字节就移位接收
			uart_bytes_data_reg <= {uart_sing_data,uart_bytes_data_reg[(BYTES*8-1)-:(BYTES-1)*8]};														
	end	
	else		
		uart_bytes_data_reg <= uart_bytes_data_reg;				
end

//对接收的字节个数进行计数		
always @(posedge clk or negedge rstn)begin		
	if(!rstn)		
		byte_cnt <= 0;		
	else if(uart_sing_done && byte_cnt == BYTES - 1)			//计数到了最大值则清零
		byte_cnt <= 0;										
	else if(uart_sing_done)										//发送完一个单字节则计数器+1
		byte_cnt <= byte_cnt + 1'b1;						
	else		
		byte_cnt <= byte_cnt;			
end

//所有数据接收完毕,拉高接收多字节数据有效信号
always @(posedge clk or negedge rstn)begin
	if(!rstn)
		uart_bytes_vld_reg <= 1'b0;
	else if(uart_sing_done && byte_cnt == BYTES - 1)			//所有单字节数据接收完毕
		uart_bytes_vld_reg <= 1'b1;
	else 
		uart_bytes_vld_reg <= 1'b0;
end

always @(posedge clk or negedge rstn) begin
    if(!rstn)
        uart_bytes_data <= 32'd0;
    else if(uart_bytes_vld_reg)
        uart_bytes_data <= uart_bytes_data_reg;
    else
        uart_bytes_data <= uart_bytes_data;
end

always @(posedge clk or negedge rstn) begin
    if(!rstn)
        uart_bytes_vld <= 1'b0;
    else
        uart_bytes_vld <= uart_bytes_vld_reg;
end


//例化串口接收驱动模块
uart_rx #(
	.BPS			(BPS			),		
	.CLK_FRE		(CLK_FRE		)		
)	
uart_rx_inst
(	
	.clk		    (clk		),			
	.rstn		    (rstn		),	
	.uart_rx_done	(uart_sing_done	),			
	.uart_rx_data	(uart_sing_data	),			
	.uart_rxd		(uart_rxd		)
);

endmodule 